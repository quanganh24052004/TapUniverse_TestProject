//
//  ProjectListViewModel.swift
//  TestProject
//

import Foundation
import SwiftUI
import Observation

// MARK: - Project List ViewModel

/// ViewModel quản lý dữ liệu danh sách dự án cho Màn hình 1 (ProjectListView).
/// Hỗ trợ chiến lược Offline-First, hợp nhất dữ liệu từ API & Local, tạo mới và xóa dự án.
@Observable
@MainActor
class ProjectListViewModel {
    
    // MARK: - Observable Properties
    
    /// Danh sách các dự án hiển thị trên giao diện
    private(set) var projects: [Project] = []
    
    /// Trạng thái đang tải dữ liệu từ API
    private(set) var isLoading: Bool = false
    
    /// Thông báo lỗi từ mạng hoặc hệ thống
    private(set) var errorMessage: String? = nil
    
    // MARK: - Dependencies (Dependency Injection)
    
    private let networkService: NetworkServiceProtocol
    private let localRepository: LocalProjectRepositoryProtocol
    
    // MARK: - Initialization
    
    /// Khởi tạo ViewModel với các Dependency truyền vào (Mặc định dùng Shared Singletons)
    init(
        networkService: NetworkServiceProtocol? = nil,
        localRepository: LocalProjectRepositoryProtocol? = nil
    ) {
        self.networkService = networkService ?? NetworkManager.shared
        self.localRepository = localRepository ?? LocalProjectRepository.shared
        
        // Khởi tạo và tự động tải danh sách đã lưu cục bộ lên trước để UI hiển thị tức thì
        loadProjectsFromLocalStorage()
    }
    
    // MARK: - API & Data Synchronization Operations
    
    /// Tải danh sách dự án từ API, hợp nhất thông minh với dữ liệu đĩa cứng dựa trên mốc thời gian `updatedAt`.
    func loadProjects() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let apiProjects = try await networkService.fetchProjects()
            let localSaved = localRepository.loadProjects()
            
            // Hợp nhất dữ liệu: So sánh mốc thời gian updatedAt giữa API và Local
            var mergedProjects = apiProjects
            for localProj in localSaved {
                if let index = mergedProjects.firstIndex(where: { $0.id == localProj.id }) {
                    // Trùng ID: Giữ lại bản ghi có mốc thời gian cập nhật mới hơn
                    let apiProj = mergedProjects[index]
                    if localProj.updatedAt > apiProj.updatedAt {
                        mergedProjects[index] = localProj
                    }
                } else {
                    // Dữ liệu chỉ có ở Local (Chưa đồng bộ lên Server): Thêm vào danh sách
                    mergedProjects.append(localProj)
                }
            }
            
            self.projects = mergedProjects
            localRepository.saveProjects(self.projects) // Ghi đè lại cache đĩa cứng
            
        } catch {
            print("[\(#file):\(#line)] \(#function) - Lỗi API khi tải danh sách dự án: \(error.localizedDescription)")
            self.errorMessage = "Không thể kết nối API. Đang hiển thị dữ liệu cục bộ."
        }
        
        isLoading = false
    }
    
    // MARK: - Data Mutation Operations
    
    /// Khởi tạo và lưu trữ một dự án mới xuống Local Storage.
    /// - Parameter name: Tên của dự án mới cần tạo.
    func addProject(name: String) {
        let newId = (projects.map { $0.id }.max() ?? 0) + 1
        let newProject = Project(id: newId, name: name)
        projects.append(newProject)
        
        // Lưu trữ mảng danh sách mới xuống thiết bị
        localRepository.saveProjects(self.projects)
    }
    
    /// Xóa dự án tại các vị trí được chỉ định và giải phóng dữ liệu Canvas chi tiết.
    /// - Parameter offsets: Tập hợp các vị trí Index trong mảng cần xóa.
    func removeProject(at offsets: IndexSet) {
        // Trích xuất ID các dự án cần xóa
        let idsToDelete = offsets.map { projects[$0].id }
        
        projects.remove(atOffsets: offsets)
        
        // Cập nhật lại danh sách tổng xuống ổ cứng
        localRepository.saveProjects(self.projects)
        
        // Giải phóng hoàn toàn dữ liệu Canvas chi tiết khỏi đĩa cứng
        for id in idsToDelete {
            localRepository.deleteProjectDetail(projectId: id)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Nạp dữ liệu danh sách tổng từ Local Storage
    private func loadProjectsFromLocalStorage() {
        self.projects = localRepository.loadProjects()
    }
}

//import Foundation
//import SwiftUI
//import Observation
//
//@Observable
//@MainActor
//class ProjectListViewModel {
//    private(set) var projects: [Project] = []
//    private(set) var isLoading: Bool = false
//    private(set) var errorMessage: String? = nil
//    
//    // Dependency Injection
//    private let networkService: NetworkServiceProtocol
//    private let localRepository: LocalProjectRepositoryProtocol
//    
//    init(networkService: NetworkServiceProtocol? = nil, localRepository: LocalProjectRepositoryProtocol? = nil) {
//        self.networkService = networkService ?? NetworkManager.shared
//        self.localRepository = localRepository ?? LocalProjectRepository.shared
//        // Khởi tạo và tự động tải danh sách đã lưu cục bộ lên trước để UI hiển thị tức thì
//        loadProjectsFromLocalStorage()
//    }
//    
//    /// Tải danh sách dự án từ API cho Screen 1, đồng thời kết hợp với dữ liệu đã lưu cục bộ.
//    func loadProjects() async {
//        isLoading = true
//        errorMessage = nil
//        do {
//            print("======== BẮT ĐẦU QUÁ TRÌNH MERGE DỮ LIỆU ========")
//            
//            // 1. Tải danh sách từ API
//            let apiProjects = try await networkService.fetchProjects()
//            print("1. [API] Số lượng dự án tải từ API: \(apiProjects.count)")
//            for proj in apiProjects {
//                print("   -> API Proj: ID = \(proj.id), Name = \(proj.name), UpdatedAt = \(proj.updatedAt)")
//            }
//            
//            // 2. Đọc dữ liệu từ bộ nhớ cục bộ
//            let localSaved = localRepository.loadProjects()
//            print("2. [LOCAL] Số lượng dự án trong bộ nhớ máy: \(localSaved.count)")
//            for proj in localSaved {
//                print("   -> Local Proj: ID = \(proj.id), Name = \(proj.name), UpdatedAt = \(proj.updatedAt)")
//            }
//            
//            // 3. Khởi tạo mảng kết quả từ danh sách API
//            var mergedProjects = apiProjects
//            print("\n--- Bắt đầu vòng lặp so sánh từng Local Project ---")
//            
//            // 4. Hợp nhất dữ liệu: So sánh updatedAt giữa API và Local
//            for localProj in localSaved {
//                print("\n[Kiểm tra Local ID = \(localProj.id)]")
//                
//                if let index = mergedProjects.firstIndex(where: { $0.id == localProj.id }) {
//                    // Nếu trùng ID, giữ lại bản mới hơn
//                    let apiProj = mergedProjects[index]
//                    print("   => Trạng thái: Trùng ID \(localProj.id) giữa Local và API.")
//                    print("      + Local UpdatedAt: \(localProj.updatedAt)")
//                    print("      + API UpdatedAt:   \(apiProj.updatedAt)")
//                    
//                    if localProj.updatedAt > apiProj.updatedAt {
//                        print("   ==> KẾT QUẢ: Local MỚI HƠN API -> Ghi đè bản ghi Local vào vị trí [\(index)]")
//                        mergedProjects[index] = localProj
//                    } else {
//                        print("   ==> KẾT QUẢ: Local CŨ HƠN hoặc BẰNG API -> Giữ nguyên bản ghi từ API")
//                    }
//                } else {
//                    // Nếu local có mà API không có (hoặc chưa đồng bộ), thêm vào
//                    print("   => Trạng thái: ID \(localProj.id) chỉ có ở Local (API không có).")
//                    print("   ==> KẾT QUẢ: THÊM MỚI bản ghi Local này vào mảng mergedProjects")
//                    mergedProjects.append(localProj)
//                }
//            }
//            
//            // 5. In tổng hợp danh sách sau khi hợp nhất hoàn tất
//            print("\n======== KẾT QUẢ MERGE HOÀN TẤT ========")
//            print("Tổng số lượng dự án sau khi hợp nhất: \(mergedProjects.count)")
//            for (idx, proj) in mergedProjects.enumerated() {
//                print("   [\(idx)] ID = \(proj.id) | Name = \(proj.name) | UpdatedAt = \(proj.updatedAt)")
//            }
//            print("==========================================\n")
//            
//            self.projects = mergedProjects
//            localRepository.saveProjects(self.projects) // Cập nhật lại bộ nhớ đệm cục bộ
//            
//        } catch {
//            // Danh sách cục bộ đã được nạp sẵn ở init hoặc bộ nhớ đệm, không cần đọc lại từ disk
//            print("❌ [\(#file):\(#line)] \(#function) - Lỗi API khi tải danh sách dự án: \(error.localizedDescription)")
//            self.errorMessage = "Không thể kết nối API. Đang hiển thị dữ liệu cục bộ."
//        }
//        isLoading = false
//    }
//    
//    /// Tạo và lưu trữ một dự án mới cục bộ.
//    ///
//    /// - Parameter name: Tên của dự án mới cần tạo.
//    func addProject(name: String) {
//        let newId = (projects.map { $0.id }.max() ?? 0) + 1
//        let newProject = Project(id: newId, name: name)
//        projects.append(newProject)
//        
//        // Lưu trữ lại toàn bộ danh sách mới xuống thiết bị
//        localRepository.saveProjects(self.projects)
//    }
//    
//    /// Xoá dự án cục bộ tại các vị trí được chỉ định.
//    ///
//    /// - Parameter offsets: Tập hợp các vị trí (index) của dự án cần xoá.
//    func removeProject(at offsets: IndexSet) {
//        // Lấy danh sách ID để xóa chi tiết trước
//        let idsToDelete = offsets.map { projects[$0].id }
//        
//        projects.remove(atOffsets: offsets)
//        
//        // Cập nhật lại danh sách sau khi xóa xuống thiết bị
//        localRepository.saveProjects(self.projects)
//        
//        // Đồng thời xóa luôn detail khỏi ổ cứng để giải phóng bộ nhớ
//        for id in idsToDelete {
//            localRepository.deleteProjectDetail(projectId: id)
//        }
//    }
//    
//    // MARK: - Helper Methods
//    
//    /// Cập nhật trạng thái ứng dụng bằng cách tải dữ liệu từ bộ nhớ cục bộ.
//    private func loadProjectsFromLocalStorage() {
//        self.projects = localRepository.loadProjects()
//    }
//}
