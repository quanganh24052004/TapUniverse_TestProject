//
//  NetworkManager.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

// MARK: - Network Errors

/// Các loại lỗi mạng tùy chỉnh xảy ra trong quá trình giao tiếp API
enum NetworkError: Error {
    /// URL không hợp lệ hoặc không thể khởi tạo
    case invalidURL
    
    /// Phản hồi HTTP trả về trạng thái lỗi (Status Code != 200)
    case invalidResponse
    
    /// Lỗi mã hóa JSON (Encode) hoặc giải mã JSON (Decode)
    case decodingError
}

// MARK: - Network Service Protocol

/// Protocol định nghĩa các cổng giao tiếp API cho ứng dụng Quản lý Dự án
protocol NetworkServiceProtocol {
    /// Tải danh sách tóm tắt tất cả các dự án
    func fetchProjects() async throws -> [Project]
    
    /// Tải thông tin chi tiết Canvas của một dự án theo ID
    func fetchProjectDetail(projectId: Int) async throws -> ProjectDetail
    
    /// Đồng bộ và lưu dữ liệu Canvas chi tiết lên Server
    func saveProjectDetail(projectDetail: ProjectDetail) async throws
}

// MARK: - Network Manager Implementation

/// Service singleton chịu trách nhiệm thực thi các yêu cầu mạng RESTful API
class NetworkManager: NetworkServiceProtocol {
    
    // MARK: - Singleton Instance
    
    static let shared = NetworkManager()
    
    private init() {}
    
    // MARK: - API Methods
    
    /// Tải danh sách dự án (Phục vụ Màn hình 1 - ProjectListView)
    ///
    /// - Returns: Mảng chứa các đối tượng `Project`
    /// - Throws: `NetworkError` nếu URL sai, phản hồi HTTP lỗi, hoặc giải mã thất bại
    func fetchProjects() async throws -> [Project] {
        guard let url = URL(string: "https://tapuniverse.com/xproject") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            let decodedResponse = try JSONDecoder().decode(ProjectResponse.self, from: data)
            return decodedResponse.projects
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// Gửi Project ID theo phương thức POST để tải chi tiết dự án (Phục vụ Màn hình 2 - Canvas)
    ///
    /// - Parameter projectId: ID của dự án cần lấy dữ liệu
    /// - Returns: Đối tượng `ProjectDetail` chứa thông tin các layer ảnh và tọa độ
    /// - Throws: `NetworkError` nếu có lỗi kết nối hoặc giải mã JSON
    func fetchProjectDetail(projectId: Int) async throws -> ProjectDetail {
        guard let url = URL(string: "https://tapuniverse.com/xprojectdetail") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Cấu hình Body tham số truyền đi: { "id": <projectId> }
        let body: [String: Int] = ["id": projectId]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        
        do {
            return try JSONDecoder().decode(ProjectDetail.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    /// Mã hóa và đẩy thông tin chi tiết dự án lên Server qua phương thức POST
    ///
    /// - Parameter projectDetail: Đối tượng `ProjectDetail` chứa dữ liệu mới nhất cần lưu
    /// - Throws: `NetworkError` nếu mã hóa thất bại hoặc Server trả về lỗi HTTP
    func saveProjectDetail(projectDetail: ProjectDetail) async throws {
        guard let url = URL(string: "https://tapuniverse.com/xprojectsave") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let bodyData = try JSONEncoder().encode(projectDetail)
            request.httpBody = bodyData
        } catch {
            throw NetworkError.decodingError
        }
        
        // Thực thi gọi request thực tế lên server
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }
    }
}
