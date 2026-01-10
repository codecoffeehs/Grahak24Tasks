//
//  CategoryRow.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 10/01/26.
//

import SwiftUI

struct CategoryRow: View {
    let title : String
    let icon : String
    let color : String
    let totalTasks : Int
    
    var categoryColor: CategoryColor {
            CategoryColor(rawValue: color) ?? .blue
        }
    var body: some View {
        HStack(spacing: 14) {
            // Icon bubble
            ZStack {
                Circle()
                    .fill(categoryColor.color)
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(categoryColor.color)
                    .frame(width: 34, height: 34)

                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Title + subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.primary)

                Text("Tap to view tasks")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Task count badge
            Text("\(totalTasks)")
                .font(.system(size: 13, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(.thinMaterial)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(.primary.opacity(0.08))
                )
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())

    }
}

#Preview {
    CategoryRow(title: "Test", icon: "pencil.and.outline", color: "orange", totalTasks: 10)
}
