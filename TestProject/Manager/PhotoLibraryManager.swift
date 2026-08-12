//
//  PhotoLibraryManager.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import Photos
import Observation

// MARK: - Photo Library Manager Service

/// Lớp quản lý dịch vụ truy cập thư viện ảnh PhotoKit trên thiết bị.
/// Xử lý xin quyền riêng tư, truy vấn Album/PHAsset và xuất file ảnh cục bộ ra Document Directory.
@Observable
@MainActor
class PhotoLibraryManager {
    
    // MARK: - Observable Properties
    
    /// Trạng thái đã được người dùng cấp quyền truy cập Thư viện ảnh hay chưa
    var isAuthorized = false
    
    /// Danh sách các Album thu thập được từ thiết bị (Smart Albums & User Albums)
    var albums: [PHAssetCollection] = []
    
    /// Album đang được chọn hiện tại (Tự động tải danh sách PHAsset khi thay đổi)
    var selectedAlbum: PHAssetCollection? {
        didSet {
            if let album = selectedAlbum {
                fetchAssets(in: album)
            }
        }
    }
    
    /// Danh sách các đối tượng PHAsset thuộc Album đang được chọn
    var assets: [PHAsset] = []
    
    // MARK: - Unobserved Properties
    
    /// Quản lý bộ nhớ đệm hình ảnh PhotoKit (Bỏ qua Observation để tối ưu hiệu năng UI)
    @ObservationIgnored
    let imageManager = PHCachingImageManager()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Authorization & Fetching
    
    /// Yêu cầu cấp quyền truy cập Thư viện ảnh (.readWrite) từ người dùng
    func requestAuthorization() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        self.isAuthorized = (status == .authorized || status == .limited)
        
        if self.isAuthorized {
            self.fetchAlbums()
        }
    }
    
    /// Quét và lọc danh sách Album hệ thống (Smart Albums) và Album do người dùng tự tạo
    func fetchAlbums() {
        var fetchedAlbums: [PHAssetCollection] = []
        
        // 1. Quét Smart Albums hệ thống (Recents, Favorites, Screenshots...)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            if collection.estimatedAssetCount > 0 || collection.estimatedAssetCount == NSNotFound {
                fetchedAlbums.append(collection)
            }
        }
        
        // 2. Quét User Albums (Album người dùng tự tạo trong Photos app)
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            if collection.estimatedAssetCount > 0 {
                fetchedAlbums.append(collection)
            }
        }
        
        self.albums = fetchedAlbums
        
        // 3. Mặc định ưu tiên chọn Album "Recents / All Photos" (.smartAlbumUserLibrary)
        if let firstAlbum = fetchedAlbums.first(where: { $0.assetCollectionSubtype == .smartAlbumUserLibrary }) ?? fetchedAlbums.first {
            self.selectedAlbum = firstAlbum
        }
    }
    
    /// Truy vấn toàn bộ PHAsset trong một Album được chỉ định, sắp xếp giảm dần theo thời gian tạo
    /// - Parameter collection: Album cần lấy danh sách ảnh
    func fetchAssets(in collection: PHAssetCollection) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchedAssets = PHAsset.fetchAssets(in: collection, options: options)
        var tempAssets: [PHAsset] = []
        
        fetchedAssets.enumerateObjects { (asset, index, stop) in
            tempAssets.append(asset)
        }
        
        self.assets = tempAssets
    }
    
    // MARK: - Asset Export Pipeline
    
    /// Xuất ảnh chất lượng cao từ PHAsset thành file .jpg lưu trữ cục bộ trong Document Directory
    /// - Parameter asset: Đối tượng PHAsset cần xử lý
    /// - Returns: Đường dẫn URL file cục bộ sau khi ghi thành công
    func saveAssetToLocal(asset: PHAsset) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true // Cho phép tải ảnh gốc từ iCloud nếu chưa có dưới máy
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 1024, height: 1024),
                contentMode: .aspectFit,
                options: options
            ) { image, info in
                // Kiểm tra nếu PhotoKit trả về lỗi
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                // Bỏ qua bản xem trước chất lượng thấp (Thường trả về ở callback lần 1)
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if isDegraded {
                    return
                }
                
                // Nén dữ liệu ảnh về định dạng JPEG (Chất lượng 80%)
                guard let image = image, let data = image.jpegData(compressionQuality: 0.8) else {
                    continuation.resume(
                        throwing: NSError(
                            domain: "PhotoLibraryManager",
                            code: 0,
                            userInfo: [NSLocalizedDescriptionKey: "Không thể trích xuất dữ liệu từ hình ảnh"]
                        )
                    )
                    return
                }
                
                // Tạo file URL duy nhất trong thư mục Document Directory
                let filename = "\(UUID().uuidString).jpg"
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(filename)
                
                // Ghi dữ liệu ra đĩa cứng
                do {
                    try data.write(to: fileURL)
                    continuation.resume(returning: fileURL)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
