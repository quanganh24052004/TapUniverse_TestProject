//
//  AppConstants.swift
//  TestProject
//

import Foundation
import CoreGraphics

// MARK: - App Global Constants

/// Tập hợp các hằng số cấu hình hệ thống, khoá lưu trữ đĩa cứng và thông số Canvas toàn cục.
enum AppConstants {
    
    // MARK: - UserDefaults Storage Keys
    
    /// Quản lý danh sách các chuỗi khoá (Keys) dùng cho đọc/ghi dữ liệu qua UserDefaults
    enum UserDefaultsKeys {
        
        /// Khoá lưu trữ mảng danh sách tóm tắt tất cả các dự án (Tầng 1 - Meta Level)
        static let savedLocalProjects = "saved_local_projects"
        
        /// Tạo khoá lưu trữ động cho cấu hình Canvas chi tiết của từng dự án theo ID (Tầng 2 - Detail Level)
        /// - Parameter projectId: ID định danh duy nhất của dự án
        /// - Returns: Chuỗi khoá định dạng `saved_project_detail_\(projectId)`
        static func savedProjectDetail(projectId: Int) -> String {
            return "saved_project_detail_\(projectId)"
        }
    }
    
    // MARK: - Canvas Configuration
    
    /// Thông số kích thước mặc định cho không gian không gian làm việc Canvas
    enum Canvas {
        
        /// Kích thước mặc định của mặt phẳng Canvas (1000 x 1000 points)
        static let defaultSize = CGSize(width: 1000, height: 1000)
        
        /// Kích thước mặc định ban đầu khi chèn một bức ảnh mới vào Canvas (300 x 300 points)
        static let photoInitialSize = CGSize(width: 300, height: 300)
    }
}
