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
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        
        for photo in photos {
            let rect = CGRect(x: photo.frame.x, y: photo.frame.y, width: photo.frame.width, height: photo.frame.height)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let transform = CGAffineTransform(translationX: center.x, y: center.y)
                .rotated(by: CGFloat(Angle(degrees: photo.rotation).radians))
                .translatedBy(x: -center.x, y: -center.y)
            
            let corners = [
                CGPoint(x: rect.minX, y: rect.minY).applying(transform),
                CGPoint(x: rect.maxX, y: rect.minY).applying(transform),
                CGPoint(x: rect.minX, y: rect.maxY).applying(transform),
                CGPoint(x: rect.maxX, y: rect.maxY).applying(transform)
            ]
            
            for point in corners {
                minX = min(minX, point.x)
                minY = min(minY, point.y)
                maxX = max(maxX, point.x)
                maxY = max(maxY, point.y)
            }
        }
        
        guard minX <= maxX && minY <= maxY else { return nil }
        
        let margin: CGFloat = 40
        let cropRect = CGRect(
            x: minX - margin,
            y: minY - margin,
            width: (maxX - minX) + margin * 2,
            height: (maxY - minY) + margin * 2
        )
        
        let renderer = UIGraphicsImageRenderer(size: cropRect.size)
        
        // Tạo UIImage từ bộ dựng đồ họa
        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            // Dịch hệ trục toạ độ để crop ảnh vừa khít
            cgContext.translateBy(x: -cropRect.minX, y: -cropRect.minY)
            
            // Đổ màu nền trắng cho vùng canvas được xuất ra
            cgContext.setFillColor(UIColor.white.cgColor)
            cgContext.fill(cropRect)
            
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
