//
//  ProjectListView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

// MARK: - Project List View (Screen 1)

/// Màn hình danh sách dự án chính (Root View) của ứng dụng.
/// Hiển thị danh sách dự án, xử lý tải dữ liệu Offline-First và điều hướng sang màn hình chi tiết.
struct ProjectListView: View {
    
    // MARK: - Properties & States
    
    /// ViewModel quản lý trạng thái danh sách dự án và đồng bộ API/Local
    @State var viewModel = ProjectListViewModel()
    
    /// Trạng thái ẩn/hiện Sheet tạo dự án mới
    @State private var isShowingAddSheet = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Nền trắng phủ toàn màn hình
                Color(.white)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: 1. Main Content Area (Conditional States)
                    mainContentSection
                    
                    // MARK: 2. Bottom Action Button
                    addProjectButton
                }
            }
            .navigationTitle("Projects")
            // Tải dữ liệu bất đồng bộ khi màn hình vừa xuất hiện
            .task {
                await viewModel.loadProjects()
            }
            // Sheet tạo dự án mới
            .sheet(isPresented: $isShowingAddSheet) {
                AddProjectView(viewModel: viewModel)
            }
            // Điều hướng dựa trên Type Routing (Project.self)
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(
                    viewModel: ProjectDetailViewModel(
                        projectId: project.id,
                        projectName: project.name
                    )
                )
            }
        }
    }
}

// MARK: - Subviews & State Components

private extension ProjectListView {
    
    /// Vùng hiển thị nội dung chính dựa trên các trạng thái dữ liệu của ViewModel
    @ViewBuilder
    var mainContentSection: some View {
        if viewModel.isLoading && viewModel.projects.isEmpty {
            // Trạng thái 1: Đang tải dữ liệu từ cache/server
            Spacer()
            ProgressView("Đang tải dự án...")
            Spacer()
            
        } else if let errorMessage = viewModel.errorMessage {
            // Trạng thái 2: Xảy ra lỗi kết nối hoặc API
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.orange)
                
                Text(errorMessage)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("Tải lại") {
                    Task {
                        await viewModel.loadProjects()
                    }
                }
                .buttonStyle(.bordered)
            }
            Spacer()
            
        } else if viewModel.projects.isEmpty {
            // Trạng thái 3: Danh sách rỗng (Chưa có dự án nào)
            Spacer()
            ContentUnavailableView(
                "Không có dự án",
                systemImage: "folder.badge.questionmark",
                description: Text("Nhấn 'Add Project' bên dưới để tạo dự án mới.")
            )
            Spacer()
            
        } else {
            // Trạng thái 4: Hiển thị danh sách dự án
            projectListView
        }
    }
    
    /// Danh sách hiển thị các thẻ dự án
    var projectListView: some View {
        List {
            ForEach(viewModel.projects) { project in
                ZStack {
                    // NavigationLink ẩn để tự do thiết kế UI cho ProjectRow mà không bị dính mũi tên mặc định
                    NavigationLink(value: project) {
                        EmptyView()
                    }
                    .opacity(0)
                    
                    ProjectRow(project: project)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                
                // Thao tác vuốt từ phải sang trái để xóa
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        if let index = viewModel.projects.firstIndex(where: { $0.id == project.id }) {
                            viewModel.removeProject(at: IndexSet(integer: index))
                        }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .listStyle(.plain)
        .background(Color.clear)
        .scrollContentBackground(.hidden)
    }
    
    /// Nút "Add Project" cố định ở góc dưới màn hình
    var addProjectButton: some View {
        Button(action: {
            isShowingAddSheet = true
        }) {
            Text("Add Project")
                .font(.system(.body, design: .rounded))
                .bold()
                .foregroundColor(.bgButton)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.universe)
                .cornerRadius(16)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// MARK: - Preview

#Preview {
    ProjectListView()
}
