//
//  ImageCacheManager.swift
//  TestProject
//
import UIKit

// MARK: - Image Cache Manager Service

/// Singleton Service quản lý bộ nhớ đệm hình ảnh tạm thời (In-Memory Cache) bằng `NSCache`.
/// Tự động giải phóng các vùng nhớ đệm khi hệ thống iOS nhận cảnh báo thiếu RAM (Memory Pressure).
final class ImageCacheManager {
    
    // MARK: - Singleton Instance
    
    static let shared = ImageCacheManager()
    
    // MARK: - Properties
    
    /// Đối tượng NSCache lưu trữ hình ảnh dưới dạng Key-Value (Thread-safe)
    private let cache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    
    private init() {
        // Cấu hình giới hạn bộ nhớ tối đa: 50MB
        // Công thức ước tính: 1 pixel ARGB = 4 bytes. Một bức ảnh 1000x1000 pixels ≈ 4MB RAM
        cache.totalCostLimit = 1024 * 1024 * 50
    }
    
    // MARK: - Cache Operations
    
    /// Trích xuất hình ảnh từ bộ nhớ đệm dựa trên Key
    /// - Parameter key: Chuỗi định danh (thường là URL hoặc filename)
    /// - Returns: Đối tượng `UIImage` nếu tồn tại trong đệm, ngược lại trả về `nil`
    func getImage(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    /// Lưu trữ hình ảnh vào bộ nhớ đệm kèm theo chi phí dung lượng (Cost) tính toán chính xác
    /// - Parameters:
    ///   - image: Đối tượng `UIImage` cần lưu
    ///   - key: Chuỗi định danh dùng để truy xuất
    func saveImage(_ image: UIImage, forKey key: String) {
        // Tính toán kích thước điểm ảnh thực tế (Pixel Width x Pixel Height) dựa trên Scale của màn hình (@2x, @3x)
        let pixelWidth = image.size.width * image.scale
        let pixelHeight = image.size.height * image.scale
        
        // 1 pixel ARGB tiêu tốn 4 bytes bộ nhớ
        let cost = Int(pixelWidth * pixelHeight * 4)
        
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
