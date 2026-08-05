//
//  ImageCacheManager.swift
//  TestProject
//

import UIKit

final class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    private let cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Cấu hình giới hạn bộ nhớ (ví dụ: khoảng 50MB cho bộ đệm hình ảnh)
        // 1 pixel ARGB tốn 4 bytes. Một bức ảnh 1000x1000 tốn khoảng 4MB.
        cache.totalCostLimit = 1024 * 1024 * 50
    }
    
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    func saveImage(_ image: UIImage, forKey key: String) {
        // Tính toán cost tương đối (width * height * 4 bytes/pixel)
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
