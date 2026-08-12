//
//  AssetThumbnailView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import Photos

// MARK: - Asset Thumbnail View Component

/// View hiển thị ảnh thu nhỏ (Thumbnail) từ PHAsset phục vụ cho lưới chọn ảnh (Photo Picker Grid).
/// Tự động quản lý vòng đời nạp ảnh và hủy yêu cầu khi View bị ngắt khỏi màn hình.
struct AssetThumbnailView: View {
    
    // MARK: - Properties & Dependencies
    
    /// Đối tượng PHAsset cần lấy hình ảnh
    let asset: PHAsset
    
    /// Bộ quản lý đệm nạp ảnh PhotoKit
    let imageManager: PHCachingImageManager
    
    /// Kích thước thumbnail mục tiêu
    let targetSize: CGSize
    
    // MARK: - States
    
    /// Bức ảnh UIImage đã tải thành công từ PhotoKit
    @State private var image: UIImage?
    
    /// ID định danh yêu cầu nạp ảnh (Dùng để hủy task khi View bị scroll khỏi màn hình)
    @State private var requestID: PHImageRequestID?
    
    // MARK: - Body View
    
    var body: some View {
        Group {
            if let uiImage = image {
                Color.clear
                    .aspectRatio(1, contentMode: .fill)
                    .overlay(
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
            } else {
                // Trạng thái chờ (Placeholder) khi ảnh đang tải
                Color.gray.opacity(0.2)
                    .aspectRatio(1, contentMode: .fill)
            }
        }
        // Tự động tải lại ảnh mỗi khi asset thay đổi hoặc xuất hiện trên màn hình
        .task(id: asset.localIdentifier) {
            loadImage()
        }
        // Hủy yêu cầu nạp ảnh nếu người dùng cuộn qua nhanh
        .onDisappear {
            cancelImageRequest()
        }
    }
    
    // MARK: - PhotoKit Loading Logic
    
    /// Yêu cầu PhotoKit nạp ảnh thu nhỏ bất đồng bộ
    private func loadImage() {
        // Hủy yêu cầu cũ nếu đang chạy
        cancelImageRequest()
        
        // Reset trạng thái ảnh tạm để tránh bị dính ảnh của cell cũ trong LazyVGrid
        self.image = nil
        
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        requestID = imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { result, _ in
            if let result {
                self.image = result
            }
        }
    }
    
    /// Hủy tiến trình nạp ảnh PhotoKit ngầm để giải phóng bộ nhớ
    private func cancelImageRequest() {
        if let requestID = requestID {
            imageManager.cancelImageRequest(requestID)
            self.requestID = nil
        }
    }
}
