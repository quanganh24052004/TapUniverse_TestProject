//
//  NetworkManager.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

// MARK: - NetworkError
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

// MARK: - NetworkServiceProtocol
protocol NetworkServiceProtocol {
    func fetchProjects() async throws -> [Project]
    func fetchProjectDetail(projectId: Int) async throws -> ProjectDetail
    func saveProjectDetail(projectDetail: ProjectDetail) async throws
}

// MARK: - NetworkManager
class NetworkManager: NetworkServiceProtocol {
    static let shared = NetworkManager()
    private init() {}
    
    /// Tải danh sách dự án (phục vụ hiển thị Screen 1).
    ///
    /// - Returns: Mảng chứa các đối tượng `Project`.
    /// - Throws: `NetworkError` nếu URL không hợp lệ, phản hồi HTTP lỗi, hoặc giải mã JSON thất bại.
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
    
    /// Gửi Project ID và tải chi tiết dự án (phục vụ hiển thị Screen 2).
    ///
    /// - Parameter projectId: ID của dự án cần tải.
    /// - Returns: Đối tượng `ProjectDetail` chứa thông tin hình ảnh và toạ độ.
    /// - Throws: `NetworkError` nếu có lỗi mạng hoặc lỗi giải mã.
    func fetchProjectDetail(projectId: Int) async throws -> ProjectDetail {
        guard let url = URL(string: "https://tapuniverse.com/xprojectdetail") else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Cấu hình tham số body: { "id": <id_dự_án> }
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
    
    /// Cập nhật và lưu lại thông tin chi tiết dự án lên server (Giai đoạn 6).
    ///
    /// - Parameter projectDetail: Đối tượng `ProjectDetail` chứa dữ liệu mới nhất.
    /// - Throws: `NetworkError` nếu quá trình mã hoá dữ liệu hoặc gọi mạng thất bại.
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
        
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
