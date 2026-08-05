//
//  PhotoContainerView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import UIKit
import SwiftUI

// MARK: - 1. Properties & Initialization
class PhotoContainerView: UIView {
    var photoId: UUID
    weak var coordinator: InteractiveCanvasView.Coordinator?
    
    var isInteracting = false // Cờ đánh dấu để chặn ghi đè từ SwiftUI khi người dùng đang kéo thả
    
    let imageView = UIImageView()
    let deleteButton = UIButton(type: .system)
    var cornerHandles: [UIView] = []
    
    var initialCenter = CGPoint.zero
    var initialBounds = CGRect.zero
    var initialTransform = CGAffineTransform.identity
    
    // Lưu trạng thái tính toán thu phóng
    var anchorPointInSuper = CGPoint.zero
    var initialDistanceInSuper: CGFloat = 0
    
    // Lưu lại zoom scale của canvas để tự động điều chỉnh kích thước UI ngược lại
    var currentCanvasZoomScale: CGFloat = 1.0
    
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
        self.layer.borderColor = UIColor.systemBlue.cgColor
        addSubview(imageView)
        
        let config = UIImage.SymbolConfiguration(pointSize: 24)
        let minusImage = UIImage(systemName: "xmark.circle.fill", withConfiguration: config)
        deleteButton.setImage(minusImage, for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.layer.cornerRadius = 12
        deleteButton.clipsToBounds = true
        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        addSubview(deleteButton)
        
        // Setup 4 corner handles
        let handleSize: CGFloat = 16
        for i in 0..<4 {
            let handle = UIView(frame: CGRect(x: 0, y: 0, width: handleSize, height: handleSize))
            handle.backgroundColor = .systemBlue
            handle.layer.cornerRadius = handleSize / 2
            handle.tag = i // 0: TL, 1: TR, 2: BL, 3: BR
            handle.isUserInteractionEnabled = true
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan(_:)))
            pan.delegate = self
            handle.addGestureRecognizer(pan)
            
            addSubview(handle)
            cornerHandles.append(handle)
        }
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
    
    @objc private func handleDelete() {
        coordinator?.deletePhoto(id: photoId)
    }
}

// MARK: - 2. Layout & Hit-Testing
extension PhotoContainerView {
    
    // Gom các touch bên trong ảnh về PhotoContainerView (OOP Hit-Testing)
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        
        // Nếu chạm vào nút xóa hoặc điểm neo, để chúng tự xử lý
        if hitView == deleteButton { return hitView }
        for handle in cornerHandles {
            if hitView == handle { return hitView }
        }
        
        // Còn lại, mọi vùng chạm bên trong bounds sẽ báo cáo là PhotoContainerView
        if hitView != nil { return self }
        
        return nil
    }
    
    func updateSubviewsFrames(isSelected: Bool) {
        imageView.frame = bounds
        let inverseScale = 1.0 / currentCanvasZoomScale
        self.layer.borderWidth = isSelected ? (2.0 * inverseScale) : 0
        
        let buttonSize: CGFloat = 30
        deleteButton.bounds = CGRect(x: 0, y: 0, width: buttonSize, height: buttonSize)
        deleteButton.center = CGPoint(x: bounds.width / 2, y: -25 * inverseScale)
        deleteButton.isHidden = !isSelected
        
        guard cornerHandles.count == 4 else { return }
        cornerHandles[0].center = CGPoint(x: 0, y: 0)
        cornerHandles[1].center = CGPoint(x: bounds.width, y: 0)
        cornerHandles[2].center = CGPoint(x: 0, y: bounds.height)
        cornerHandles[3].center = CGPoint(x: bounds.width, y: bounds.height)
        
        for handle in cornerHandles {
            handle.isHidden = !isSelected
        }
    }
}

// MARK: - 3. Update Data (SwiftUI Sync)
extension PhotoContainerView {
    func update(with photo: PhotoFrame, isSelected: Bool) {
        bounds = CGRect(x: 0, y: 0, width: photo.frame.width, height: photo.frame.height)
        center = CGPoint(x: photo.frame.x + photo.frame.width/2, y: photo.frame.y + photo.frame.height/2)
        transform = CGAffineTransform(rotationAngle: CGFloat(Angle(degrees: photo.rotation).radians))
        
        imageView.alpha = CGFloat(photo.opacity)
        
        updateSubviewsFrames(isSelected: isSelected)
        
        if isSelected {
            superview?.bringSubviewToFront(self)
        }
    }
    
    func updateCanvasZoomScale(_ scale: CGFloat) {
        currentCanvasZoomScale = scale
        let inverseScale = 1.0 / scale
        let inverseTransform = CGAffineTransform(scaleX: inverseScale, y: inverseScale)
        
        deleteButton.transform = inverseTransform
        for handle in cornerHandles {
            handle.transform = inverseTransform
        }
        
        updateSubviewsFrames(isSelected: !deleteButton.isHidden)
    }
    
    func saveCurrentState() {
        let currentWidth = bounds.width
        let currentHeight = bounds.height
        let currentX = center.x - currentWidth/2
        let currentY = center.y - currentHeight/2
        
        let newFrame = FrameRect(x: currentX, y: currentY, width: currentWidth, height: currentHeight)
        
        let radians = atan2(transform.b, transform.a)
        let degrees = radians * 180 / .pi
        
        coordinator?.updatePhotoFrame(id: photoId, newFrame: newFrame, newRotation: Double(degrees))
    }
}

// MARK: - 4. Gesture Recognizers
extension PhotoContainerView: UIGestureRecognizerDelegate {
    
    func setupGestures() {
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
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        coordinator?.selectPhoto(id: photoId)
    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        switch gesture.state {
        case .began:
            isInteracting = true
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
        default: break
        }
    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            let scale = gesture.scale
            
            let anchorInLocal = gesture.location(in: self)
            let oldWidth = bounds.width
            let oldHeight = bounds.height
            
            let oldOffset = CGPoint(x: anchorInLocal.x - oldWidth / 2, y: anchorInLocal.y - oldHeight / 2)
            
            let newWidth = oldWidth * scale
            let newHeight = oldHeight * scale
            bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
            updateSubviewsFrames(isSelected: true)
            
            let shiftFactor = 1.0 - scale
            let shiftX = oldOffset.x * shiftFactor
            let shiftY = oldOffset.y * shiftFactor
            
            let rotatedShiftX = shiftX * transform.a + shiftY * transform.c
            let rotatedShiftY = shiftX * transform.b + shiftY * transform.d
            
            center = CGPoint(x: center.x + rotatedShiftX, y: center.y + rotatedShiftY)
            gesture.scale = 1.0
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
        default: break
        }
    }
    
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            isInteracting = true
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            transform = transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
        default: break
        }
    }
    
    @objc func handleCornerPan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view, let superview = self.superview else { return }
        
        switch gesture.state {
        case .began:
            isInteracting = true
            initialBounds = bounds
            initialCenter = center
            initialTransform = transform
            coordinator?.selectPhoto(id: photoId)
            
            let w = initialBounds.width
            let h = initialBounds.height
            var localAnchor = CGPoint.zero
            switch handle.tag {
            case 0: localAnchor = CGPoint(x: w, y: h)
            case 1: localAnchor = CGPoint(x: 0, y: h)
            case 2: localAnchor = CGPoint(x: w, y: 0)
            case 3: localAnchor = CGPoint(x: 0, y: 0)
            default: break
            }
            
            anchorPointInSuper = self.convert(localAnchor, to: superview)
            
            let locationInSuper = gesture.location(in: superview)
            initialDistanceInSuper = hypot(locationInSuper.x - anchorPointInSuper.x, locationInSuper.y - anchorPointInSuper.y)
            
        case .changed:
            guard initialDistanceInSuper > 0 else { return }
            
            let locationInSuper = gesture.location(in: superview)
            let currentDistance = hypot(locationInSuper.x - anchorPointInSuper.x, locationInSuper.y - anchorPointInSuper.y)
            
            var scale = currentDistance / initialDistanceInSuper
            scale = max(0.2, scale)
            
            let newWidth = initialBounds.width * scale
            let newHeight = initialBounds.height * scale
            bounds = CGRect(x: 0, y: 0, width: newWidth, height: newHeight)
            updateSubviewsFrames(isSelected: true)
            
            var newLocalAnchor = CGPoint.zero
            switch handle.tag {
            case 0: newLocalAnchor = CGPoint(x: newWidth, y: newHeight)
            case 1: newLocalAnchor = CGPoint(x: 0, y: newHeight)
            case 2: newLocalAnchor = CGPoint(x: newWidth, y: 0)
            case 3: newLocalAnchor = CGPoint(x: 0, y: 0)
            default: break
            }
            
            let offsetFromCenter = CGPoint(x: newLocalAnchor.x - newWidth / 2, y: newLocalAnchor.y - newHeight / 2)
            
            let rotatedOffsetX = offsetFromCenter.x * transform.a + offsetFromCenter.y * transform.c
            let rotatedOffsetY = offsetFromCenter.x * transform.b + offsetFromCenter.y * transform.d
            
            center = CGPoint(x: anchorPointInSuper.x - rotatedOffsetX, y: anchorPointInSuper.y - rotatedOffsetY)
            
        case .ended, .cancelled:
            isInteracting = false
            saveCurrentState()
            
        default: break
        }
    }
    
    // Hỗ trợ xử lý đa chạm đồng thời
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view == self && otherGestureRecognizer.view == self
    }
}
