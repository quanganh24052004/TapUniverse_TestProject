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
    @Published var saveStatus: String = ""
    
    // UI States
    @Published var selectedPhotoId: UUID? = nil
    @Published var isShowingPhotoPicker = false
    @Published var isExporting = false
    @Published var isShowingShareSheet = false
    @Published var exportItem: UIImage? = nil
    
    private var cancellables = Set<AnyCancellable>()
    private var isFirstLoad = true
    
    let projectId: Int
    let projectName: String
    private let networkService: NetworkServiceProtocol
    
    init(projectId: Int, projectName: String, networkService: NetworkServiceProtocol? = nil) {
        self.projectId = projectId
        self.projectName = projectName
        self.networkService = networkService ?? NetworkManager.shared
        
        setupAutoSave()
    }
    
    private func setupAutoSave() {
        $selectedProjectDetail
            .dropFirst() // Bỏ qua lần khởi tạo ban đầu (nil)
            .debounce(for: .seconds(1.0), scheduler: RunLoop.main)
            .sink { [weak self] updatedDetail in
                guard let self = self, let detail = updatedDetail else { return }
                // Bỏ qua lần gán đầu tiên từ loadProjectDetail()
                if self.isFirstLoad {
                    self.isFirstLoad = false
                    return
                }
                self.saveProjectToLocalStorage(detail)
            }
            .store(in: &cancellables)
    }
    
    /// Lấy thông tin chi tiết cấu hình Canvas (phục vụ hiển thị Screen 2).
    func loadProjectDetail() async {
        isLoading = true
        errorMessage = nil
        
        // 1. Ưu tiên load từ Local Storage trước
        if let localDetail = loadProjectFromLocalStorage() {
            self.selectedProjectDetail = localDetail
            self.saveStatus = "Đã tải từ máy"
            self.isLoading = false
            return
        }
        
        // 2. Nếu không có local, thử gọi API
        do {
            self.selectedProjectDetail = try await networkService.fetchProjectDetail(projectId: projectId)
            self.saveStatus = "Đã tải từ máy chủ"
        } catch {
            // Xử lý ngoại lệ khi vừa tạo dự án mới (chưa có trên server)
            self.selectedProjectDetail = ProjectDetail(id: projectId, name: projectName, photos: [])
            self.saveStatus = "Đã khởi tạo"
        }
        isLoading = false
    }
    
    /// Đồng bộ hoá (lưu) thông tin dự án hiện tại lên Server (Giai đoạn 6).
    func saveProject() async {
        guard let projectDetail = selectedProjectDetail else { return }
        isLoading = true
        saveStatus = "Đang đồng bộ..."
        do {
            try await networkService.saveProjectDetail(projectDetail: projectDetail)
            saveStatus = "Đã đồng bộ máy chủ"
        } catch {
            self.errorMessage = "Lỗi khi lưu dự án."
            saveStatus = "Đồng bộ thất bại"
        }
        isLoading = false
    }
    
    // MARK: - Local Storage
    
    private func saveProjectToLocalStorage(_ detail: ProjectDetail) {
        self.saveStatus = "Đang lưu..."
        do {
            let data = try JSONEncoder().encode(detail)
            let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: projectId)
            UserDefaults.standard.set(data, forKey: key)
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss"
            self.saveStatus = "Đã lưu cục bộ lúc \(formatter.string(from: Date()))"
        } catch {
            self.saveStatus = "Lưu cục bộ thất bại"
            print("Lỗi lưu local storage: \(error)")
        }
    }
    
    private func loadProjectFromLocalStorage() -> ProjectDetail? {
        let key = AppConstants.UserDefaultsKeys.savedProjectDetail(projectId: projectId)
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        do {
            return try JSONDecoder().decode(ProjectDetail.self, from: data)
        } catch {
            print("Lỗi tải local storage: \(error)")
            return nil
        }
    }
    
    /// Thêm một hoặc nhiều ảnh mới từ URL vào chính giữa không gian Canvas.
    ///
    /// - Parameters:
    ///   - urls: Mảng chứa các đường dẫn (URL) của hình ảnh cần chèn.
    ///   - selectedPhotoId: Trạng thái `inout` để trỏ vào ảnh cuối cùng được thêm vào.
    func addPhotos(urls: [String], into selectedPhotoId: inout UUID?) {
        for url in urls {
            var width: Double = 300
            var height: Double = 300
            
            // Khôi phục tỷ lệ (aspect ratio) gốc của bức ảnh từ file local
            if let imageURL = URL(string: url),
               imageURL.isFileURL,
               let image = UIImage(contentsOfFile: imageURL.path) {
                
                let imageAspect = image.size.width / image.size.height
                if imageAspect > 1 {
                    // Ảnh ngang
                    width = 300
                    height = 300 / imageAspect
                } else {
                    // Ảnh dọc hoặc vuông
                    height = 300
                    width = 300 * imageAspect
                }
            }
            
            let newPhoto = PhotoFrame(
                url: url,
                frame: FrameRect(x: 500 - width/2, y: 500 - height/2, width: width, height: height), // Đặt ngay giữa Canvas 1000x1000
                rotation: 0.0,
                opacity: 1.0
            )
            selectedProjectDetail?.photos.append(newPhoto)
            selectedPhotoId = newPhoto.id
        }
    }
    
    // MARK: - Photo Operations (MVVM Logic)
    
    func deletePhoto(id: UUID) {
        selectedProjectDetail?.photos.removeAll { $0.id == id }
        if selectedPhotoId == id {
            selectedPhotoId = nil
        }
    }
    
    func bringPhotoToFront(id: UUID) {
        guard let index = selectedProjectDetail?.photos.firstIndex(where: { $0.id == id }) else { return }
        let photo = selectedProjectDetail!.photos.remove(at: index)
        selectedProjectDetail!.photos.append(photo)
        selectedPhotoId = id
    }
    
    func updatePhoto(_ updatedPhoto: PhotoFrame) {
        guard let index = selectedProjectDetail?.photos.firstIndex(where: { $0.id == updatedPhoto.id }) else { return }
        selectedProjectDetail?.photos[index] = updatedPhoto
    }
    
    /// Bắt đầu quá trình kết xuất ảnh. Cập nhật các UI state tương ứng.
    func triggerExportCanvas() {
        isExporting = true
        exportCanvas { [weak self] image in
            guard let self = self else { return }
            self.exportItem = image
            self.isExporting = false
            if image != nil {
                self.isShowingShareSheet = true
            }
        }
    }
    
    /// Kết xuất toàn bộ cấu trúc Canvas hiện tại thành một bức ảnh thực tế (JPEG).
    /// Quá trình này được đẩy sang Background Queue để không làm chặn (block) giao diện người dùng.
    ///
    /// - Parameter completion: Hàm callback trả về `UIImage` hoàn chỉnh, hoặc `nil` nếu rỗng/lỗi.
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
