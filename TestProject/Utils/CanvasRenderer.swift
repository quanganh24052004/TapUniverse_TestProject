//
//  CanvasRenderer.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import UIKit
import SwiftUI

class CanvasRenderer {
    
    /// Hàm kết xuất toàn bộ Canvas thành dữ liệu hình ảnh JPEG
    static func renderToJPEG(photos: [PhotoFrame], canvasSize: CGSize) -> Data? {
        // 1. Ép cứng kích thước Canvas chuẩn theo AppConstants
        let targetSize = AppConstants.Canvas.defaultSize
        
        // 2. Cấu hình định dạng không bị ảnh hưởng bởi tỷ lệ scale của thiết bị (1 point = 1 pixel)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        format.opaque = true
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        
        // Tạo UIImage từ bộ dựng đồ họa
        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Đổ màu nền cho vùng canvas
            if let canvasColor = UIColor.canvas.cgColor as CGColor? {
                cgContext.setFillColor(canvasColor)
            } else {
                cgContext.setFillColor(UIColor.white.cgColor)
            }
            cgContext.fill(CGRect(origin: .zero, size: targetSize))
            
            for photo in photos {
                // 1. Lấy ảnh từ Cache để tăng tốc, nếu không có mới tải đồng bộ
                let uiImage: UIImage
                if let cached = ImageCacheManager.shared.getImage(forKey: photo.url) {
                    uiImage = cached
                } else if let url = URL(string: photo.url),
                          let data = try? Data(contentsOf: url),
                          let downloaded = UIImage(data: data) {
                    uiImage = downloaded
                    ImageCacheManager.shared.saveImage(downloaded, forKey: photo.url)
                } else {
                    continue
                }
                
                // Lưu lại trạng thái ngữ cảnh đồ họa trước khi biến đổi hình học
                cgContext.saveGState()
                
                // 2. Thiết lập kích thước vẽ khung ảnh
                let rect = CGRect(
                    x: photo.frame.x,
                    y: photo.frame.y,
                    width: photo.frame.width,
                    height: photo.frame.height
                )
                
                // 3. Thực hiện xoay ảnh quanh tâm của chính nó
                let center = CGPoint(x: rect.midX, y: rect.midY)
                cgContext.translateBy(x: center.x, y: center.y)
                cgContext.rotate(by: CGFloat(Angle(degrees: photo.rotation).radians))
                cgContext.translateBy(x: -center.x, y: -center.y)
                
                // 4. Áp dụng độ mờ Opacity từ Slider tùy chỉnh
                let alpha = CGFloat(photo.opacity)
                
                // 5. Tiến hành vẽ ảnh lên CGContext
                uiImage.draw(in: rect, blendMode: .normal, alpha: alpha)
                
                // Khôi phục lại trạng thái đồ họa ban đầu cho bức ảnh tiếp theo
                cgContext.restoreGState()
            }
        }
        
        // Trả về dữ liệu ảnh nén định dạng JPEG với chất lượng 90%
        return renderedImage.jpegData(compressionQuality: 0.9)
    }
}
