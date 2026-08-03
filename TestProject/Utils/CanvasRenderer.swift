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
        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        
        // Tạo UIImage từ bộ dựng đồ họa
        let renderedImage = renderer.image { context in
            let cgContext = context.cgContext
            
            for photo in photos {
                // 1. Tải ảnh đồng bộ từ URL
                guard let url = URL(string: photo.url),
                      let data = try? Data(contentsOf: url),
                      let uiImage = UIImage(data: data) else {
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
