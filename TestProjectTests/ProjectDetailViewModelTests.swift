//
//  ProjectDetailViewModelTests.swift
//  TestProjectTests
//

import XCTest
@testable import TestProject

@MainActor
final class ProjectDetailViewModelTests: XCTestCase {
    
    var viewModel: ProjectDetailViewModel!
    var mockNetworkManager: MockNetworkManager!
    let testLocalKey = "saved_project_detail_99"
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.removeObject(forKey: testLocalKey)
        mockNetworkManager = MockNetworkManager()
        viewModel = ProjectDetailViewModel(projectId: 99, projectName: "Test Name", networkService: mockNetworkManager)
    }
    
    override func tearDown() {
        viewModel = nil
        mockNetworkManager = nil
        UserDefaults.standard.removeObject(forKey: testLocalKey)
        super.tearDown()
    }
    
    // MARK: - Test Fetch Project Detail (Screen 2)
    func test_FetchProjectDetail_Success() async {
        // Arrange
        let fakePhoto = PhotoFrame(id: UUID(), url: "test.jpg", frame: FrameRect(x: 10, y: 10, width: 100, height: 100), rotation: 45, opacity: 0.8)
        let fakeDetail = ProjectDetail(id: 99, name: "Test Detail", photos: [fakePhoto])
        mockNetworkManager.mockProjectDetail = fakeDetail
        
        // Act
        await viewModel.loadProjectDetail()
        
        // Assert
        XCTAssertEqual(mockNetworkManager.fetchProjectDetailCalledCount, 1)
        XCTAssertNotNil(viewModel.selectedProjectDetail)
        XCTAssertEqual(viewModel.selectedProjectDetail?.name, "Test Detail")
        XCTAssertEqual(viewModel.selectedProjectDetail?.photos.count, 1)
        
        // Test xem Decode toạ độ có chuẩn không
        let photo = viewModel.selectedProjectDetail?.photos.first
        XCTAssertEqual(photo?.frame.x, 10)
        XCTAssertEqual(photo?.frame.width, 100)
        XCTAssertEqual(photo?.rotation, 45)
    }
    
    func test_FetchProjectDetail_NewProject_Fallback() async {
        // Arrange
        mockNetworkManager.shouldReturnError = true // Dự án mới chưa có trên server sẽ lỗi 404
        
        // Act
        await viewModel.loadProjectDetail()
        
        // Assert
        XCTAssertNotNil(viewModel.selectedProjectDetail) // Tạo detail ảo (fallback)
        XCTAssertEqual(viewModel.selectedProjectDetail?.name, "Test Name")
        XCTAssertTrue(viewModel.selectedProjectDetail!.photos.isEmpty)
        XCTAssertNil(viewModel.errorMessage) // Không văng lỗi vì đã fallback
    }
    
    // MARK: - Test Save Project
    func test_SaveProject_Payload() async {
        // Arrange
        let detailToSave = ProjectDetail(id: 99, name: "Save Me", photos: [])
        viewModel.selectedProjectDetail = detailToSave
        
        // Act
        await viewModel.saveProject()
        
        // Assert
        XCTAssertEqual(mockNetworkManager.saveProjectDetailCalledCount, 1)
        XCTAssertNotNil(mockNetworkManager.lastSavedProjectDetail)
        XCTAssertEqual(mockNetworkManager.lastSavedProjectDetail?.id, 99)
        XCTAssertEqual(mockNetworkManager.lastSavedProjectDetail?.name, "Save Me")
    }
    
    // MARK: - Test Local Storage
    func test_LoadProjectDetail_FromLocalStorage() async {
        // Arrange
        let fakePhoto = PhotoFrame(id: UUID(), url: "local.jpg", frame: FrameRect(x: 0, y: 0, width: 50, height: 50))
        let fakeDetail = ProjectDetail(id: 99, name: "Local Detail", photos: [fakePhoto])
        let data = try? JSONEncoder().encode(fakeDetail)
        UserDefaults.standard.set(data, forKey: testLocalKey)
        
        // Act
        await viewModel.loadProjectDetail()
        
        // Assert
        XCTAssertEqual(mockNetworkManager.fetchProjectDetailCalledCount, 0) // API was bypassed
        XCTAssertNotNil(viewModel.selectedProjectDetail)
        XCTAssertEqual(viewModel.selectedProjectDetail?.name, "Local Detail")
        XCTAssertEqual(viewModel.saveStatus, "Đã tải từ máy")
    }
}
