//
//  Models.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

// Model của Project
struct Project: Identifiable, Codable, Equatable, Hashable {
    let id: Int
    let name: String
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id, name, updatedAt
    }
}

extension Project {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

// struct của Project
struct ProjectResponse: Codable {
    let projects: [Project]
}

// Khung chứa tọa độ và kích thước tuyệt đối của ảnh
struct FrameRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

//Model quản lý từng bức ảnh trên Canvas
struct PhotoFrame: Identifiable, Codable, Equatable {
    var id = UUID()
    let url: String
    var frame: FrameRect
    
    // Các thuộc tính mở rộng cho các tính năng tinh chỉnh ở Screen 3
    var rotation: Double = 0.0
    var opacity: Double = 1.0
    
    // Khai báo CodingKeys đầy đủ
    enum CodingKeys: String, CodingKey {
        case id, url, frame, rotation, opacity
    }
}

extension PhotoFrame {
    // Custom Decode để hỗ trợ lấy từ API (thiếu rotation, opacity, id)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.url = try container.decode(String.self, forKey: .url)
        self.frame = try container.decode(FrameRect.self, forKey: .frame)
        self.rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0.0
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
    }
    
    // Custom Encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(frame, forKey: .frame)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(opacity, forKey: .opacity)
    }
}
//Model chi tiết dự án nhận từ POST
struct ProjectDetail: Identifiable, Codable {
    let id: Int
    let name: String
    var photos: [PhotoFrame]
    var updatedAt: Date = Date()
    
    enum CodingKeys: String, CodingKey {
        case id, name, photos, updatedAt
    }
}

extension ProjectDetail {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.photos = try container.decode([PhotoFrame].self, forKey: .photos)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}




