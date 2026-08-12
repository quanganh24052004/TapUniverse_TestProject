//
//  ActivityView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import UIKit

// MARK: - Activity View (Share Sheet Wrapper)

/// Bridge component giúp hiển thị giao diện Chia sẻ (Share Sheet / UIActivityViewController) của UIKit trong môi trường SwiftUI.
/// Dùng để chia sẻ hình ảnh đã xuất (Exported Canvas Image), tệp tin hoặc văn bản sang các ứng dụng ngoài.
struct ActivityView: UIViewControllerRepresentable {
    
    // MARK: - Properties
    
    /// Danh sách các đối tượng dữ liệu cần chia sẻ (UIImage, URL, Data, String...)
    let activityItems: [Any]
    
    /// Danh sách các tác vụ chia sẻ tùy chỉnh (Custom UIActivity Services)
    let applicationActivities: [UIActivity]?
    
    // MARK: - Initialization
    
    /// Khởi tạo ActivityView với các item cần chia sẻ
    /// - Parameters:
    ///   - activityItems: Mảng chứa các đối tượng dữ liệu cần chia sẻ
    ///   - applicationActivities: Mảng các dịch vụ tùy chỉnh thêm vào Share Sheet (Mặc định: nil)
    init(activityItems: [Any], applicationActivities: [UIActivity]? = nil) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }
    
    // MARK: - UIViewControllerRepresentable Lifecycle
    
    /// Khởi tạo và cấu hình Controller UIActivityViewController của UIKit
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }
    
    /// Cập nhật Controller khi State của SwiftUI thay đổi
    /// - Note: UIActivityViewController là một modal hiển thị tĩnh nên không cần xử lý cập nhật lại.
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
