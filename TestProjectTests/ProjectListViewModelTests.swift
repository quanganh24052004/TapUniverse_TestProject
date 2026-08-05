//
//  ProjectViewModelTests.swift
//  TestProjectTests
//

import XCTest
@testable import TestProject

@MainActor
final class ProjectListViewModelTests: XCTestCase {
    
    var viewModel: ProjectListViewModel!
    var mockNetworkManager: MockNetworkManager!
    let testLocalProjectsKey = "saved_local_projects"
    
    override func setUp() {
        super.setUp()
        // Xóa dữ liệu cũ trong UserDefaults để test độc lập
        UserDefaults.standard.removeObject(forKey: testLocalProjectsKey)
        
        mockNetworkManager = MockNetworkManager()
        // Khởi tạo ViewModel với Mock Network
        viewModel = ProjectListViewModel(networkService: mockNetworkManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkManager = nil
        UserDefaults.standard.removeObject(forKey: testLocalProjectsKey)
        super.tearDown()
    }
    
    // MARK: - 1. Test Fetch Projects (Screen 1)
    func test_FetchProjects_Success() async {
        // Arrange
        let fakeProject = Project(id: 99, name: "Test API Project")
        mockNetworkManager.mockProjects = [fakeProject]
        
        // Act
        await viewModel.loadProjects()
        
        // Assert
        XCTAssertEqual(mockNetworkManager.fetchProjectsCalledCount, 1)
        XCTAssertEqual(viewModel.projects.count, 1)
        XCTAssertEqual(viewModel.projects.first?.name, "Test API Project")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func test_OfflineFirst_LoadFromUserDefaults() async {
        // Arrange
        // Giả lập lưu 1 project vào local storage
        let localProject = Project(id: 1, name: "Local Project")
        let data = try? JSONEncoder().encode([localProject])
        UserDefaults.standard.set(data, forKey: testLocalProjectsKey)
        
        // Khởi tạo lại viewModel để nó tự load từ local trong hàm init
        viewModel = ProjectListViewModel(networkService: mockNetworkManager)
        
        // Giả lập API lỗi (Mất mạng)
        mockNetworkManager.shouldReturnError = true
        
        // Act
        await viewModel.loadProjects()
        
        // Assert
        XCTAssertEqual(mockNetworkManager.fetchProjectsCalledCount, 1) // Vẫn gọi API
        XCTAssertEqual(viewModel.projects.count, 1) // Nhưng lấy data từ local fallback
        XCTAssertEqual(viewModel.projects.first?.name, "Local Project")
        XCTAssertNotNil(viewModel.errorMessage) // Có thông báo lỗi mạng
    }
    
}
    
    // MARK: - 4. Test Quản lý Dự án (Thêm / Xóa)
    func test_AddProject_UpdatesListAndLocalStorage() {
        // Arrange
        viewModel.projects = [Project(id: 1, name: "Old Project")]
        
        // Act
        viewModel.addProject(name: "Brand New Project")
        
        // Assert
        XCTAssertEqual(viewModel.projects.count, 2)
        XCTAssertEqual(viewModel.projects.last?.name, "Brand New Project")
        XCTAssertEqual(viewModel.projects.last?.id, 2) // ID tự tăng
        
        // Kiểm tra xem đã lưu xuống UserDefaults chưa
        guard let data = UserDefaults.standard.data(forKey: testLocalProjectsKey),
              let savedProjects = try? JSONDecoder().decode([Project].self, from: data) else {
            XCTFail("Không tìm thấy dữ liệu trong UserDefaults")
            return
        }
        XCTAssertEqual(savedProjects.count, 2)
        XCTAssertEqual(savedProjects.last?.name, "Brand New Project")
    }
    
    func test_RemoveProject_UpdatesListAndLocalStorage() {
        // Arrange
        viewModel.projects = [
            Project(id: 1, name: "Proj 1"),
            Project(id: 2, name: "Proj 2"),
            Project(id: 3, name: "Proj 3")
        ]
        
        // Act
        viewModel.removeProject(at: IndexSet(integer: 1)) // Xóa Proj 2
        
        // Assert
        XCTAssertEqual(viewModel.projects.count, 2)
        XCTAssertEqual(viewModel.projects[0].name, "Proj 1")
        XCTAssertEqual(viewModel.projects[1].name, "Proj 3")
        
        // Kiểm tra UserDefaults
        guard let data = UserDefaults.standard.data(forKey: testLocalProjectsKey),
              let savedProjects = try? JSONDecoder().decode([Project].self, from: data) else {
            XCTFail("Không tìm thấy dữ liệu trong UserDefaults")
            return
        }
        XCTAssertEqual(savedProjects.count, 2)
        XCTAssertEqual(savedProjects[1].name, "Proj 3")
    }
}
