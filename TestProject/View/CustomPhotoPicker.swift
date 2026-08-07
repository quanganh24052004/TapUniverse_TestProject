//
//  CustomPhotoPicker.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import Photos

struct CustomPhotoPicker: View {
    @Environment(\.dismiss) var dismiss
    var onAddPhotos: ([String]) -> Void
    
    @StateObject private var libraryManager = PhotoLibraryManager()
    
    @State private var selectedAssets: Set<PHAsset> = []
    @State private var isExporting = false
    
    let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 2) {
                if libraryManager.isAuthorized {
                    
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 4) {
                            ForEach(libraryManager.assets, id: \.localIdentifier) { asset in
                                let isSelected = selectedAssets.contains(asset)
                                
                                ZStack(alignment: .bottomTrailing) {
                                    AssetThumbnailView(
                                        asset: asset,
                                        imageManager: libraryManager.imageManager,
                                        targetSize: CGSize(width: 300, height: 300)
                                    )
                                    .frame(minWidth: 0, maxWidth: .infinity)
                                    .clipped()
                                    
                                    if isSelected {
                                        Rectangle()
                                            .stroke(Color.blue, lineWidth: 2)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    toggleSelection(for: asset)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("Cần cấp quyền truy cập Ảnh")
                            .font(.headline)
                        Button("Cấp quyền") {
                            libraryManager.requestAuthorization()
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Menu {
                        Picker("Chọn Album", selection: $libraryManager.selectedAlbum) {
                            ForEach(libraryManager.albums, id: \.localIdentifier) { album in
                                Text(album.localizedTitle ?? "Unknown").tag(album as PHAssetCollection?)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(libraryManager.selectedAlbum?.localizedTitle ?? "Đang tải...")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        addSelectedPhotos()
                    }) {
                        if isExporting {
                            ProgressView()
                        } else {
                            Text("Thêm (\(selectedAssets.count))")
                                .bold()
                        }
                    }
                    .disabled(selectedAssets.isEmpty || isExporting)
                }
            }
            .onAppear {
                libraryManager.requestAuthorization()
            }
        }
    }
    
    private func toggleSelection(for asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
        } else {
            selectedAssets.insert(asset)
        }
    }
    
    private func addSelectedPhotos() {
        guard !selectedAssets.isEmpty else { return }
        isExporting = true
        
        let assetsToProcess = Array(selectedAssets)
        var localUrls: [String] = []
        
        Task {
            for asset in assetsToProcess {
                do {
                    let url = try await libraryManager.saveAssetToLocal(asset: asset)
                    localUrls.append(url.absoluteString)
                } catch {
                    print("Lỗi xuất ảnh: \(error)")
                }
            }
            
            await MainActor.run {
                isExporting = false
                onAddPhotos(localUrls)
                dismiss()
            }
        }
    }
}
