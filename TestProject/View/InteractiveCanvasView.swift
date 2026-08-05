//
//  InteractiveCanvasView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import UIKit

struct InteractiveCanvasView: UIViewRepresentable {
    @Binding var photos: [PhotoFrame]
    @Binding var selectedPhotoId: UUID?
    
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
        
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        containerView.backgroundColor = .canvas
        containerView.clipsToBounds = true
        scrollView.addSubview(containerView)
        scrollView.contentSize = containerView.bounds.size
        
        DispatchQueue.main.async {
            scrollView.contentOffset = CGPoint.zero
        }
        
        context.coordinator.containerView = containerView
        context.coordinator.scrollView = scrollView
        
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
        weak var containerView: UIView?
        weak var scrollView: UIScrollView?
        
        var photoViews: [UUID: PhotoContainerView] = [:]
        
        init(_ parent: InteractiveCanvasView) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return containerView
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
            DispatchQueue.main.async {
                self.parent.selectedPhotoId = nil
            }
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
                    containerView.addSubview(newView)
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
            if let index = parent.photos.firstIndex(where: { $0.id == id }) {
                DispatchQueue.main.async {
                    self.parent.photos[index].frame = newFrame
                    self.parent.photos[index].rotation = newRotation
                }
            }
        }
        
        func selectPhoto(id: UUID) {
            if parent.selectedPhotoId != id {
                DispatchQueue.main.async {
                    self.parent.selectedPhotoId = id
                }
            }
        }
        
        func deletePhoto(id: UUID) {
            if let index = parent.photos.firstIndex(where: { $0.id == id }) {
                DispatchQueue.main.async {
                    self.parent.photos.remove(at: index)
                    if self.parent.selectedPhotoId == id {
                        self.parent.selectedPhotoId = nil
                    }
                }
            }
        }
    }
}


