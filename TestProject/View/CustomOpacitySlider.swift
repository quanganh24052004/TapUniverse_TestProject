//
//  CustomOpacitySlider.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

struct CustomOpacitySlider: View {
    @Binding var opacity: Double // Liên kết trực tiếp với thuộc tính opacity của PhotoFrame
    
    private let startUIColor = UIColor.systemBlue
    private let endUIColor = UIColor.systemPink
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Độ mờ ảnh (Opacity):")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.secondary)
                Text("\(Int(opacity * 100))%")
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
            }
            .padding(.horizontal)
            
            GeometryReader { geometry in
                let width = geometry.size.width
                let thumbSize: CGFloat = 26
                // Tính toán vị trí ngang của nút trượt dựa trên giá trị opacity
                let thumbOffset = CGFloat(opacity) * (width - thumbSize)
                
                ZStack(alignment: .leading) {
                    // 1. Đường trượt Gradient màu từ Xanh dương sang Hồng
                    Capsule()
                        .fill(LinearGradient(
                            colors: [Color(startUIColor), Color(endUIColor)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                        .frame(height: 8)
                    
                    // 2. Nút tròn kéo có màu sắc biến đổi đồng điệu với vị trí dải màu phía dưới
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
                                    // Chuyển vị trí ngón tay kéo thành tỷ lệ 0.0 -> 1.0 tương ứng
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
        .background(Color(.systemBackground).cornerRadius(12).shadow(radius: 2))
        .padding(.horizontal)
    }
    
    // Thuật toán nội suy màu sắc (RGB Color Interpolation) giúp đồng bộ màu của nút tròn
    private func getUnderlyingColor(fraction: Double) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        
        startUIColor.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        endUIColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        
        let r = r1 + (r2 - r1) * CGFloat(fraction)
        let g = g1 + (g2 - g1) * CGFloat(fraction)
        let b = b1 + (b2 - b1) * CGFloat(fraction)
        let a = a1 + (a2 - a1) * CGFloat(fraction)
        
        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }
}
