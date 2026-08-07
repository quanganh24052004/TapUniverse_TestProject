//
//  ProjectListViewModel.swift
//  TestProject
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectListViewModel: ObservableObject {
    @Published private(set) var projects: [Project] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    
    // Dependency Injection
    private let networkService: NetworkServiceProtocol
    private let localRepository: LocalProjectRepositoryProtocol
    
    init(networkService: NetworkServiceProtocol? = nil, localRepository: LocalProjectRepositoryProtocol? = nil) {
        self.networkService = networkService ?? NetworkManager.shared
        self.localRepository = localRepository ?? LocalProjectRepository.shared
        // Khởi tạo và tự động tải danh sách đã lưu cục bộ lên trước để UI hiển thị tức thì
        loadProjectsFromLocalStorage()
    }
    
    /// Tải danh sách dự án từ API cho Screen 1, đồng thời kết hợp với dữ liệu đã lưu cục bộ.
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        do {
            let apiProjects = try await networkService.fetchProjects()
            
            // Hợp nhất dữ liệu: So sánh updatedAt giữa API và Local
            let localSaved = localRepository.loadProjects()
            
            var mergedProjects = apiProjects
            for localProj in localSaved {
                if let index = mergedProjects.firstIndex(where: { $0.id == localProj.id }) {
                    // Nếu trùng ID, giữ lại bản mới hơn
                    let apiProj = mergedProjects[index]
                    if localProj.updatedAt > apiProj.updatedAt {
                        mergedProjects[index] = localProj
                    }
                } else {
                    // Nếu local có mà API không có (hoặc chưa đồng bộ), thêm vào
                    mergedProjects.append(localProj)
                }
            }
            
            self.projects = mergedProjects
            localRepository.saveProjects(self.projects) // Cập nhật lại bộ nhớ đệm cục bộ
            
        } catch {
            // Nếu mất mạng hoặc API lỗi, ứng dụng vẫn hiển thị danh sách đã lưu cục bộ trước đó
            loadProjectsFromLocalStorage()
            print("Không thể tải danh sách dự án từ API, sử dụng dữ liệu cục bộ: \(error)")
            self.errorMessage = "Không thể kết nối API. Đang hiển thị dữ liệu cục bộ."
        }
        isLoading = false
    }
    
    /// Tạo và lưu trữ một dự án mới cục bộ.
    ///
    /// - Parameter name: Tên của dự án mới cần tạo.
    func addProject(name: String) {
        let newId = (projects.map { $0.id }.max() ?? 0) + 1
        let newProject = Project(id: newId, name: name)
        projects.append(newProject)
        
        // Lưu trữ lại toàn bộ danh sách mới xuống thiết bị
        localRepository.saveProjects(self.projects)
    }
    
    /// Xoá dự án cục bộ tại các vị trí được chỉ định.
    ///
    /// - Parameter offsets: Tập hợp các vị trí (index) của dự án cần xoá.
    func removeProject(at offsets: IndexSet) {
        // Lấy danh sách ID để xóa chi tiết trước
        let idsToDelete = offsets.map { projects[$0].id }
        
        projects.remove(atOffsets: offsets)
        
        // Cập nhật lại danh sách sau khi xóa xuống thiết bị
        localRepository.saveProjects(self.projects)
        
        // Đồng thời xóa luôn detail khỏi ổ cứng để giải phóng bộ nhớ
        for id in idsToDelete {
            localRepository.deleteProjectDetail(projectId: id)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Cập nhật trạng thái ứng dụng bằng cách tải dữ liệu từ bộ nhớ cục bộ.
    private func loadProjectsFromLocalStorage() {
        self.projects = localRepository.loadProjects()
    }
}
