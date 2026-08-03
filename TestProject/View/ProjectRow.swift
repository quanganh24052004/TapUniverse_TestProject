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
        HStack {
            Text(project.name)
                .font(.system(.body, design: .rounded))
                .fontWeight(.medium)
                .padding(.leading, 8)
    
            Spacer()

        }
        .padding(.vertical, 8)
    }
}
