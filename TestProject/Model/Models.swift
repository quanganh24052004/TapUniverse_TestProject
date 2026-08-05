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
    
    // Khai báo CodingKeys đầy đủ
    enum CodingKeys: String, CodingKey {
        case id, url, frame, rotation, opacity
    }
    
    // Custom Decode để hỗ trợ lấy từ API (thiếu rotation, opacity, id)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.url = try container.decode(String.self, forKey: .url)
        self.frame = try container.decode(FrameRect.self, forKey: .frame)
        self.rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0.0
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
    }
    
    // Constructor mặc định
    init(id: UUID = UUID(), url: String, frame: FrameRect, rotation: Double = 0.0, opacity: Double = 1.0) {
        self.id = id
        self.url = url
        self.frame = frame
        self.rotation = rotation
        self.opacity = opacity
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
}




