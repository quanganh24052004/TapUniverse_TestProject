//
//  Models.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

// Model của Project
struct Project: Identifiable, Codable {
    let id: Int
    let name: String
}

// struct của Project
struct ProjectResponse: Codable {
    let projects: [Project]
}

// Khung chứa tọa độ và kích thước tuyệt đối của ảnh
struct FrameRect: Codable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

//Model quản lý từng bức ảnh trên Canvas
struct PhotoFrame: Identifiable, Codable {
    var id = UUID()
    let url: String
    var frame: FrameRect
    
    // Các thuộc tính mở rộng cho các tính năng tinh chỉnh ở Screen 3
    var rotation: Double = 0.0
    var opacity: Double = 1.0
    
    // Omit các trường sinh cục bộ (id, rotation, opacity) khi mã hóa/giải mã API
    enum CodingKeys: String, CodingKey {
        case url
        case frame
    }
}

//Model chi tiết dự án nhận từ POST
struct ProjectDetail: Identifiable, Codable {
    let id: Int
    let name: String
    var photos: [PhotoFrame]
}




