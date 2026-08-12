//
//  Models.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import Foundation

// MARK: - 1. Project List Models

/// Model đại diện cho thông tin tóm tắt của dự án (Dùng cho Màn hình 1 - Danh sách)
struct Project: Identifiable, Codable, Equatable, Hashable {
    
    // MARK: Properties
    
    /// Mã định danh duy nhất của dự án từ Server
    let id: Int
    
    /// Tên dự án
    let name: String
    
    /// Thời gian cập nhật gần nhất (Mặc định là thời điểm khởi tạo)
    var updatedAt: Date = Date()
    
    // MARK: CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case id, name, updatedAt
    }
}

extension Project {
    
    /// Custom Decodable: Gán thời gian hiện tại nếu API không trả về `updatedAt`
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}

/// Struct bọc dữ liệu danh sách dự án trả về từ API
struct ProjectResponse: Codable {
    let projects: [Project]
}

// MARK: - 2. Canvas Geometry Models

/// Khung chứa tọa độ tuyệt đối và kích thước của đối tượng trên Canvas
struct FrameRect: Codable, Equatable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double
}

// MARK: - 3. Photo Frame Model

/// Model quản lý từng bức ảnh đơn lẻ nằm trên mặt phẳng Canvas (Màn hình 2)
struct PhotoFrame: Identifiable, Codable, Equatable {
    
    // MARK: Properties
    
    /// Định danh duy nhất cho từng layer ảnh trên Canvas
    var id = UUID()
    
    /// Đường dẫn ảnh (URL mạng HTTP hoặc đường dẫn file cục bộ trong DocumentDirectory)
    let url: String
    
    /// Khung hình học chứa tọa độ (x, y) và kích thước (width, height)
    var frame: FrameRect
    
    /// Góc xoay của ảnh (tính theo Độ - Degrees)
    var rotation: Double = 0.0
    
    /// Độ mờ / Trong suốt của ảnh (Giá trị từ 0.0 đến 1.0)
    var opacity: Double = 1.0
    
    // MARK: CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case id, url, frame, rotation, opacity
    }
}

extension PhotoFrame {
    
    /// Custom Decodable: Hỗ trợ nạp dữ liệu từ API thiếu các trường mở rộng (id, rotation, opacity)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.url = try container.decode(String.self, forKey: .url)
        self.frame = try container.decode(FrameRect.self, forKey: .frame)
        self.rotation = try container.decodeIfPresent(Double.self, forKey: .rotation) ?? 0.0
        self.opacity = try container.decodeIfPresent(Double.self, forKey: .opacity) ?? 1.0
    }
    
    /// Custom Encodable: Mã hóa toàn bộ dữ liệu photo xuống JSON
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(frame, forKey: .frame)
        try container.encode(rotation, forKey: .rotation)
        try container.encode(opacity, forKey: .opacity)
    }
}

// MARK: - 4. Project Detail Model

/// Model chứa toàn bộ thông tin chi tiết và danh sách ảnh thuộc về một dự án Canvas
struct ProjectDetail: Identifiable, Codable {
    
    // MARK: Properties
    
    /// Mã định danh dự án
    let id: Int
    
    /// Tên dự án
    let name: String
    
    /// Mảng chứa tất cả các layer ảnh trên Canvas
    var photos: [PhotoFrame]
    
    /// Thời gian chỉnh sửa Canvas gần nhất
    var updatedAt: Date = Date()
    
    // MARK: CodingKeys
    
    enum CodingKeys: String, CodingKey {
        case id, name, photos, updatedAt
    }
}

extension ProjectDetail {
    
    /// Custom Decodable: Tự động gán mốc thời gian nếu API không cung cấp
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.photos = try container.decode([PhotoFrame].self, forKey: .photos)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
    }
}
