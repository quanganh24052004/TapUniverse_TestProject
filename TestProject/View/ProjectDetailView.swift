//
//  ProjectDetailView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

// MARK: - Project Detail View (Screen 2)

/// Màn hình chỉnh sửa chi tiết Canvas của từng dự án.
/// Quản lý thao tác chèn ảnh, chỉnh độ mờ, xoay/kéo giãn, tự động lưu ngầm và xuất ảnh (Export).
struct ProjectDetailView: View {
    
    // MARK: - Environment & Dependencies
    
    /// Thao tác đóng màn hình hiện tại
    @Environment(\.dismiss) var dismiss
    
    /// ViewModel quản lý dữ liệu chi tiết canvas và đồng bộ
    @State var viewModel: ProjectDetailViewModel
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: 1. Navigation Header Bar
            headerBarView
            
            // MARK: 2. Interactive Canvas Workspace
            canvasAreaView
            
            // MARK: 3. Contextual Controls (Opacity Slider)
            opacityControlSection
            
            // MARK: 4. Bottom Action Button
            addPhotoButton
        }
        .navigationBarBackButtonHidden(true)
        
        // Modal Sheet chọn ảnh từ thư viện
        .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
            CustomPhotoPicker { selectedUrls in
                viewModel.addPhotos(urls: selectedUrls, into: &viewModel.selectedPhotoId)
            }
        }
        
        // Modal Sheet chia sẻ bức ảnh đã export
        .sheet(isPresented: $viewModel.isShowingShareSheet, onDismiss: { viewModel.exportItem = nil }) {
            if let imageToShare = viewModel.exportItem {
                ActivityView(activityItems: [imageToShare])
            }
        }
    }
}

// MARK: - Subviews & Layout Components

private extension ProjectDetailView {
    
    /// Thanh Header trên cùng chứa nút Back, Tiêu đề/Trạng thái lưu và nút Export
    var headerBarView: some View {
        HStack {
            // Nút Back & Lưu ngầm khi thoát
            Button(action: saveAndCloseProject) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                    Text("back")
                }
                .font(.system(.body, design: .rounded))
                .bold()
            }
            
            Spacer()
            
            // Tiêu đề dự án & Trạng thái lưu
            VStack(spacing: 2) {
                Text(viewModel.selectedProjectDetail?.name ?? "Chi tiết dự án")
                    .font(.headline)
                
                if !viewModel.saveStatus.isEmpty {
                    Text(viewModel.saveStatus)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Nút Export Canvas thành ảnh
            Button(action: { viewModel.triggerExportCanvas() }) {
                if viewModel.isExporting {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "square.and.arrow.up")
                        .font(.title3)
                        .bold()
                }
            }
            .disabled(viewModel.selectedProjectDetail?.photos.isEmpty ?? true)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    /// Vùng làm việc chính chứa không gian vẽ Canvas tương tác
    var canvasAreaView: some View {
        GeometryReader { geometry in
            let canvasSize = geometry.size
            
            ZStack {
                Color(UIColor.secondarySystemBackground)
                
                if viewModel.isLoading {
                    ProgressView("Đang tải dữ liệu Canvas...")
                } else if let projectDetail = viewModel.selectedProjectDetail {
                    InteractiveCanvasView(
                        photos: projectDetail.photos,
                        selectedPhotoId: viewModel.selectedPhotoId,
                        onUpdatePhotoFrame: { id, newFrame, newRotation in
                            if var photo = viewModel.selectedProjectDetail?.photos.first(where: { $0.id == id }) {
                                photo.frame = newFrame
                                photo.rotation = newRotation
                                viewModel.updatePhoto(photo)
                            }
                        },
                        onSelectPhoto: { id in
                            viewModel.bringPhotoToFront(id: id)
                        },
                        onDeletePhoto: { id in
                            viewModel.deletePhoto(id: id)
                        },
                        onBackgroundTap: {
                            viewModel.selectedPhotoId = nil
                        }
                    )
                }
            }
            .clipShape(Rectangle())
            // Tải dữ liệu Canvas bất đồng bộ dựa trên ID dự án
            .task(id: viewModel.projectId) {
                if viewModel.selectedProjectDetail?.id != viewModel.projectId {
                    await viewModel.loadProjectDetail()
                }
            }
            .preference(key: CanvasSizePreferenceKey.self, value: canvasSize)
        }
    }
    
    /// Thanh trượt tùy chỉnh Opacity (chỉ xuất hiện khi có 1 bức ảnh được chọn)
    @ViewBuilder
    var opacityControlSection: some View {
        if let selectedId = viewModel.selectedPhotoId,
           let selectedIndex = viewModel.selectedProjectDetail?.photos.firstIndex(where: { $0.id == selectedId }) {
            
            CustomOpacitySlider(opacity: Binding(
                get: { viewModel.selectedProjectDetail?.photos[selectedIndex].opacity ?? 1.0 },
                set: { viewModel.updatePhotoOpacity(id: selectedId, opacity: $0) }
            ))
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.easeInOut, value: viewModel.selectedPhotoId)
        }
    }
    
    /// Nút "Add Photo" cố định ở chân màn hình
    var addPhotoButton: some View {
        Button(action: {
            viewModel.isShowingPhotoPicker = true
        }) {
            Text("Add Photo")
                .font(.system(.body, design: .rounded))
                .bold()
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.universe)
                .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Private Actions & Helpers

private extension ProjectDetailView {
    
    /// Thực thi thoát màn hình ngay lập tức và tiến hành lưu đĩa local + đồng bộ Server ngầm
    func saveAndCloseProject() {
        dismiss()
        
        Task {
            print("Đang chuẩn bị dữ liệu và lưu cục bộ tức thì...")
            viewModel.prepareForExit()
            
            print("Đang đồng bộ dự án hiện tại lên server ngầm...")
            await viewModel.saveProject()
        }
    }
}

// MARK: - Canvas Size PreferenceKey

/// PreferenceKey theo dõi và truyền kích thước khả dụng của Canvas
struct CanvasSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
