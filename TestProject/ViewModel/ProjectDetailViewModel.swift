//
//  ProjectDetailViewModel.swift
//  TestProject
//

import Foundation
import SwiftUI
import Observation

// MARK: - Project Detail ViewModel

/// ViewModel quản lý dữ liệu chi tiết Canvas, các thao tác chỉnh sửa ảnh, tự động lưu ngầm và kết xuất hình ảnh.
@Observable
@MainActor
class ProjectDetailViewModel {
    
    // MARK: - Observable Properties (State & UI)
    
    /// Thông tin chi tiết Canvas dự án. Khi thay đổi sẽ tự động kích hoạt Auto-save ngầm
    private(set) var selectedProjectDetail: ProjectDetail? = nil {
        didSet {
            if isFirstLoad {
                isFirstLoad = false
                return
            }
            if let detail = selectedProjectDetail {
                scheduleAutoSave(detail)
            }
        }
    }
    
    /// Trạng thái đang tải dữ liệu Canvas
    private(set) var isLoading: Bool = false
    
    /// Thông báo lỗi hiển thị trên UI
    private(set) var errorMessage: String? = nil
    
    /// Chuỗi hiển thị trạng thái lưu (ví dụ: "Đang lưu...", "Đã lưu cục bộ lúc...")
    private(set) var saveStatus: String = ""
    
    // MARK: - UI States
    
    /// ID của bức ảnh đang được chọn trên Canvas
    var selectedPhotoId: UUID? = nil
    
    /// Trạng thái ẩn/hiện Sheet chọn ảnh từ thư viện
    var isShowingPhotoPicker = false
    
    /// Trạng thái xoay ProgressView khi đang phẳng hóa (render) Canvas
    var isExporting = false
    
    /// Trạng thái ẩn/hiện Share Sheet
    var isShowingShareSheet = false
    
    /// Bức ảnh `UIImage` đã xuất để sẵn sàng chia sẻ
    var exportItem: UIImage? = nil
    
    // MARK: - Observation Ignored Properties
    
    /// Cờ đánh dấu lần nạp dữ liệu đầu tiên để tránh kích hoạt Auto-save dư thừa
    @ObservationIgnored
    private var isFirstLoad = true
    
    /// Task quản lý việc trì hoãn (Debounce) tiến trình Auto-save
    @ObservationIgnored
    private var saveTask: Task<Void, Never>?
    
    // MARK: - Dependencies & Init Parameters
    
    let projectId: Int
    let projectName: String
    private let networkService: NetworkServiceProtocol
    private let localRepository: LocalProjectRepositoryProtocol
    
    // MARK: - Initialization
    
    init(
        projectId: Int,
        projectName: String,
        networkService: NetworkServiceProtocol? = nil,
        localRepository: LocalProjectRepositoryProtocol? = nil
    ) {
        self.projectId = projectId
        self.projectName = projectName
        self.networkService = networkService ?? NetworkManager.shared
        self.localRepository = localRepository ?? LocalProjectRepository.shared
    }
    
    // MARK: - Auto Save & Debounce Logic
    
    /// Thiết lập lịch lưu ngầm tự động với khoảng hoãn (Debounce) 1 giây
    private func scheduleAutoSave(_ detail: ProjectDetail) {
        saveTask?.cancel()
        saveTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 1_000_000_000) // Debounce 1s
                guard !Task.isCancelled, let self else { return }
                self.saveProjectToLocalStorage(detail)
            } catch {
                // Task bị hủy khi người dùng tiếp tục thao tác
            }
        }
    }
    
    // MARK: - Load & Sync Operations
    
    /// Tải thông tin chi tiết cấu hình Canvas (Ưu tiên nạp từ Local Storage)
    func loadProjectDetail() async {
        isLoading = true
        errorMessage = nil
        
        // 1. Ưu tiên nạp dữ liệu từ Local Storage
        if let localDetail = loadProjectFromLocalStorage() {
            self.selectedProjectDetail = localDetail
            self.saveStatus = "Đã tải từ máy"
            self.isLoading = false
            return
        }
        
        // 2. Nếu local chưa có, gọi API lấy dữ liệu từ server
        do {
            self.selectedProjectDetail = try await networkService.fetchProjectDetail(projectId: projectId)
            self.saveStatus = "Đã tải từ máy chủ"
        } catch {
            // Khởi tạo Canvas rỗng nếu dự án mới tạo chưa tồn tại trên server
            self.selectedProjectDetail = ProjectDetail(id: projectId, name: projectName, photos: [])
            self.saveStatus = "Đã khởi tạo"
        }
        isLoading = false
    }
    
    /// Đồng bộ thông tin dự án hiện tại lên Server ngầm
    func saveProject() async {
        guard let projectDetail = selectedProjectDetail else { return }
        saveStatus = "Đang đồng bộ..."
        do {
            try await networkService.saveProjectDetail(projectDetail: projectDetail)
            saveStatus = "Đã đồng bộ máy chủ"
        } catch {
            saveStatus = "Đồng bộ thất bại"
        }
    }
    
    // MARK: - Local Storage Pipeline
    
    /// Thực hiện đóng mốc thời gian `updatedAt` và lưu tức thì trước khi đóng màn hình
    func prepareForExit() {
        guard var detail = selectedProjectDetail else { return }
        let now = Date()
        detail.updatedAt = now
        self.selectedProjectDetail = detail
        
        self.saveStatus = "Đang lưu..."
        
        // 1. Lưu Tầng 2 (Detail Canvas)
        localRepository.saveProjectDetail(detail)
        
        // 2. Cập nhật Tầng 1 (Meta List): Đóng mốc thời gian mới cho danh sách tổng
        var currentProjects = localRepository.loadProjects()
        if let index = currentProjects.firstIndex(where: { $0.id == detail.id }) {
            currentProjects[index].updatedAt = now
            localRepository.saveProjects(currentProjects)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        self.saveStatus = "Đã lưu cục bộ lúc \(formatter.string(from: now))"
    }
    
    /// Lưu dữ liệu Canvas và cập nhật danh sách tổng xuống Local Storage
    private func saveProjectToLocalStorage(_ detail: ProjectDetail) {
        self.saveStatus = "Đang lưu..."
        var updatedDetail = detail
        let now = Date()
        updatedDetail.updatedAt = now
        
        // 1. Lưu Tầng 2 (Detail Canvas)
        localRepository.saveProjectDetail(updatedDetail)
        
        // 2. Cập nhật Tầng 1 (Meta List)
        var currentProjects = localRepository.loadProjects()
        if let index = currentProjects.firstIndex(where: { $0.id == detail.id }) {
            currentProjects[index].updatedAt = now
            localRepository.saveProjects(currentProjects)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        self.saveStatus = "Đã lưu cục bộ lúc \(formatter.string(from: now))"
    }
    
    /// Đọc chi tiết dự án từ Local Storage
    private func loadProjectFromLocalStorage() -> ProjectDetail? {
        return localRepository.loadProjectDetail(projectId: projectId)
    }
    
    // MARK: - Canvas Photo Operations
    
    /// Thêm một hoặc nhiều ảnh mới từ URL vào giữa Canvas (Tự tính toán aspect ratio gốc)
    /// - Parameters:
    ///   - urls: Mảng đường dẫn file ảnh cần thêm
    ///   - selectedPhotoId: Binding cập nhật ID ảnh vừa được thêm vào
    func addPhotos(urls: [String], into selectedPhotoId: inout UUID?) {
        for url in urls {
            var width: Double = 300
            var height: Double = 300
            
            // Khôi phục tỷ lệ khung hình (Aspect Ratio) gốc của bức ảnh từ file local
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
                frame: FrameRect(x: 500 - width/2, y: 500 - height/2, width: width, height: height), // Đặt giữa Canvas 1000x1000
                rotation: 0.0,
                opacity: 1.0
            )
            selectedProjectDetail?.photos.append(newPhoto)
            selectedPhotoId = newPhoto.id
        }
    }
    
    /// Xóa bức ảnh khỏi Canvas
    func deletePhoto(id: UUID) {
        selectedProjectDetail?.photos.removeAll { $0.id == id }
        if selectedPhotoId == id {
            selectedPhotoId = nil
        }
    }
    
    /// Đưa bức ảnh được chọn lên trên cùng của Z-Index Layer
    func bringPhotoToFront(id: UUID) {
        guard let index = selectedProjectDetail?.photos.firstIndex(where: { $0.id == id }) else { return }
        let photo = selectedProjectDetail!.photos.remove(at: index)
        selectedProjectDetail!.photos.append(photo)
        selectedPhotoId = id
    }
    
    /// Cập nhật tọa độ / kích thước / góc xoay của ảnh
    func updatePhoto(_ updatedPhoto: PhotoFrame) {
        guard let index = selectedProjectDetail?.photos.firstIndex(where: { $0.id == updatedPhoto.id }) else { return }
        selectedProjectDetail?.photos[index] = updatedPhoto
    }
    
    /// Cập nhật độ mờ (Opacity) của ảnh
    func updatePhotoOpacity(id: UUID, opacity: Double) {
        guard let index = selectedProjectDetail?.photos.firstIndex(where: { $0.id == id }) else { return }
        selectedProjectDetail?.photos[index].opacity = opacity
    }
    
    // MARK: - Export Canvas Operations
    
    /// Khởi chạy quá trình kết xuất Canvas và hiển thị Share Sheet
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
    
    typealias ExportCompletionHandler = (UIImage?) -> Void
    
    /// Kết xuất toàn bộ Canvas thành file JPEG (Chạy trên Background Thread)
    func exportCanvas(completion: @escaping ExportCompletionHandler) {
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
