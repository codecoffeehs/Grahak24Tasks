import SwiftUI

struct CategoryRow: View {
    let title: String
    let icon: String
    let colorHex: String
    let totalTasks: Int?

    private var categoryUIColor: Color {
        categoryColors.first(where: { $0.hex == colorHex })?.color ?? .blue
    }

    var body: some View {
        HStack(spacing: 14) {

            // Icon bubble
            ZStack {
                Circle()
                    .fill(categoryUIColor.opacity(0.18))
                    .frame(width: 44, height: 44)

                Circle()
                    .fill(categoryUIColor)
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
            Text("\(totalTasks ?? 0)")
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
    CategoryRow(
        title: "Finance",
        icon: "creditcard.fill",
        colorHex: "#FFCC00",
        totalTasks: 10
    )
    .padding()
}
