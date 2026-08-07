//
//  ProjectRow.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI

struct ProjectRow: View {
    let project: Project
    
    var body: some View {
        HStack(spacing: 16) {
            Text(project.name)
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.primary)
            Spacer()
        }
        .padding(14)
        .background(Color(.listgray))
        .cornerRadius(14)
    }
}
