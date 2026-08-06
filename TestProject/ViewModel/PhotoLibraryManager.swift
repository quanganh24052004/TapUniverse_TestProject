//
//  PhotoLibraryManager.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import Photos
import Combine

class PhotoLibraryManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var albums: [PHAssetCollection] = []
    @Published var selectedAlbum: PHAssetCollection? {
        didSet {
            if let album = selectedAlbum {
                fetchAssets(in: album)
            }
        }
    }
    @Published var assets: PHFetchResult<PHAsset>?
    
    let imageManager = PHCachingImageManager()
    
    init() {}
    
    func requestAuthorization() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.isAuthorized = (status == .authorized || status == .limited)
                if self?.isAuthorized == true {
                    self?.fetchAlbums()
                }
            }
        }
    }
    
    func fetchAlbums() {
        var fetchedAlbums: [PHAssetCollection] = []
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            if collection.estimatedAssetCount > 0 || collection.estimatedAssetCount == NSNotFound {
                fetchedAlbums.append(collection)
            }
        }
        
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        userAlbums.enumerateObjects { collection, _, _ in
            if collection.estimatedAssetCount > 0 {
                fetchedAlbums.append(collection)
            }
        }
        
        DispatchQueue.main.async {
            self.albums = fetchedAlbums
            if let firstAlbum = fetchedAlbums.first(where: { $0.assetCollectionSubtype == .smartAlbumUserLibrary }) ?? fetchedAlbums.first {
                self.selectedAlbum = firstAlbum
            }
        }
    }
    
    func fetchAssets(in collection: PHAssetCollection) {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchedAssets = PHAsset.fetchAssets(in: collection, options: options)
        DispatchQueue.main.async {
            self.assets = fetchedAssets
        }
    }
    
    /// Xuất ảnh từ PHAsset ra file cục bộ và trả về URL
    func saveAssetToLocal(asset: PHAsset) async throws -> URL {
        return try await withCheckedThrowingContinuation { continuation in
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false // Đặt false và dùng callback
            
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 1024, height: 1024), contentMode: .aspectFit, options: options) { image, info in
                if let error = info?[PHImageErrorKey] as? Error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool ?? false
                if isDegraded {
                    // Bỏ qua bản xem trước chất lượng thấp
                    return
                }
                
                guard let image = image, let data = image.jpegData(compressionQuality: 0.8) else {
                    continuation.resume(throwing: NSError(domain: "PhotoLibraryManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Không thể lấy dữ liệu ảnh"]))
                    return
                }
                
                let filename = "\(UUID().uuidString).jpg"
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let fileURL = documentsDirectory.appendingPathComponent(filename)
                
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
