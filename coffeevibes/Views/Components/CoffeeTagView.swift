import SwiftUI

struct CoffeeTagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppColor.secondary)
            .foregroundColor(AppColor.primary)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppColor.primary, lineWidth: 1)
            )
    }
} 