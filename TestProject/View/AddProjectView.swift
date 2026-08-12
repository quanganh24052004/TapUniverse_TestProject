//
//  AddProject.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

// MARK: - Add Project View (Sheet Modal)

/// Giao diện Popup cho phép người dùng nhập tên và khởi tạo dự án mới.
struct AddProjectView: View {
    
    // MARK: - Environment & Dependencies
    
    /// Thao tác đóng Modal View từ môi trường SwiftUI
    @Environment(\.dismiss) var dismiss
    
    /// Binding hai chiều tới ProjectListViewModel để thực hiện thêm dự án
    @Bindable var viewModel: ProjectListViewModel
    
    // MARK: - Local States
    
    /// Tên dự án do người dùng nhập vào TextField
    @State private var projectName: String = ""
    
    /// Trạng thái ẩn/hiện Alert cảnh báo khi tên dự án bị rỗng
    @State private var showErrorAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin dự án")) {
                    TextField("Nhập tên dự án...", text: $projectName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(true)
                }
            }
            .navigationTitle("Dự án mới")
            .navigationBarTitleDisplayMode(.inline)
            
            // MARK: Navigation Toolbar
            .toolbar {
                // Nút Hủy ở góc trái
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                
                // Nút Lưu ở góc phải
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        saveProjectAction()
                    }
                    .bold()
                }
            }
            
            // MARK: Validation Error Alert
            .alert("Lỗi", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vui lòng nhập tên dự án hợp lệ.")
            }
        }
    }
}

// MARK: - Private Actions & Helpers

private extension AddProjectView {
    
    /// Kiểm tra tính hợp lệ của tên dự án trước khi lưu và đóng màn hình
    func saveProjectAction() {
        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedName.isEmpty {
            viewModel.addProject(name: trimmedName)
            dismiss()
        } else {
            showErrorAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    AddProjectView(viewModel: ProjectListViewModel())
}
