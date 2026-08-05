//
//  NetworkManager.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case decodingError
}

protocol NetworkServiceProtocol {
    func fetchProjects() async throws -> [Project]
    func fetchProjectDetail(projectId: Int) async throws -> ProjectDetail
    func saveProjectDetail(projectDetail: ProjectDetail) async throws
}

class NetworkManager: NetworkServiceProtocol {
    static let shared = NetworkManager()
    private init() {}
    
    // 1. GET: Tải danh sách dự án hiển thị lên Screen 1
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
    
    // 2. POST: Gửi Project ID và tải chi tiết dự án hiển thị lên Screen 2
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
    
    // 3. POST: Lưu thông tin chi tiết dự án (Giai đoạn 6)
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
        
        // Thực hiện call API (giả lập delay và response vì endpoint chưa tồn tại thực tế)
        /*
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.invalidResponse
        }
        */
        
        // Giả lập độ trễ mạng để test UI
        try await Task.sleep(nanoseconds: 500_000_000)
    }
}
