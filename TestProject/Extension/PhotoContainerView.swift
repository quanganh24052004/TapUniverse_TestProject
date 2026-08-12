//
//  PhotoContainerView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import UIKit
import SwiftUI

// MARK: - Photo Container View (Interactive Layer)

/// View tương tác cho từng bức ảnh trên Canvas.
/// Hỗ trợ kéo di chuyển, xoay 2 ngón, thu phóng pinch-to-zoom và kéo nắn 4 góc.
class PhotoContainerView: UIView {
    
    // MARK: - Properties & Dependencies
    
    /// ID định danh duy nhất của bức ảnh
    var photoId: UUID
    
    /// Tham chiếu yếu (weak) trỏ về Coordinator để phát tín hiệu tương tác
    weak var coordinator: InteractiveCanvasView.Coordinator?
    
    /// Dữ liệu Model hình ảnh hiện tại
    var currentPhotoData: PhotoFrame?
    
    /// Trạng thái ảnh đang được chọn trên Canvas
    var isSelected: Bool = false
    
    // MARK: - Interaction Lock Mechanism
    
    /// Bộ đếm số lượng cử chỉ đang active đồng thời
    var activeInteractionsCount = 0
    
    /// Cờ kiểm tra người dùng có đang trực tiếp di ngón tay trên View hay không
    var isInteracting: Bool { return activeInteractionsCount > 0 }
    
    // MARK: - UI Components
    
    /// Control hiển thị hình ảnh thô
    let imageView = UIImageView()
    
    /// Nút xóa ảnh (Nằm ở cạnh trên)
    let deleteButton = UIButton(type: .system)
    
    /// Danh sách 4 View đại diện cho 4 góc neo điều chỉnh kích thước
    var cornerHandles: [UIView] = []
    
    // MARK: - Gesture Recognizers
    
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var rotationGesture: UIRotationGestureRecognizer!
    
    // MARK: - Geometry State Variables
    
    var initialCenter = CGPoint.zero
    var initialBounds = CGRect.zero
    var initialTransform = CGAffineTransform.identity
    
    var anchorPointInSuper = CGPoint.zero
    var initialDistanceInSuper: CGFloat = 0
    
    /// Tỷ lệ zoom hiện tại của Canvas ScrollView (Dùng để tính nghịch đảo kích thước UI)
    var currentCanvasZoomScale: CGFloat = 1.0 {
        didSet {
            updateSubviewsFrames(isSelected: isSelected)
        }
    }
    
    // MARK: - Property Observers for Auto Sync
    
    override var center: CGPoint {
        didSet { imageView.center = center }
    }
    
    override var bounds: CGRect {
        didSet { imageView.bounds = bounds }
    }
    
    override var transform: CGAffineTransform {
        didSet { imageView.transform = transform }
    }
    
    // MARK: - Initialization
    
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
    
    // MARK: - Setup UI & Photo Loading
    
    private func setupView() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        self.layer.borderColor = UIColor.systemBlue.cgColor

        // Cấu hình Nút xóa (SF Symbol)
        let config = UIImage.SymbolConfiguration(paletteColors: [.white, .systemRed])
        let sizeConfig = UIImage.SymbolConfiguration(pointSize: 24)
        let finalConfig = config.applying(sizeConfig)
        let minusImage = UIImage(systemName: "minus.circle.fill", withConfiguration: finalConfig)
        deleteButton.setImage(minusImage, for: .normal)
        deleteButton.tintColor = .systemRed

        deleteButton.addTarget(self, action: #selector(handleDelete), for: .touchUpInside)
        addSubview(deleteButton)
        
        // Khởi tạo 4 góc neo điều khiển (Corner Handles)
        let handleSize: CGFloat = 16
        for i in 0..<4 {
            let handle = UIView(frame: CGRect(x: 0, y: 0, width: handleSize, height: handleSize))
            handle.backgroundColor = .systemBlue
            handle.layer.cornerRadius = handleSize / 2
            handle.tag = i // 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
            handle.isUserInteractionEnabled = true
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan(_:)))
            pan.delegate = self
            handle.addGestureRecognizer(pan)
            
            addSubview(handle)
            cornerHandles.append(handle)
        }
    }
    
    /// Nạp hình ảnh từ Cache, File đĩa cục bộ hoặc API
    private func loadPhoto(url: String) {
        if let cachedImage = ImageCacheManager.shared.getImage(forKey: url) {
            self.imageView.image = cachedImage
            return
        }
        
        let absoluteURL: URL?
        if url.starts(with: "http") {
            absoluteURL = URL(string: url)
        } else {
            let filename = (url as NSString).lastPathComponent
            if let docDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                absoluteURL = docDir.appendingPathComponent(filename)
            } else {
                absoluteURL = nil
            }
        }
        
        guard let imageURL = absoluteURL else { return }
        
        if !url.starts(with: "http") {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                if let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) {
                    ImageCacheManager.shared.saveImage(image, forKey: url)
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }
        } else {
            URLSession.shared.dataTask(with: imageURL) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    ImageCacheManager.shared.saveImage(image, forKey: url)
                    DispatchQueue.main.async {
                        self?.imageView.image = image
                    }
                }
            }.resume()
        }
    }
    
    @objc private func handleDelete() {
        coordinator?.deletePhoto(id: photoId)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateSubviewsFrames(isSelected: isSelected)
    }
}

// MARK: - Layout & Hit-Testing Customization

extension PhotoContainerView {
    
    /// Kiểm tra thủ công điểm chạm cho nút xóa và 4 góc neo khi chúng nằm ngoài bounds của View
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 1. Kiểm tra điểm chạm vào Nút Xóa
        if !deleteButton.isHidden {
            let pointInButton = convert(point, to: deleteButton)
            if deleteButton.bounds.contains(pointInButton) {
                return deleteButton
            }
        }
        
        // 2. Kiểm tra điểm chạm vào 4 Góc neo
        for handle in cornerHandles {
            if !handle.isHidden {
                let pointInHandle = convert(point, to: handle)
                if handle.bounds.contains(pointInHandle) {
                    return handle
                }
            }
        }
        
        // 3. Kiểm tra điểm chạm trong lòng bức ảnh
        if bounds.contains(point) {
            return self
        }
        
        return nil
    }
    
    /// Cập nhật khung hình và nghịch đảo tỷ lệ Zoom cho các nút UI phụ thuộc
    func updateSubviewsFrames(isSelected: Bool) {
        let inverseScale = currentCanvasZoomScale > 0 ? (1.0 / currentCanvasZoomScale) : 1.0
        
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
            handle.transform = CGAffineTransform(scaleX: inverseScale, y: inverseScale)
        }
        deleteButton.transform = CGAffineTransform(scaleX: inverseScale, y: inverseScale)
    }
}

// MARK: - SwiftUI Data Synchronization

extension PhotoContainerView {
    
    /// Cập nhật thuộc tính hình học từ SwiftUI Model sang UIKit View
    func update(with photo: PhotoFrame, isSelected: Bool) {
        if self.currentPhotoData == photo && self.isSelected == isSelected {
            return
        }
        
        self.currentPhotoData = photo
        self.isSelected = isSelected
        
        // Bật/tắt cử chỉ theo trạng thái chọn
        panGesture?.isEnabled = isSelected
        pinchGesture?.isEnabled = isSelected
        rotationGesture?.isEnabled = isSelected
        
        // Cập nhật Bounds, Center và Rotation Transform
        bounds = CGRect(x: 0, y: 0, width: photo.frame.width, height: photo.frame.height)
        center = CGPoint(x: photo.frame.x + photo.frame.width/2, y: photo.frame.y + photo.frame.height/2)
        transform = CGAffineTransform(rotationAngle: CGFloat(Angle(degrees: photo.rotation).radians))
        
        imageView.alpha = CGFloat(photo.opacity)
        
        updateSubviewsFrames(isSelected: isSelected)
        
        if isSelected {
            superview?.bringSubviewToFront(self)
        }
    }
    
    /// Cập nhật tỷ lệ thu phóng toàn Canvas
    func updateCanvasZoomScale(_ scale: CGFloat) {
        currentCanvasZoomScale = scale
    }
    
    /// Đóng gói vị trí, kích thước và góc xoay hiện tại để gửi về SwiftUI Binding
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

// MARK: - Gesture Recognizers & Multi-Touch Handlers

extension PhotoContainerView: UIGestureRecognizerDelegate {
    
    func setupGestures() {
        isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        panGesture.isEnabled = false
        addGestureRecognizer(panGesture)
        
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        pinchGesture.isEnabled = false
        addGestureRecognizer(pinchGesture)
        
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        rotationGesture.isEnabled = false
        addGestureRecognizer(rotationGesture)
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        coordinator?.selectPhoto(id: photoId)
    }
    
    /// Xử lý kéo di chuyển View trên Canvas
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        switch gesture.state {
        case .began:
            activeInteractionsCount += 1
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            let translation = gesture.translation(in: superview)
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
        case .ended, .cancelled, .failed:
            activeInteractionsCount = max(0, activeInteractionsCount - 1)
            if !isInteracting {
                saveCurrentState()
            }
        default: break
        }
    }
    
    /// Xử lý thu phóng 2 ngón tay (Pinch-to-zoom) theo Anchor Point
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .began:
            activeInteractionsCount += 1
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
        case .ended, .cancelled, .failed:
            activeInteractionsCount = max(0, activeInteractionsCount - 1)
            if !isInteracting {
                saveCurrentState()
            }
        default: break
        }
    }
    
    /// Xử lý xoay 2 ngón tay (Rotation) theo Anchor Point
    @objc func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .began:
            activeInteractionsCount += 1
            coordinator?.selectPhoto(id: photoId)
        case .changed:
            let anchorInLocal = gesture.location(in: self)
            let offset = CGPoint(x: anchorInLocal.x - bounds.midX, y: anchorInLocal.y - bounds.midY)
            
            let v_super_old = CGPoint(
                x: offset.x * transform.a + offset.y * transform.c,
                y: offset.x * transform.b + offset.y * transform.d
            )
            
            let newTransform = transform.rotated(by: gesture.rotation)
            
            let v_super_new = CGPoint(
                x: offset.x * newTransform.a + offset.y * newTransform.c,
                y: offset.x * newTransform.b + offset.y * newTransform.d
            )
            
            center = CGPoint(
                x: center.x + v_super_old.x - v_super_new.x,
                y: center.y + v_super_old.y - v_super_new.y
            )
            transform = newTransform
            gesture.rotation = 0
        case .ended, .cancelled, .failed:
            activeInteractionsCount = max(0, activeInteractionsCount - 1)
            if !isInteracting {
                saveCurrentState()
            }
        default: break
        }
    }
    
    /// Xử lý kéo nắn kích thước từ 4 góc neo (Corner Handles)
    @objc func handleCornerPan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view, let superview = self.superview else { return }
        
        switch gesture.state {
        case .began:
            activeInteractionsCount += 1
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
            
        case .ended, .cancelled, .failed:
            activeInteractionsCount = max(0, activeInteractionsCount - 1)
            if !isInteracting {
                saveCurrentState()
            }
            
        default: break
        }
    }
    
    /// Bật chế độ nhận diện nhiều cử chỉ đồng thời (Pan + Pinch + Rotate)
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view == self && otherGestureRecognizer.view == self
    }
}
