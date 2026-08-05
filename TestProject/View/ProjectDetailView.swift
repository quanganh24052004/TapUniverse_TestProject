//
//  ProjectDetailView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

struct ProjectDetailView: View {
    @StateObject var viewModel: ProjectDetailViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedPhotoId: UUID? = nil
    // Đã thay thế canvasScale bằng UIScrollView trong InteractiveCanvasView
    @State private var isShowingPhotoPicker = false
    
    // Trạng thái quản lý chia sẻ ảnh
    @State private var isExporting = false
    @State private var exportItem: UIImage? = nil
    @State private var isShowingShareSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Toolbar Điều hướng & Xuất bản nâng cấp
            HStack {
                Button(action: {
                    saveAndCloseProject()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("back")
                    }
                    .font(.system(.body, design: .rounded))
                    .bold()
                }
                
                Spacer()
                
                Text(viewModel.selectedProjectDetail?.name ?? "Chi tiết dự án")
                    .font(.headline)
                
                Spacer()
                
                // NÚT XUẤT BẢN CANVASES (SCREEN 3)
                Button(action: {
                    exportCanvas()
                }) {
                    if isExporting {
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
            
            // Vùng vẽ Canvas (UIKit Bridge - Giai đoạn 3)
            GeometryReader { geometry in
                let canvasSize = geometry.size
                
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                    
                    if viewModel.isLoading {
                        ProgressView("Đang tải dữ liệu Canvas...")
                    } else if let photosBinding = Binding($viewModel.selectedProjectDetail)?.photos {
                        InteractiveCanvasView(
                            photos: photosBinding,
                            selectedPhotoId: $selectedPhotoId
                        )
                    }
                }
                .clipShape(Rectangle())
                .task(id: viewModel.projectId) {
                    if viewModel.selectedProjectDetail?.id != viewModel.projectId {
                        await viewModel.loadProjectDetail()
                    }
                }
                // Lưu kích thước thật của Canvas để phục vụ lúc kết xuất đồ họa
                .preference(key: CanvasSizePreferenceKey.self, value: canvasSize)
            }
            
            // Custom Slider tinh chỉnh Opacity (Chỉ hiển thị khi có ảnh được chọn)
            if let selectedId = selectedPhotoId,
               let selectedIndex = viewModel.selectedProjectDetail?.photos.firstIndex(where: { $0.id == selectedId }) {
                
                CustomOpacitySlider(opacity: Binding(
                    get: { viewModel.selectedProjectDetail?.photos[selectedIndex].opacity ?? 1.0 },
                    set: { viewModel.selectedProjectDetail?.photos[selectedIndex].opacity = $0 }
                ))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: selectedPhotoId)
            }
            
            // Nút "Add Photo" mở Photo Picker
            Button(action: {
                isShowingPhotoPicker = true
            }) {
                Text("Add Photo")
                    .font(.system(.body, design: .rounded))
                    .bold()
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.universe)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
            }
        }
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $isShowingPhotoPicker) {
            CustomPhotoPicker { selectedUrls in
                viewModel.addPhotos(urls: selectedUrls, into: &$selectedPhotoId.wrappedValue)
            }
        }
        // HIỂN THỊ TRÌNH CHIA SẺ HỆ THỐNG KHI ĐÃ RENDER XONG JPEG
        .sheet(isPresented: $isShowingShareSheet, onDismiss: { exportItem = nil }) {
            if let imageToShare = exportItem {
                ActivityView(activityItems: [imageToShare])
            }
        }
    }
    
    // GỌI KẾT XUẤT ĐỒ HỌA SANG JPEG & CHIA SẺ
    private func exportCanvas() {
        isExporting = true
        viewModel.exportCanvas { image in
            self.exportItem = image
            self.isExporting = false
            if image != nil {
                self.isShowingShareSheet = true
            }
        }
    }
    
    private func saveAndCloseProject() {
        Task {
            print("Đang lưu dự án hiện tại...")
            await viewModel.saveProject()
            dismiss()
        }
    }
}

// Trợ giúp lưu trữ thông tin kích thước Canvas hiển thị
struct CanvasSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
