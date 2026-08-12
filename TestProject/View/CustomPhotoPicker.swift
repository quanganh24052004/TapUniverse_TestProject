//
//  CustomPhotoPicker.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import Photos

// MARK: - Custom Photo Picker View (Screen 4)

/// Màn hình chọn ảnh tùy biến cho phép duyệt Album, chọn nhiều ảnh và xuất file local.
struct CustomPhotoPicker: View {
    
    // MARK: - Environment & Dependencies
    
    /// Thao tác đóng Modal View từ môi trường SwiftUI
    @Environment(\.dismiss) var dismiss
    
    /// Closure callback trả về danh sách đường dẫn URL cục bộ sau khi xuất ảnh thành công
    var onAddPhotos: ([String]) -> Void
    
    // MARK: - States
    
    /// Manager quản lý truy vấn PhotoKit và cache hình ảnh
    @State private var libraryManager = PhotoLibraryManager()
    
    /// Tập hợp các PHAsset được người dùng chọn (Dùng Set để tìm kiếm O(1))
    @State private var selectedAssets: Set<PHAsset> = []
    
    /// Trạng thái xoay ProgressView khi đang nén và xuất file ảnh ra đĩa
    @State private var isExporting = false
    
    // MARK: - Layout Constants
    
    /// Cấu hình lưới hiển thị 3 cột cố định
    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 2) {
                if libraryManager.isAuthorized {
                    // Trạng thái 1: Đã cấp quyền -> Hiển thị lưới ảnh
                    photoGridView
                } else {
                    // Trạng thái 2: Chưa cấp quyền -> Hiển thị màn hình yêu cầu cấp quyền
                    permissionDeniedView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: Navigation Toolbar
            .toolbar {
                // Nút Hủy góc trái
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                
                // Menu thả xuống chọn Album ở trung tâm Navigation Bar
                ToolbarItem(placement: .principal) {
                    albumPickerMenu
                }
                
                // Nút Thêm ảnh góc phải
                ToolbarItem(placement: .navigationBarTrailing) {
                    exportButton
                }
            }
            // Tự động kiểm tra và xin quyền truy cập ảnh khi View xuất hiện
            .task {
                await libraryManager.requestAuthorization()
            }
        }
    }
}

// MARK: - Subviews & Layout Components

private extension CustomPhotoPicker {
    
    /// Lưới hiển thị danh sách ảnh dạng 3 cột (LazyVGrid)
    var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(libraryManager.assets, id: \.localIdentifier) { asset in
                    let isSelected = selectedAssets.contains(asset)
                    
                    ZStack(alignment: .bottomTrailing) {
                        // View tải và hiển thị Thumbnail của PHAsset
                        AssetThumbnailView(
                            asset: asset,
                            imageManager: libraryManager.imageManager,
                            targetSize: CGSize(width: 300, height: 300)
                        )
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .clipped()
                        
                        // Khung viền xanh báo hiệu ảnh đang được chọn
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
    }
    
    /// Màn hình thông báo yêu cầu cấp quyền truy cập Thư viện ảnh
    var permissionDeniedView: some View {
        VStack {
            Spacer()
            Text("Cần cấp quyền truy cập Ảnh")
                .font(.headline)
            
            Button("Cấp quyền") {
                Task {
                    await libraryManager.requestAuthorization()
                }
            }
            .padding()
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }
    
    /// Menu thả xuống hỗ trợ chuyển đổi giữa các Album (Recents, Favorites, Custom Albums...)
    var albumPickerMenu: some View {
        Menu {
            Picker("Chọn Album", selection: $libraryManager.selectedAlbum) {
                ForEach(libraryManager.albums, id: \.localIdentifier) { album in
                    Text(album.localizedTitle ?? "Unknown")
                        .tag(album as PHAssetCollection?)
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
    
    /// Nút thực thi xuất ảnh và đóng Modal
    var exportButton: some View {
        Button(action: addSelectedPhotos) {
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

// MARK: - Private Actions & Business Logic

private extension CustomPhotoPicker {
    
    /// Chuyển đổi trạng thái chọn / bỏ chọn của một PHAsset
    /// - Parameter asset: Đối tượng PHAsset cần chuyển đổi
    func toggleSelection(for asset: PHAsset) {
        if selectedAssets.contains(asset) {
            selectedAssets.remove(asset)
        } else {
            selectedAssets.insert(asset)
        }
    }
    
    /// Đọc danh sách PHAsset đã chọn, nén file và lưu vào thư mục Document Directory
    func addSelectedPhotos() {
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
                    print("Lỗi xuất ảnh: \(error.localizedDescription)")
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
