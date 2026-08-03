//
//  CustomPhotoPicker.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

// Struct mô hình hóa ảnh trong thư viện
struct PickerPhoto: Identifiable, Hashable {
    let id = UUID()
    let url: String
    let album: String
}

struct CustomPhotoPicker: View {
    @Environment(\.dismiss) var dismiss
    var onAddPhotos: ([String]) -> Void // Callback trả về danh sách các URL ảnh được chọn
    
    @State private var selectedAlbum: String = "Recent Photos"
    @State private var selectedPhotoUrls: Set<String> = []
    
    let albums = ["Recent Photos", "Travel", "Portraits", "Favorites"]
    
    // Giả lập cơ sở dữ liệu hình ảnh phong phú theo các Album
    let mockPhotosDatabase: [PickerPhoto] = [
        PickerPhoto(url: "https://picsum.photos/id/1015/400/300", album: "Recent Photos"),
        PickerPhoto(url: "https://picsum.photos/id/1016/400/300", album: "Recent Photos"),
        PickerPhoto(url: "https://picsum.photos/id/1018/400/300", album: "Recent Photos"),
        PickerPhoto(url: "https://picsum.photos/id/1019/400/300", album: "Recent Photos"),
        PickerPhoto(url: "https://picsum.photos/id/1020/400/300", album: "Recent Photos"),
        PickerPhoto(url: "https://picsum.photos/id/1021/400/300", album: "Recent Photos"),
        
        PickerPhoto(url: "https://picsum.photos/id/1035/400/300", album: "Travel"),
        PickerPhoto(url: "https://picsum.photos/id/1036/400/300", album: "Travel"),
        PickerPhoto(url: "https://picsum.photos/id/1037/400/300", album: "Travel"),
        
        PickerPhoto(url: "https://picsum.photos/id/1043/400/300", album: "Portraits"),
        PickerPhoto(url: "https://picsum.photos/id/1062/400/300", album: "Portraits"),
        PickerPhoto(url: "https://picsum.photos/id/1074/400/300", album: "Portraits")
    ]
    
    // Định nghĩa lưới 3 cột đều nhau với khoảng cách giữa các phần tử là 4pt
    let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]
    
    var filteredPhotos: [PickerPhoto] {
        mockPhotosDatabase.filter { $0.album == selectedAlbum }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Thanh chọn Album (Menu Dropdown)
                HStack {
                    Text("Album:")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Picker("Chọn Album", selection: $selectedAlbum) {
                        ForEach(albums, id: \.self) { album in
                            Text(album).tag(album)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.blue)
                    .bold()
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Hiển thị ảnh dạng lưới 3 cột
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(filteredPhotos) { photo in
                            let isSelected = selectedPhotoUrls.contains(photo.url)
                            
                            ZStack(alignment: .bottomTrailing) {
                                AsyncImage(url: URL(string: photo.url)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(1, contentMode: .fill)
                                } placeholder: {
                                    Color.gray.opacity(0.2)
                                        .aspectRatio(1, contentMode: .fill)
                                }
                                .frame(minWidth: 0, maxWidth: .infinity)
                                .clipped()
                                .onTapGesture {
                                    toggleSelection(for: photo.url)
                                }
                                
                                // Hiệu ứng tích chọn màu xanh dương
                                if isSelected {
                                    Color.black.opacity(0.3)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                        .background(Circle().fill(Color.white))
                                        .padding(8)
                                        .font(.title3)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
            .navigationTitle(selectedAlbum)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAddPhotos(Array(selectedPhotoUrls))
                        dismiss()
                    }
                    .bold()
                    .disabled(selectedPhotoUrls.isEmpty) // Chỉ bật nút Add khi có ảnh được chọn
                }
            }
        }
    }
    
    private func toggleSelection(for url: String) {
        if selectedPhotoUrls.contains(url) {
            selectedPhotoUrls.remove(url)
        } else {
            selectedPhotoUrls.insert(url)
        }
    }
}
