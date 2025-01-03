import SwiftUI
import CoreLocation

struct CoffeeShopCard: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var locationManager = LocationManager()
    let shop: CoffeeShop
    let onViewDetails: () -> Void
    let showDragIndicator: Bool
    let showShadow: Bool
    let showLastVisited: Bool
    let useNavigationDestination: Bool
    let onFavoriteToggled: (() -> Void)?
    let inverseViewDetailsColors: Bool
    @StateObject private var coffeeShopService = CoffeeShopService()
    @State private var showingDetail = false
    @State private var isFavorite: Bool
    
    init(
        shop: CoffeeShop, 
        onViewDetails: @escaping () -> Void,
        showDragIndicator: Bool = true,
        showShadow: Bool = true,
        showLastVisited: Bool = true,
        useNavigationDestination: Bool = true,
        onFavoriteToggled: (() -> Void)? = nil,
        inverseViewDetailsColors: Bool = false
    ) {
        self.shop = shop
        self.onViewDetails = onViewDetails
        self.showDragIndicator = showDragIndicator
        self.showShadow = showShadow
        self.showLastVisited = showLastVisited
        self.useNavigationDestination = useNavigationDestination
        self.onFavoriteToggled = onFavoriteToggled
        self.inverseViewDetailsColors = inverseViewDetailsColors
        _isFavorite = State(initialValue: shop.isFavorite)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Only show drag indicator if showDragIndicator is true
            if showDragIndicator {
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color.gray.opacity(0.5))
                    .frame(width: 36, height: 5)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
            }
            
            HStack(alignment: .center) {
                // Shop Image and Info
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppColor.primary)
                            .frame(width: 40, height: 40)
                        
                        if let logoUrl = shop.logoUrl {
                            AsyncImage(url: URL(string: logoUrl)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                case .failure:
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                @unknown default:
                                    Image(systemName: "cup.and.saucer.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(.white)
                                }
                            }
                        } else {
                            Image(systemName: "cup.and.saucer.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(shop.name)
                            .h3Style()
                        Text(shop.todayHours ?? "Hours not available")
                            .h4Style()
                        if showLastVisited, let lastVisited = lastVisitedText {
                            Text(lastVisited)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Distance info
                if let distance = shop.distance {
                    Text(String(format: "%.1f miles away", distance))
                        .h4Style()
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Tags
            shopTags
            
            // Action Buttons
            HStack(spacing: 12) {
                // Favorite Button
                Button(action: {
                    Task {
                        await toggleFavorite()
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? AppColor.primary : AppColor.foreground)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 44, height: 44)
                .background(AppColor.background)
                .cornerRadius(8)
                
                // Get Directions Button
                Button(action: {
                    if let lat = shop.latitude, let lon = shop.longitude {
                        let url = URL(string: "maps://?daddr=\(lat),\(lon)")
                        if let url = url, UIApplication.shared.canOpenURL(url) {
                            UIApplication.shared.open(url)
                        }
                    }
                }) {
                    Image(systemName: "location.fill")
                        .foregroundColor(AppColor.foreground)
                        .frame(width: 24, height: 24)
                }
                .frame(width: 44, height: 44)
                .background(AppColor.background)
                .cornerRadius(8)
                
                Spacer()
                
                // View Details Button
                Button(action: {
                    if useNavigationDestination {
                        showingDetail = true
                    } else {
                        onViewDetails()
                    }
                }) {
                    Text("View Details")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(inverseViewDetailsColors ? Color(hex: "FFFFFF") : AppColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(inverseViewDetailsColors ? AppColor.primary : AppColor.secondary)
                        .cornerRadius(10)
                        .overlay(
                            !inverseViewDetailsColors ?
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppColor.primary, lineWidth: 1)
                                : nil
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(hex: "FFFFFF"))
        .cornerRadius(12)
        .shadow(radius: showShadow ? 5 : 0)
        .navigationDestination(isPresented: $showingDetail) {
            CoffeeShopDetailView(coffeeShop: shop)
        }
    }
    
    
    // Update favorite button action to handle optional userId
    private func toggleFavorite() async {
        let userId = authService.currentUser?.id
        guard let userId = userId else {
            print("No user ID available")
            return
        }
        
        do {
            if isFavorite {
                await coffeeShopService.deleteFavorite(shopId: shop.id, userId: userId.uuidString)
                onFavoriteToggled?()
            } else {
                await coffeeShopService.createFavorite(shopId: shop.id, userId: userId.uuidString)
            }
            isFavorite.toggle()
        } catch {
            print("Error toggling favorite: \(error)")
            isFavorite = !isFavorite
        }
    }
    

    
    private var shopTags: some View {
        HStack {
            if !shop.tags.isEmpty {
                ForEach(shop.tags.prefix(3), id: \.self) { tag in
                    CoffeeTagView(text: tag, color: tagColor(for: tag))
                }
            } else {
                // Fallback tags if none provided
                CoffeeTagView(text: "Coffee Shop", color: Color(hex: "E8F5F0"))
            }
        }
        .padding()
    }
    
    private func tagColor(for tag: String) -> Color {
        switch tag.lowercased() {
        case "good vibes":
            return Color(hex: "E8F5F0")
        case "quiet":
            return Color(hex: "FCE8F3")
        case "wifi", "has wifi":
            return Color(hex: "E8F0FC")
        default:
            return Color(hex: "E8F0FC")
        }
    }
    
    private var lastVisitedText: String? {
        guard let date = shop.lastVisitedDate else { return nil }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last visited \(formatter.localizedString(for: date, relativeTo: Date()))"
    }

} 
