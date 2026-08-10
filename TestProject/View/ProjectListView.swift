//
//  ProjectListView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

struct ProjectListView: View {
    @State var viewModel = ProjectListViewModel()
    @State private var isShowingAddSheet = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.white)
                    .ignoresSafeArea()
                
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
                            ZStack {
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
                    .background(Color(.clear))
                    .scrollContentBackground(.hidden)
                }
                
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
            .navigationTitle("Projects")
            .task {
                await viewModel.loadProjects()
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddProjectView(viewModel: viewModel)
            }
            .navigationDestination(for: Project.self) { project in
                ProjectDetailView(viewModel: ProjectDetailViewModel(projectId: project.id, projectName: project.name))
            }
            }
        }
    }
}

#Preview {
    ProjectListView()
}
