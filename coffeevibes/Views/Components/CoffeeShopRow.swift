import SwiftUI
import CoreLocation

struct CoffeeShopRow: View {
    let coffeeShop: CoffeeShop
    @StateObject private var locationManager = LocationManager()
    @State private var showingDetail = false
    
    var distance: Double? {
        guard let latitude = coffeeShop.latitude,
              let longitude = coffeeShop.longitude else { return nil }
        
        let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return locationManager.calculateDistance(to: shopLocation)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with image and basic info
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: coffeeShop.coverPhoto)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(coffeeShop.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.foreground)
                    Text("Updated: 1 min ago")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let distance = distance {
                    Text(String(format: "%.1f miles away", distance))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColor.foreground)
                }
            }
            
            // Tags
            HStack(spacing: 8) {
                ForEach(coffeeShop.tags.prefix(3), id: \.self) { tag in
                    CoffeeTagView(text: tag, color: tagColor(for: tag))
                }
            }
            
            // Action buttons
            HStack {
                Button(action: {}) {
                    Image(systemName: "heart")
                        .foregroundColor(AppColor.foreground)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 44, height: 44)
                .background(AppColor.background)
                .cornerRadius(10)
                
                Spacer()
                
                Button(action: { showingDetail = true }) {
                    Text("View Details")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColor.primary)
                        .frame(width: 267, height: 44)
                        .background(AppColor.background)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppColor.primary, lineWidth: 1)
                        )
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(10)
        //
        .padding(.horizontal, 16)
        .padding(.vertical, 8) // Add padding between rows
        .navigationDestination(isPresented: $showingDetail) {
            CoffeeShopDetailView(coffeeShop: coffeeShop)
        }
    }
    
}

func tagColor(for tag: String) -> Color {
    switch tag.lowercased() {
    case "good vibes":
        return Color(hex: "E8F5F0")
    case "quiet":
        return Color(hex: "FCE8F3")
    case "has wifi":
        return Color(hex: "E8F0FC")
    default:
        return Color(hex: "E8F0FC")
    }
}
