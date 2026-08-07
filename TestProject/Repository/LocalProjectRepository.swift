//
//  LocalProjectRepository.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

protocol LocalProjectRepositoryProtocol {
    func saveProjects(_ projects: [Project])
    func loadProjects() -> [Project]
    func saveProjectDetail(_ detail: ProjectDetail)
    func loadProjectDetail(projectId: Int) -> ProjectDetail?
    func deleteProjectDetail(projectId: Int)
}

class LocalProjectRepository: LocalProjectRepositoryProtocol {
    static let shared = LocalProjectRepository()
    
    private let userDefaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    private init() {}
    
    func saveProjects(_ projects: [Project]) {
        do {
            let data = try encoder.encode(projects)
            userDefaults.set(data, forKey: AppConstants.UserDefaultsKeys.savedLocalProjects)
            print("Đã lưu thành công danh sách dự án cục bộ.")
        } catch {
            print("Lỗi mã hóa dữ liệu danh sách dự án: \(error)")
        }
    }
    
    func loadProjects() -> [Project] {
        guard let data = userDefaults.data(forKey: AppConstants.UserDefaultsKeys.savedLocalProjects) else {
            return []
        }
        do {
            return try decoder.decode([Project].self, from: data)
        } catch {
            print("Lỗi giải mã danh sách dự án đã lưu: \(error)")
            return []
        }
    }
    
    func saveProjectDetail(_ detail: ProjectDetail) {
        do {
            let data = try encoder.encode(detail)
            let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: detail.id)
            userDefaults.set(data, forKey: key)
        } catch {
            print("Lỗi lưu chi tiết dự án local storage: \(error)")
        }
    }
    
    func loadProjectDetail(projectId: Int) -> ProjectDetail? {
        let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: projectId)
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        do {
            return try decoder.decode(ProjectDetail.self, from: data)
        } catch {
            print("Lỗi tải chi tiết dự án local storage: \(error)")
            return nil
        }
    }
    
    func deleteProjectDetail(projectId: Int) {
        let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: projectId)
        userDefaults.removeObject(forKey: key)
    }
}
