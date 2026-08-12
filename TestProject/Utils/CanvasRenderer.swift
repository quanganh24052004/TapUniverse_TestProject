import UIKit
import SwiftUI

// MARK: - Canvas Renderer Service

/// Service chịu trách nhiệm phẳng hóa (flattening) tất cả các layer ảnh trên Canvas
/// và xuất ra khối dữ liệu hình ảnh JPEG hoàn chỉnh ở background thread.
class CanvasRenderer {
    
    // MARK: - Render Methods
    
    /// Kết xuất mảng dữ liệu `[PhotoFrame]` thành khối dữ liệu nén JPEG chất lượng cao
    ///
    /// - Parameters:
    ///   - photos: Mảng chứa thông tin tọa độ, góc xoay, độ mờ và đường dẫn các bức ảnh
    ///   - canvasSize: Kích thước khung nhìn hiện tại (Đã được chuẩn hóa lại theo `AppConstants.Canvas.defaultSize`)
    /// - Returns: Khối dữ liệu nhị phân `Data` định dạng JPEG, hoặc `nil` nếu lỗi
    static func renderToJPEG(photos: [PhotoFrame], canvasSize: CGSize) -> Data? {
        // 1. Ép cứng kích thước Canvas mặt phẳng chuẩn (1000 x 1000)
        let targetSize = AppConstants.Canvas.defaultSize
        
        // 2. Cấu hình renderer độ phân giải cao (scale 3x cho Super Retina)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        // 3. Tiến hành vẽ đồ họa off-screen lên Graphics Context
        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Đổ màu nền cho vùng không gian Canvas
            if let canvasColor = UIColor.canvas.cgColor as CGColor? {
                cgContext.setFillColor(canvasColor)
            } else {
                cgContext.setFillColor(UIColor.white.cgColor)
            }
            cgContext.fill(CGRect(origin: .zero, size: targetSize))
            
            // Duyệt từng layer bức ảnh theo thứ tự Z-Index từ dưới lên trên
            for photo in photos {
                // Step 1: Lấy ảnh từ ImageCacheManager để tối ưu hiệu năng
                let uiImage: UIImage
                if let cached = ImageCacheManager.shared.getImage(forKey: photo.url) {
                    uiImage = cached
                } else {
                    // Khôi phục đường dẫn tuyệt đối cho file local hoặc HTTP URL
                    let absoluteURL: URL?
                    if photo.url.starts(with: "http") {
                        absoluteURL = URL(string: photo.url)
                    } else {
                        let filename = (photo.url as NSString).lastPathComponent
                        let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                        absoluteURL = docDir?.appendingPathComponent(filename)
                    }
                    
                    if let url = absoluteURL,
                       let data = try? Data(contentsOf: url),
                       let downloaded = UIImage(data: data) {
                        uiImage = downloaded
                        ImageCacheManager.shared.saveImage(downloaded, forKey: photo.url)
                    } else {
                        continue // Bỏ qua nếu ảnh bị hỏng hoặc không thể nạp
                    }
                }
                
                // Lưu lại trạng thái ma trận đồ họa trước khi áp dụng biến đổi
                cgContext.saveGState()
                
                // Step 2: Xác định khung hình chữ nhật vẽ ảnh
                let rect = CGRect(
                    x: photo.frame.x,
                    y: photo.frame.y,
                    width: photo.frame.width,
                    height: photo.frame.height
                )
                
                // Step 3: Dịch chuyển gốc tọa độ và thực hiện xoay quanh tâm ảnh
                let center = CGPoint(x: rect.midX, y: rect.midY)
                cgContext.translateBy(x: center.x, y: center.y)
                cgContext.rotate(by: CGFloat(Angle(degrees: photo.rotation).radians))
                cgContext.translateBy(x: -center.x, y: -center.y)
                
                // Step 4: Áp dụng độ mờ Opacity
                let alpha = CGFloat(photo.opacity)
                
                // Step 5: In bức ảnh lên Graphics Context
                uiImage.draw(in: rect, blendMode: .normal, alpha: alpha)
                
                // Khôi phục ma trận đồ họa ban đầu cho layer ảnh tiếp theo
                cgContext.restoreGState()
            }
        }
        
        // 4. Trả về dữ liệu ảnh nén định dạng JPEG chất lượng tối đa (100%)
        return renderedImage.jpegData(compressionQuality: 1.0)
    }
}
