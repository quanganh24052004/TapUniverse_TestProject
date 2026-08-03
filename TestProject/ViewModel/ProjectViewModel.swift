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
    
    // Gọi API lấy danh sách dự án cho Screen 1
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        do {
            self.projects = try await NetworkManager.shared.fetchProjects()
        } catch {
            self.errorMessage = "Không thể tải danh sách dự án. Vui lòng kiểm tra kết nối mạng."
            print("Error: \(error)")
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
    }
    
    // Xóa dự án cục bộ
    func removeProject(at offsets: IndexSet) {
        projects.remove(atOffsets: offsets)
    }
}
