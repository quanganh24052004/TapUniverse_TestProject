//
//  ProjectRow.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

// MARK: - Project Row Component

/// Component hiển thị một hàng dự án dạng thẻ (Card View) trong danh sách tổng (Screen 1).
struct ProjectRow: View {
    
    // MARK: - Properties
    
    /// Model dữ liệu dự án cần hiển thị
    let project: Project
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 16) {
            // Tên dự án
            Text(project.name)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(14)
        .background(
            Color(.listgray),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
    }
}
