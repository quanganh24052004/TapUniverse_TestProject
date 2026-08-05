//
//  ProjectListViewModel.swift
//  TestProject
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectListViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Khóa lưu trữ trong UserDefaults
    private let localProjectsKey = "saved_local_projects"
    
    // Dependency Injection cho Network
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkManager.shared) {
        self.networkService = networkService
        // Khởi tạo và tự động tải danh sách đã lưu cục bộ lên trước để UI hiển thị tức thì
        loadProjectsFromLocalStorage()
    }
    
    // Gọi API lấy danh sách dự án cho Screen 1
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        do {
            let apiProjects = try await networkService.fetchProjects()
            
            // Hợp nhất dữ liệu: Giữ lại cả dự án từ API và các dự án do user tự tạo cục bộ
            let localSaved = getLocalProjectsFromStorage()
            
            // Loại bỏ trùng lặp dựa trên ID
            var mergedProjects = apiProjects
            for localProj in localSaved {
                if !mergedProjects.contains(where: { $0.id == localProj.id }) {
                    mergedProjects.append(localProj)
                }
            }
            
            self.projects = mergedProjects
            saveProjectsToLocalStorage(self.projects) // Cập nhật lại bộ nhớ đệm cục bộ
            
        } catch {
            // Nếu mất mạng hoặc API lỗi, ứng dụng vẫn hiển thị danh sách đã lưu cục bộ trước đó
            loadProjectsFromLocalStorage()
            print("Không thể tải danh sách dự án từ API, sử dụng dữ liệu cục bộ: \(error)")
            self.errorMessage = "Không thể kết nối API. Đang hiển thị dữ liệu cục bộ."
        }
        isLoading = false
    }
    
    // Tạo dự án mới cục bộ
    func addProject(name: String) {
        let newId = (projects.map { $0.id }.max() ?? 0) + 1
        let newProject = Project(id: newId, name: name)
        projects.append(newProject)
        
        // Lưu trữ lại toàn bộ danh sách mới xuống thiết bị
        saveProjectsToLocalStorage(self.projects)
    }
    
    // Xóa dự án cục bộ
    func removeProject(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
        
        // Cập nhật lại danh sách sau khi xóa xuống thiết bị
        saveProjectsToLocalStorage(self.projects)
    }
    
    // MARK: - Helper Methods (Xử lý UserDefaults & Codable)
    
    // Ghi dữ liệu xuống vĩnh viễn thiết bị
    private func saveProjectsToLocalStorage(_ projectsList: [Project]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(projectsList)
            UserDefaults.standard.set(data, forKey: localProjectsKey)
            print("Đã lưu thành công danh sách dự án cục bộ.")
        } catch {
            print("Lỗi mã hóa dữ liệu dự án: \(error)")
        }
    }
    
    // Tải dữ liệu từ thiết bị lên bộ nhớ đệm ứng dụng
    private func loadProjectsFromLocalStorage() {
        self.projects = getLocalProjectsFromStorage()
    }
    
    // Đọc và giải mã JSON từ UserDefaults
    private func getLocalProjectsFromStorage() -> [Project] {
        guard let data = UserDefaults.standard.data(forKey: localProjectsKey) else {
            return []
        }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Project].self, from: data)
        } catch {
            print("Lỗi giải mã danh sách dự án đã lưu: \(error)")
            return []
        }
    }
}
