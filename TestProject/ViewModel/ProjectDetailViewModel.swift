//
//  ProjectDetailViewModel.swift
//  TestProject
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ProjectDetailViewModel: ObservableObject {
    @Published var selectedProjectDetail: ProjectDetail? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    let projectId: Int
    let projectName: String
    private let networkService: NetworkServiceProtocol
    
    init(projectId: Int, projectName: String, networkService: NetworkServiceProtocol = NetworkManager.shared) {
        self.projectId = projectId
        self.projectName = projectName
        self.networkService = networkService
    }
    
    // Gọi API lấy thông tin chi tiết Canvas cho Screen 2
    func loadProjectDetail() async {
        isLoading = true
        errorMessage = nil
        do {
            self.selectedProjectDetail = try await networkService.fetchProjectDetail(projectId: projectId)
        } catch {
            // Sửa lỗi chức năng Thêm dự án mới:
            // Do dự án mới tạo cục bộ chưa tồn tại trên server, API sẽ trả về lỗi (404/decode error).
            // Ta sẽ tạo một ProjectDetail rỗng làm fallback để người dùng bắt đầu vẽ Canvas.
            self.selectedProjectDetail = ProjectDetail(id: projectId, name: projectName, photos: [])
            print("Đã tạo fallback Canvas trống cho dự án mới: \(projectName)")
        }
        isLoading = false
    }
    
    // Gọi API lưu thông tin dự án khi đóng (Giai đoạn 6)
    func saveProject() async {
        guard let projectDetail = selectedProjectDetail else { return }
        isLoading = true
        do {
            try await networkService.saveProjectDetail(projectDetail: projectDetail)
            print("Đã lưu dự án thành công: \(projectDetail.name)")
        } catch {
            self.errorMessage = "Lỗi khi lưu dự án."
            print("Save Error: \(error)")
        }
        isLoading = false
    }
    
    // Thêm các ảnh từ thư viện vào chính giữa Canvas
    func addPhotos(urls: [String], into selectedPhotoId: inout UUID?) {
        for url in urls {
            let newPhoto = PhotoFrame(
                url: url,
                frame: FrameRect(x: 425, y: 425, width: 150, height: 150), // Center of 1000x1000
                rotation: 0.0,
                opacity: 1.0
            )
            selectedProjectDetail?.photos.append(newPhoto)
            selectedPhotoId = newPhoto.id
        }
    }
    
    // Kết xuất Canvas thành ảnh JPEG
    func exportCanvas(completion: @escaping (UIImage?) -> Void) {
        guard let photos = selectedProjectDetail?.photos, !photos.isEmpty else {
            completion(nil)
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let renderSize = CGSize(width: 1024, height: 1024)
            if let jpegData = CanvasRenderer.renderToJPEG(photos: photos, canvasSize: renderSize),
               let uiImage = UIImage(data: jpegData) {
                DispatchQueue.main.async {
                    completion(uiImage)
                }
            } else {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
}
