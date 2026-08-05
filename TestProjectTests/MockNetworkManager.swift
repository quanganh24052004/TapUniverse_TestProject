//
//  MockNetworkManager.swift
//  TestProjectTests
//

import Foundation
@testable import TestProject

class MockNetworkManager: NetworkServiceProtocol {
    
    // Properties để cấu hình Mock (Mô phỏng dữ liệu hoặc lỗi)
    var shouldReturnError = false
    var mockProjects: [Project] = []
    var mockProjectDetail: ProjectDetail?
    
    // Các property để kiểm chứng (Spy)
    var fetchProjectsCalledCount = 0
    var fetchProjectDetailCalledCount = 0
    var saveProjectDetailCalledCount = 0
    var lastSavedProjectDetail: ProjectDetail?
    
    func fetchProjects() async throws -> [Project] {
        fetchProjectsCalledCount += 1
        
        if shouldReturnError {
            throw NetworkError.invalidResponse
        }
        return mockProjects
    }
    
    func fetchProjectDetail(projectId: Int) async throws -> ProjectDetail {
        fetchProjectDetailCalledCount += 1
        
        if shouldReturnError {
            throw NetworkError.invalidResponse
        }
        
        if let detail = mockProjectDetail {
            return detail
        } else {
            // Fallback default mock
            return ProjectDetail(id: projectId, name: "Mock Project", photos: [])
        }
    }
    
    func saveProjectDetail(projectDetail: ProjectDetail) async throws {
        saveProjectDetailCalledCount += 1
        lastSavedProjectDetail = projectDetail
        
        if shouldReturnError {
            throw NetworkError.invalidResponse
        }
    }
}
