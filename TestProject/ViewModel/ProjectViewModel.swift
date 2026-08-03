//
//  ProjectStore.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectViewModel: ObservableObject {
    @Published var projects: [Project] = []
    @Published var selectedProjectDetail: ProjectDetail? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Khóa lưu trữ trong UserDefaults
    private let localProjectsKey = "saved_local_projects"
    
    init() {
        // Khởi tạo và tự động tải danh sách đã lưu cục bộ lên trước để UI hiển thị tức thì
        loadProjectsFromLocalStorage()
    }
    
    // Gọi API lấy danh sách dự án cho Screen 1
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        do {
            let apiProjects = try await NetworkManager.shared.fetchProjects()
            
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
    
    // Gọi API lấy thông tin chi tiết Canvas cho Screen 2
    func loadProjectDetail(projectId: Int) async {
        isLoading = true
        errorMessage = nil
        do {
            self.selectedProjectDetail = try await NetworkManager.shared.fetchProjectDetail(projectId: projectId)
        } catch {
            // Sửa lỗi chức năng Thêm dự án mới:
            // Do dự án mới tạo cục bộ chưa tồn tại trên server, API sẽ trả về lỗi (404/decode error).
            // Ta sẽ tạo một ProjectDetail rỗng làm fallback để người dùng bắt đầu vẽ Canvas.
            if let project = projects.first(where: { $0.id == projectId }) {
                self.selectedProjectDetail = ProjectDetail(id: projectId, name: project.name, photos: [])
                print("Đã tạo fallback Canvas trống cho dự án mới: \(project.name)")
            } else {
                self.errorMessage = "Không thể tải dữ liệu chi tiết của dự án."
                print("Error: \(error)")
            }
        }
        isLoading = false
    }
    
    // Gọi API lưu thông tin dự án khi đóng (Giai đoạn 6)
    func saveProject() async {
        guard let projectDetail = selectedProjectDetail else { return }
        isLoading = true
        do {
            try await NetworkManager.shared.saveProjectDetail(projectDetail: projectDetail)
            print("Đã lưu dự án thành công: \(projectDetail.name)")
        } catch {
            self.errorMessage = "Lỗi khi lưu dự án."
            print("Save Error: \(error)")
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
