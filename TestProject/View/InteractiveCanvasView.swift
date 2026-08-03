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
        scrollView.minimumZoomScale = 0.5
        scrollView.maximumZoomScale = 4.0
        scrollView.delegate = context.coordinator
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        
        // Giả lập không gian làm việc rộng rãi cho Canvas
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 1000, height: 1000))
        containerView.backgroundColor = .clear
        scrollView.addSubview(containerView)
        scrollView.contentSize = containerView.bounds.size
        
        // Cuộn khung hiển thị về góc trên cùng bên trái (0, 0)
        DispatchQueue.main.async {
            scrollView.contentOffset = CGPoint.zero
        }
        
        context.coordinator.containerView = containerView
        context.coordinator.scrollView = scrollView
        
        // Tap vào khoảng trống để hủy chọn ảnh
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
        
        @objc func handleBackgroundTap(_ sender: UITapGestureRecognizer) {
            DispatchQueue.main.async {
                self.parent.selectedPhotoId = nil
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            // Kiểm tra xem vị trí chạm có nằm trên PhotoContainerView nào không
            if let view = touch.view {
                var currentView: UIView? = view
                while let v = currentView {
                    if v is PhotoContainerView {
                        // Nếu chạm vào ảnh, bỏ qua gesture của nền để không bị hủy chọn
                        return false
                    }
                    currentView = v.superview
                }
            }
            return true
        }
        
        func update(photos: [PhotoFrame], selectedPhotoId: UUID?) {
            guard let containerView = containerView else { return }
            
            // 1. Xóa các view tương ứng với ảnh đã bị xóa khỏi mảng
            let photoIds = Set(photos.map { $0.id })
            for (id, view) in photoViews {
                if !photoIds.contains(id) {
                    view.removeFromSuperview()
                    photoViews.removeValue(forKey: id)
                }
            }
            
            // 2. Thêm mới hoặc cập nhật view hiện có
            for photo in photos {
                if let existingView = photoViews[photo.id] {
                    // Tránh cập nhật giao diện ngược lại nếu đang tương tác bằng UIKit (gesture đang chạy)
                    if !existingView.isInteracting {
                        existingView.update(with: photo, isSelected: photo.id == selectedPhotoId)
                    }
                } else {
                    let newView = PhotoContainerView(photo: photo, coordinator: self)
                    containerView.addSubview(newView)
                    photoViews[photo.id] = newView
                    newView.update(with: photo, isSelected: photo.id == selectedPhotoId)
                }
            }
        }
        
        // Đồng bộ dữ liệu từ UIKit về SwiftUI Binding
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

// Wrapper View xử lý UIKit Gestures và Hiển thị ảnh
class PhotoContainerView: UIView, UIGestureRecognizerDelegate {
    var photoId: UUID
    weak var coordinator: InteractiveCanvasView.Coordinator?
    
    var isInteracting = false // Cờ đánh dấu để chặn ghi đè từ SwiftUI khi người dùng đang kéo thả
    
    private let imageView = UIImageView()
    private let deleteButton = UIButton(type: .system)
    
    private var initialCenter = CGPoint.zero
    private var initialBounds = CGRect.zero
    private var initialTransform = CGAffineTransform.identity
    
    init(photo: PhotoFrame, coordinator: InteractiveCanvasView.Coordinator) {
        self.photoId = photo.id
        self.coordinator = coordinator
        super.init(frame: .zero)
        
        setupView()
        loadPhoto(url: photo.url)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.borderColor = UIColor.systemBlue.cgColor
        addSubview(imageView)
        
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        let minusImage = UIImage(systemName: "minus.circle.fill", withConfiguration: config)
        deleteButton.setImage(minusImage, for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 12
        deleteButton.clipsToBounds = true
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        addSubview(deleteButton)
    }
    
    private func loadPhoto(url: String) {
        guard let imageURL = URL(string: url) else { return }
        URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            }
        }.resume()
    }
    
    func update(with photo: PhotoFrame, isSelected: Bool) {
        bounds = CGRect(x: 0, y: 0, width: photo.frame.width, height: photo.frame.height)
        center = CGPoint(x: photo.frame.x + photo.frame.width/2, y: photo.frame.y + photo.frame.height/2)
        transform = CGAffineTransform(rotationAngle: CGFloat(Angle(degrees: photo.rotation).radians))
        alpha = CGFloat(photo.opacity)
        
        imageView.frame = bounds
        imageView.layer.borderWidth = isSelected ? 2 : 0
        
        deleteButton.frame = CGRect(x: bounds.width - 15, y: -15, width: 30, height: 30)
        deleteButton.isHidden = !isSelected
        
        if isSelected {
            superview?.bringSubviewToFront(self)
        }
    }
    
    @objc private func handleDelete() {
        coordinator?.deletePhoto(id: photoId)
    }
    
    // MARK: - Gestures Setup
    private func setupGestures() {
        isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        addGestureRecognizer(pan)
        
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinch.delegate = self
        addGestureRecognizer(pinch)
        
        let rotation = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotation.delegate = self
        addGestureRecognizer(rotation)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        coordinator?.selectPhoto(id: photoId)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        switch gesture.state {
        case .began:
            isInteracting = true
            initialCenter = center
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
        default: break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            initialBounds = bounds
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            let scale = gesture.scale
            bounds = CGRect(x: 0, y: 0, width: initialBounds.width * scale, height: initialBounds.height * scale)
            imageView.frame = bounds
            deleteButton.frame = CGRect(x: bounds.width - 15, y: -15, width: 30, height: 30)
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
        default: break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            initialTransform = transform
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            transform = initialTransform.rotated(by: gesture.rotation)
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
        default: break
        }
    }
    
    private func saveCurrentState() {
        let currentWidth = bounds.width
        let currentHeight = bounds.height
        let currentX = center.x - currentWidth/2
        let currentY = center.y - currentHeight/2
        
        let newFrame = FrameRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
        
        let radians = atan2(transform.b, transform.a)
        let degrees = radians * 180 / .pi
        
        coordinator?.updatePhotoFrame(id: photoId, newFrame: newFrame, newRotation: Double(degrees))
    }
    
    // Hỗ trợ xử lý đa chạm đồng thời
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Chìa khóa sửa lỗi:
        // Chỉ cho phép đồng thời các cử chỉ thuộc về chính PhotoContainerView này (ví dụ: vừa xoay vừa phóng to ảnh).
        // Ngăn chặn đồng thời với các cử chỉ của UIScrollView bên ngoài (tránh việc di chuyển/zoom nền khi đang thao tác trên ảnh).
        return gestureRecognizer.view == self && otherGestureRecognizer.view == self
    }
}
