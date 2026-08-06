//
//  InteractiveCanvasView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import UIKit

struct InteractiveCanvasView: UIViewRepresentable {
    let photos: [PhotoFrame]
    let selectedPhotoId: UUID?
    
    // Action closures để đẩy sự kiện về ViewModel
    let onUpdatePhotoFrame: (UUID, FrameRect, Double) -> Void
    let onSelectPhoto: (UUID) -> Void
    let onDeletePhoto: (UUID) -> Void
    let onBackgroundTap: () -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        let zoomContainerView = PassThroughView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        zoomContainerView.backgroundColor = .clear
        scrollView.addSubview(zoomContainerView)
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        containerView.backgroundColor = .canvas
        containerView.clipsToBounds = true
        zoomContainerView.addSubview(containerView)
        
        let uiContainerView = PassThroughView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        uiContainerView.backgroundColor = .clear
        uiContainerView.clipsToBounds = false
        zoomContainerView.addSubview(uiContainerView)
        
        scrollView.contentSize = zoomContainerView.bounds.size
        
        DispatchQueue.main.async {
            scrollView.contentOffset = CGPoint.zero
        }
        
        context.coordinator.zoomContainerView = zoomContainerView
        context.coordinator.containerView = containerView
        context.coordinator.uiContainerView = uiContainerView
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleBackgroundTap(_:)))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = context.coordinator
        scrollView.addGestureRecognizer(tapGesture)
        
        return scrollView
    }
    
    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.update(photos: photos, selectedPhotoId: selectedPhotoId)
    }
    
    class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        var parent: InteractiveCanvasView
        weak var zoomContainerView: UIView?
        weak var containerView: UIView?
        weak var uiContainerView: PassThroughView?
        weak var scrollView: UIScrollView?
        
        var photoViews: [UUID: PhotoContainerView] = [:]
        
        init(_ parent: InteractiveCanvasView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return zoomContainerView
        }
        
        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
            let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
            scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
            
            let scale = scrollView.zoomScale
            for view in photoViews.values {
                view.updateCanvasZoomScale(scale)
            }
        }
        
        @objc func handleBackgroundTap(_ sender: UITapGestureRecognizer) {
            parent.onBackgroundTap()
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            if touch.view is PhotoContainerView || touch.view is UIButton {
                return false
            }
            return true
        }
        
        func update(photos: [PhotoFrame], selectedPhotoId: UUID?) {
            guard let containerView = containerView else { return }
            
            let photoIds = Set(photos.map { $0.id })
            for (id, view) in photoViews {
                if !photoIds.contains(id) {
                    view.imageView.removeFromSuperview()
                    view.removeFromSuperview()
                    photoViews.removeValue(forKey: id)
                }
            }
            
            for photo in photos {
                if let existingView = photoViews[photo.id] {
                    // Tránh cập nhật giao diện ngược lại nếu đang tương tác bằng UIKit (gesture đang chạy)
                    if !existingView.isInteracting {
                        existingView.update(with: photo, isSelected: photo.id == selectedPhotoId)
                    }
                } else {
                    let newView = PhotoContainerView(photo: photo, coordinator: self)
                    newView.updateCanvasZoomScale(scrollView?.zoomScale ?? 1.0)
                    uiContainerView?.addSubview(newView)
                    containerView.addSubview(newView.imageView)
                    photoViews[photo.id] = newView
                    newView.update(with: photo, isSelected: photo.id == selectedPhotoId)
                }
            }
        }
        
        /// Đồng bộ dữ liệu toạ độ và góc xoay từ UIKit về SwiftUI `@Binding`.
        ///
        /// - Parameters:
        ///   - id: ID của ảnh cần cập nhật.
        ///   - newFrame: Khung toạ độ mới (FrameRect).
        ///   - newRotation: Góc xoay mới (Double).
        func updatePhotoFrame(id: UUID, newFrame: FrameRect, newRotation: Double) {
            DispatchQueue.main.async {
                self.parent.onUpdatePhotoFrame(id, newFrame, newRotation)
            }
        }
        
        func selectPhoto(id: UUID) {
            // Hiệu ứng visual tạm thời trước khi ViewModel cập nhật mảng
            if let view = photoViews[id] {
                uiContainerView?.bringSubviewToFront(view)
                containerView?.bringSubviewToFront(view.imageView)
            }
            
            if parent.selectedPhotoId != id {
                DispatchQueue.main.async {
                    self.parent.onSelectPhoto(id)
                }
            }
        }
        
        func deletePhoto(id: UUID) {
            DispatchQueue.main.async {
                self.parent.onDeletePhoto(id)
            }
        }
    }
}

// Lớp View cho phép Touch đi xuyên qua những phần trong suốt (bằng cách trả về nil nếu hit vào chính nó)
class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Duyệt ngược danh sách subviews (view nào add sau/nổi lên trên thì xét trước)
        for subview in subviews.reversed() {
            guard subview.isUserInteractionEnabled, !subview.isHidden, subview.alpha >= 0.01 else { continue }
            
            // Chuyển đổi toạ độ sang subview
            let pointInSubview = subview.convert(point, from: self)
            
            // Hỏi subview xem nó (hoặc con của nó) có nhận touch này không
            if let hitView = subview.hitTest(pointInSubview, with: event) {
                return hitView
            }
        }
        
        // Nếu không có subview nào nhận (chạm vào nền trống), trả về nil để xuyên qua
        return nil
    }
}
