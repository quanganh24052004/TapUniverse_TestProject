//
//  InteractiveCanvasView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import UIKit

struct InteractiveCanvasView: UIViewRepresentable {
    // MARK: - Properties
    
    /// Danh sách các bức ảnh hiển thị trên Canvas
    let photos: [PhotoFrame]
    
    /// ID của bức ảnh đang được người dùng chọn (null nếu bấm ra ngoài)
    let selectedPhotoId: UUID?
    
    // MARK: - Callbacks (UIKit -> SwiftUI Data Flow)
    
    /// Callback cập nhật tọa độ, kích thước và góc xoay mới của ảnh
    let onUpdatePhotoFrame: (UUID, FrameRect, Double) -> Void
    
    /// Callback chọn bức ảnh
    let onSelectPhoto: (UUID) -> Void
    
    /// Callback yêu cầu xóa bức ảnh
    let onDeletePhoto: (UUID) -> Void
    
    /// Callback khi người dùng chạm vào vùng trống của Canvas
    let onBackgroundTap: () -> Void
    
    // MARK: - UIViewRepresentable Lifecycle
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    /// Khởi tạo và cấu hình không gian làm việc UIKit (UIScrollView & Containers)
    func makeUIView(context: Context) -> UIScrollView {
        // 1. Cấu hình ScrollView nền tảng cho việc Thu phóng (Zooming) & Cuộn (Scrolling)
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        let defaultRect = CGRect(origin: .zero, size: AppConstants.Canvas.defaultSize)
        
        // 2. Tầng 1: Container thu phóng tổng thể (Zoom Container)
        let zoomContainerView = PassThroughView(frame: defaultRect)
        zoomContainerView.backgroundColor = .clear
        scrollView.addSubview(zoomContainerView)
        
        // 3. Tầng 2: Container chứa hình ảnh thô (Cắt tỉa phần thừa ngoài biên Canvas)
        let containerView = UIView(frame: defaultRect)
        containerView.backgroundColor = .canvas
        containerView.clipsToBounds = true
        zoomContainerView.addSubview(containerView)
        
        // 4. Tầng 3: Container chứa khung chọn & nút điều khiển (Không cắt viền)
        let uiContainerView = PassThroughView(frame: defaultRect)
        uiContainerView.backgroundColor = .clear
        uiContainerView.clipsToBounds = false
        zoomContainerView.addSubview(uiContainerView)
        
        // 5. Cài đặt Content Size & Reset vị trí cuộn ban đầu
        scrollView.contentSize = zoomContainerView.bounds.size
        DispatchQueue.main.async {
            scrollView.contentOffset = CGPoint.zero
        }
        
        // 6. Lưu tham chiếu các View vào Coordinator
        context.coordinator.zoomContainerView = zoomContainerView
        context.coordinator.containerView = containerView
        context.coordinator.uiContainerView = uiContainerView
        context.coordinator.scrollView = scrollView
        
        // 7. Gán Cử chỉ chạm nền (Background Tap) để bỏ chọn ảnh
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleBackgroundTap(_:))
        )
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        scrollView.addGestureRecognizer(tapGesture)
        
        return scrollView
    }
    
    /// Đồng bộ dữ liệu mảng ảnh từ SwiftUI ViewModel sang UIKit khi State thay đổi
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.update(
            scrollView: scrollView,
            photos: photos,
            selectedPhotoId: selectedPhotoId
        )
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        
        // MARK: - Properties
        
        /// Tham chiếu ngược trỏ về Container View SwiftUI
        var parent: InteractiveCanvasView
        
        /// Các tham chiếu yếu (weak) tới hệ thống View UIKit để tránh Retain Cycle
        weak var zoomContainerView: UIView?
        weak var containerView: UIView?
        weak var uiContainerView: PassThroughView?
        weak var scrollView: UIScrollView?
        
        /// Lưu trữ danh sách View đại diện cho từng bức ảnh dựa trên UUID
        var photoViews: [UUID: PhotoContainerView] = [:]
        
        // MARK: - Initialization
        
        init(_ parent: InteractiveCanvasView) {
            self.parent = parent
        }
        
        // MARK: - UIScrollViewDelegate (Zoom & Centering)
        
        /// Chỉ định View sẽ chịu tác động phóng to / thu nhỏ khi chụm 2 ngón tay
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return zoomContainerView
        }
        
        /// Tự động căn giữa Canvas và nghịch đảo tỉ lệ Zoom cho các nút UI
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // 1. Căn giữa Canvas trong không gian ScrollView khi thu nhỏ
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
            
            // 2. Cập nhật scale nghịch đảo để giữ nguyên kích thước vật lý của nút xóa & 4 góc neo
            let scale = scrollView.zoomScale
            for view in photoViews.values {
                view.updateCanvasZoomScale(scale)
            }
        }
        
        // MARK: - UIGestureRecognizerDelegate (Gesture Filtering)
        
        /// Xử lý sự kiện khi người dùng chạm vào vùng trống rỗng của Canvas
        @objc func handleBackgroundTap(_ sender: UITapGestureRecognizer) {
            parent.onBackgroundTap()
        }
        
        /// Lọc điểm chạm: Bỏ qua gesture chạm nền nếu người dùng bấm trực tiếp vào ảnh hoặc nút bấm
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if touch.view is PhotoContainerView || touch.view is UIButton {
                return false
            }
            return true
        }
        
        // MARK: - Diffing & UI Synchronization
        
        /// Cập nhật cây phân cấp View trong UIKit khi mảng `photos` từ SwiftUI thay đổi
        func update(scrollView: UIScrollView, photos: [PhotoFrame], selectedPhotoId: UUID?) {
            guard let containerView = containerView else { return }
            
            // Step 1: Loại bỏ các PhotoContainerView đã bị xóa khỏi Model
            let photoIds = Set(photos.map { $0.id })
            for (id, view) in photoViews where !photoIds.contains(id) {
                view.imageView.removeFromSuperview()
                view.removeFromSuperview()
                photoViews.removeValue(forKey: id)
            }
            
            // Step 2: Cập nhật View hiện có hoặc khởi tạo View mới
            for photo in photos {
                if let existingView = photoViews[photo.id] {
                    // Không cập nhật nếu người dùng đang trực tiếp di chuyển/xoay ảnh bằng UIKit
                    if !existingView.isInteracting {
                        existingView.update(with: photo, isSelected: photo.id == selectedPhotoId)
                    }
                } else {
                    // Khởi tạo View mới cho bức ảnh vừa chèn
                    let newView = PhotoContainerView(photo: photo, coordinator: self)
                    uiContainerView?.addSubview(newView)
                    containerView.addSubview(newView.imageView)
                    photoViews[photo.id] = newView
                    newView.update(with: photo, isSelected: photo.id == selectedPhotoId)
                    
                    // Đồng bộ tỷ lệ zoom hiện tại cho View mới sinh ra sau khi hoàn tất layout
                    DispatchQueue.main.async { [weak newView, weak scrollView] in
                        guard let newView, let scrollView else { return }
                        newView.updateCanvasZoomScale(scrollView.zoomScale)
                    }
                }
            }
        }
        
        // MARK: - SwiftUI Callbacks (UIKit -> SwiftUI Data Flow)
        
        /// Đồng bộ dữ liệu toạ độ và góc xoay từ UIKit về SwiftUI ViewModel
        ///
        /// - Parameters:
        ///   - id: ID của ảnh cần cập nhật.
        ///   - newFrame: Khung toạ độ mới (FrameRect).
        ///   - newRotation: Góc xoay mới (Double).
        func updatePhotoFrame(id: UUID, newFrame: FrameRect, newRotation: Double) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.parent.onUpdatePhotoFrame(id, newFrame, newRotation)
            }
        }
        
        /// Chuyển vị trí hiển thị (Z-Index) lên trên cùng và thông báo chọn ảnh
        func selectPhoto(id: UUID) {
            if let view = photoViews[id] {
                uiContainerView?.bringSubviewToFront(view)
                containerView?.bringSubviewToFront(view.imageView)
            }
            
            if parent.selectedPhotoId != id {
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.parent.onSelectPhoto(id)
                }
            }
        }
        
        /// Bắn tín hiệu yêu cầu xóa ảnh về SwiftUI
        func deletePhoto(id: UUID) {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.parent.onDeletePhoto(id)
            }
        }
    }
}


// MARK: - Pass-Through Container View

extension InteractiveCanvasView {
    /// Một `UIView` đặc biệt cho phép các sự kiện chạm (Touch Events) xuyên qua khoảng trống trong suốt.
    ///
    /// - Note: Nếu điểm chạm trúng View con (ví dụ: `PhotoContainerView`, `UIButton`), View con đó sẽ nhận tương tác.
    ///         Nếu chạm vào vùng khoảng trống rỗng, hàm sẽ trả về `nil` để sự kiện rơi xuống `UIScrollView` ở tầng dưới.
    class PassThroughView: UIView {
        
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            // 1. Duyệt ngược danh sách subviews để ưu tiên kiểm tra các lớp hiển thị trên cùng (Z-Index cao nhất)
            for subview in subviews.reversed() {
                // Bỏ qua các subview không thể nhận tương tác
                guard subview.isUserInteractionEnabled,
                      !subview.isHidden,
                      subview.alpha >= 0.01 else {
                    continue
                }
                
                // 2. Quy đổi tọa độ điểm chạm từ PassThroughView sang hệ quy chiếu của subview
                let pointInSubview = subview.convert(point, from: self)
                
                // 3. Nếu subview (hoặc View con bên trong nó) nhận điểm chạm, trả về hitView đó
                if let hitView = subview.hitTest(pointInSubview, with: event) {
                    return hitView
                }
            }
            
            // 4. Chạm vào vùng trống rỗng: Trả về nil để cho phép Touch xuyên qua lớp View này
            return nil
        }
    }
}
