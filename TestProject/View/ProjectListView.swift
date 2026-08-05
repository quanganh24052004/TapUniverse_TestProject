//
//  ProjectListView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

struct ProjectListView: View {
    @StateObject var viewModel = ProjectListViewModel()
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                if viewModel.isLoading && viewModel.projects.isEmpty {
                    Spacer()
                    ProgressView("Đang tải dự án...")
                    Spacer()
                } else if let errorMessage = viewModel.errorMessage {
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
                    Spacer()
                    ContentUnavailableView(
                        "Không có dự án",
                        systemImage: "folder.badge.questionmark",
                        description: Text("Nhấn 'Add Project' bên dưới để tạo dự án mới.")
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(viewModel.projects) { project in
                            NavigationLink(destination: ProjectDetailView(viewModel: ProjectDetailViewModel(projectId: project.id, projectName: project.name))) {
                                ProjectRow(project: project)
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.removeProject(at: indexSet)
                        }
                    }
                    .listStyle(.automatic)
                }
                
                Button(action: {
                    isShowingAddSheet = true
                }) {
                    Text("Add Project")
                        .font(.system(.body, design: .rounded))
                        .bold()
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.universe)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("Projects")
            .task {
                await viewModel.loadProjects()
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddProjectView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    ProjectListView()
}
