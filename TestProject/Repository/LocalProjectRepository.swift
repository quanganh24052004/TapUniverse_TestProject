//
//  LocalProjectRepository.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

// MARK: - Local Project Repository Protocol

/// Protocol định nghĩa các phương thức thao tác đĩa cứng cục bộ cho dự án
protocol LocalProjectRepositoryProtocol {
    /// Lưu danh sách tóm tắt tất cả các dự án xuống đĩa
    func saveProjects(_ projects: [Project])
    
    /// Đọc danh sách tóm tắt tất cả các dự án từ đĩa
    func loadProjects() -> [Project]
    
    /// Lưu thông tin chi tiết Canvas của một dự án theo ID
    func saveProjectDetail(_ detail: ProjectDetail)
    
    /// Đọc thông tin chi tiết Canvas của một dự án theo ID
    func loadProjectDetail(projectId: Int) -> ProjectDetail?
    
    /// Xóa dữ liệu Canvas chi tiết của một dự án khỏi đĩa
    func deleteProjectDetail(projectId: Int)
}

// MARK: - Local Project Repository Implementation

/// Service singleton quản lý đọc/ghi dữ liệu đĩa cứng thông qua UserDefaults
class LocalProjectRepository: LocalProjectRepositoryProtocol {
    
    // MARK: - Singleton Instance
    
    static let shared = LocalProjectRepository()
    
    // MARK: - Dependencies & Tools
    
    private let userDefaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    // Khóa hàm khởi tạo để đảm bảo cấu trúc Singleton
    private init() {}
    
    // MARK: - Meta Level Persistence (Screen 1 - List)
    
    /// Mã hóa và ghi đè danh sách tóm tắt tất cả các dự án xuống UserDefaults
    /// - Parameter projects: Mảng danh sách các dự án
    func saveProjects(_ projects: [Project]) {
        do {
            let data = try encoder.encode(projects)
            userDefaults.set(data, forKey: AppConstants.UserDefaultsKeys.savedLocalProjects)
            print("Đã lưu thành công danh sách dự án cục bộ.")
        } catch {
            print("Lỗi mã hóa dữ liệu danh sách dự án: \(error)")
        }
    }
    
    /// Đọc và giải mã mảng danh sách tổng các dự án từ UserDefaults
    /// - Returns: Mảng [Project] đã lưu, hoặc mảng rỗng [] nếu chưa có dữ liệu hoặc lỗi
    func loadProjects() -> [Project] {
        guard let data = userDefaults.data(forKey: AppConstants.UserDefaultsKeys.savedLocalProjects) else {
            return []
        }
        do {
            return try decoder.decode([Project].self, from: data)
        } catch {
            print("Lỗi giải mã danh sách dự án đã lưu: \(error)")
            return []
        }
    }
    
    // MARK: - Detail Level Persistence (Screen 2 - Canvas)
    
    /// Mã hóa và lưu cấu hình Canvas chi tiết của một dự án theo khóa động `savedProjectDetail_\(id)`
    /// - Parameter detail: Đối tượng `ProjectDetail` chứa các layer ảnh và tọa độ
    func saveProjectDetail(_ detail: ProjectDetail) {
        do {
            let data = try encoder.encode(detail)
            let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: detail.id)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Lỗi lưu chi tiết dự án local storage: \(error)")
        }
    }
    
    /// Đọc và giải mã dữ liệu Canvas chi tiết của một dự án từ UserDefaults dựa trên ID
    /// - Parameter projectId: ID của dự án cần lấy
    /// - Returns: Đối tượng `ProjectDetail` nếu tồn tại, ngược lại trả về `nil`
    func loadProjectDetail(projectId: Int) -> ProjectDetail? {
        let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: projectId)
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        do {
            return try decoder.decode(ProjectDetail.self, from: data)
        } catch {
            print("Lỗi tải chi tiết dự án local storage: \(error)")
            return nil
        }
    }
    
    /// Giải phóng bộ nhớ đệm chi tiết của dự án khỏi đĩa khi người dùng thực hiện xóa dự án
    /// - Parameter projectId: ID dự án cần xóa
    func deleteProjectDetail(projectId: Int) {
        let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: projectId)
        userDefaults.removeObject(forKey: key)
    }
}
