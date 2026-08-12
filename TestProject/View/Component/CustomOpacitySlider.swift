//
//  CustomOpacitySlider.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

// MARK: - Custom Opacity Slider Component

/// Component thanh trượt độ mờ tùy chỉnh với dải màu Gradient và nút kéo đổi màu tự động.
struct CustomOpacitySlider: View {
    
    // MARK: - Bindings & Properties
    
    /// Liên kết 2 chiều với thuộc tính độ mờ opacity của đối tượng (Giá trị từ 0.0 đến 1.0)
    @Binding var opacity: Double
    
    /// Màu điểm bắt đầu dải màu (Xanh dương)
    private let startUIColor = UIColor.systemBlue
    
    /// Màu điểm kết thúc dải màu (Hồng)
    private let endUIColor = UIColor.systemPink
    
    // MARK: - Body View
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbSize: CGFloat = 26
                // Tính toán khoảng dịch chuyển của nút kéo (giới hạn trong biên chiều rộng trừ kích thước nút)
                let thumbOffset = CGFloat(opacity) * (width - thumbSize)
                
                ZStack(alignment: .leading) {
                    // 1. Đường trượt Gradient màu (Track)
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(startUIColor), Color(endUIColor)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 8)
                    
                    // 2. Nút tròn kéo (Thumb Knob) có màu biến đổi đồng điệu theo vị trí
                    Circle()
                        .fill(getUnderlyingColor(fraction: opacity))
                        .frame(width: thumbSize, height: thumbSize)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                                .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                        )
                        .offset(x: thumbOffset)
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    // Quy đổi vị trí điểm chạm x thành tỷ lệ phần trăm (0.0 -> 1.0)
                                    let newLocation = value.location.x - (thumbSize / 2)
                                    let fraction = Double(newLocation / (width - thumbSize))
                                    self.opacity = min(max(fraction, 0.0), 1.0)
                                }
                        )
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 30)
            .padding(.horizontal)
        }
        .padding(.vertical, 12)
        .background(Color(.clear))
        .padding(.horizontal)
    }
    
    // MARK: - Helper Methods
    
    /// Thuật toán nội suy màu sắc tuyến tính (RGB Linear Interpolation - LERP)
    /// - Parameter fraction: Tỷ lệ vị trí thanh trượt từ 0.0 (Gốc) đến 1.0 (Đích)
    /// - Returns: Đối tượng `Color` đã được pha trộn màu tương ứng
    private func getUnderlyingColor(fraction: Double) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        // Trích xuất các kênh RGBA từ UIColor nguồn
        startUIColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endUIColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        // Tính toán giá trị từng kênh màu theo tỷ lệ fraction
        let r = r1 + (r2 - r1) * CGFloat(fraction)
        let g = g1 + (g2 - g1) * CGFloat(fraction)
        let b = b1 + (b2 - b1) * CGFloat(fraction)
        let a = a1 + (a2 - a1) * CGFloat(fraction)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
