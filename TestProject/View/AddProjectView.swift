//
//  AddProject.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

struct AddProjectView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProjectListViewModel
    @State private var projectName: String = ""
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Thông tin dự án")) {
                    TextField("Nhập tên dự án...", text: $projectName)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
            }
            .navigationTitle("Dự án mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        let trimmedName = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmedName.isEmpty {
                            viewModel.addProject(name: trimmedName)
                            dismiss()
                        } else {
                            showErrorAlert = true
                        }
                    }
                    .bold()
                }
            }
            .alert("Lỗi", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vui lòng nhập tên dự án hợp lệ.")
            }
        }
    }
}
