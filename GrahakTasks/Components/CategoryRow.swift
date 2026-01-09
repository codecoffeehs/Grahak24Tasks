import SwiftUI

struct CategoryRow: View {
    let category: CategoryModel

    var body: some View {
        HStack(spacing: 12) {

            // Icon with colored background
            ZStack {
                Circle()
                    .fill(Color(category.color).opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: category.icon)
                    .foregroundColor(Color(category.color))
            }

            Text(category.title)
                .font(.body)
                .fontWeight(.medium)

            Spacer()
        }
        .padding(.vertical, 6)
    }
}
