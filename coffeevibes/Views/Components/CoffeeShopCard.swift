import SwiftUI
import CoreLocation

struct CoffeeShopCard: View {
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var locationManager = LocationManager()
    let shop: CoffeeShop
    let onViewDetails: () -> Void
    let showDragIndicator: Bool
    let showShadow: Bool
    let useNavigationDestination: Bool
    let onFavoriteToggled: (() -> Void)?
    @StateObject private var coffeeShopService = CoffeeShopService()
    @State private var showingDetail = false
    @State private var isFavorite: Bool
    
    init(
        shop: CoffeeShop, 
        onViewDetails: @escaping () -> Void,
        showDragIndicator: Bool = true,
        showShadow: Bool = true,
        useNavigationDestination: Bool = true,
        onFavoriteToggled: (() -> Void)? = nil
    ) {
        self.shop = shop
        self.onViewDetails = onViewDetails
        self.showDragIndicator = showDragIndicator
        self.showShadow = showShadow
        self.useNavigationDestination = useNavigationDestination
        self.onFavoriteToggled = onFavoriteToggled
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
                    
                    VStack(alignment: .leading) {
                        Text(shop.name)
                            .h3Style()
                        Text(shop.todayHours ?? "Hours not available")
                            .h4Style()
                    }
                }
                
                Spacer()
                
                if let distance = shop.distance {
                    Text(String(format: "%.1f mi", distance))
                        .h4MediumStyle()
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
                        .foregroundColor(Color(hex: "1D1612"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(hex: "F7F0E1"))
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(hex: "5D4037"), lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
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

} 