//
//  AppConstants.swift
//  TestProject
//

import Foundation
import CoreGraphics

enum AppConstants {
    enum UserDefaultsKeys {
        static let savedLocalProjects = "saved_local_projects"
        static func savedProjectDetail(projectId: Int) -> String {
            return "saved_project_detail_\(projectId)"
        }
    }
    
    enum Canvas {
        static let defaultSize = CGSize(width: 1000, height: 1000)
        static let photoInitialSize = CGSize(width: 150, height: 150)
    }
}
