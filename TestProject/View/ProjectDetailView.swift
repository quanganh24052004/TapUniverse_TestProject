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
    
    var body: some View {
        VStack(spacing: 0) {
            
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
                
                Button(action: {
                    viewModel.triggerExportCanvas()
                }) {
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
                .task(id: viewModel.projectId) {
                    if viewModel.selectedProjectDetail?.id != viewModel.projectId {
                        await viewModel.loadProjectDetail()
                    }
                }
                .preference(key: CanvasSizePreferenceKey.self, value: canvasSize)
            }
            
            if let selectedId = viewModel.selectedPhotoId,
               let selectedIndex = viewModel.selectedProjectDetail?.photos.firstIndex(where: { $0.id == selectedId }) {
                
                CustomOpacitySlider(opacity: Binding(
                    get: { viewModel.selectedProjectDetail?.photos[selectedIndex].opacity ?? 1.0 },
                    set: { viewModel.updatePhotoOpacity(id: selectedId, opacity: $0) }
                ))
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut, value: viewModel.selectedPhotoId)
            }
            
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
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $viewModel.isShowingPhotoPicker) {
            CustomPhotoPicker { selectedUrls in
                viewModel.addPhotos(urls: selectedUrls, into: &viewModel.selectedPhotoId)
            }
        }
        .sheet(isPresented: $viewModel.isShowingShareSheet, onDismiss: { viewModel.exportItem = nil }) {
            if let imageToShare = viewModel.exportItem {
                ActivityView(activityItems: [imageToShare])
            }
        }
    }
    
    private func saveAndCloseProject() {
        dismiss()
        
        Task {
            print("Đang chuẩn bị dữ liệu và lưu cục bộ tức thì...")
            viewModel.prepareForExit()
            
            print("Đang đồng bộ dự án hiện tại lên server ngầm...")
            await viewModel.saveProject()
        }
    }
}

struct CanvasSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}
