import SwiftUI

struct CoffeeShopCard: View {
    @EnvironmentObject private var authService: AuthenticationService
    let shop: CoffeeShop
    let distance: String
    let onViewDetails: () -> Void
    let showDragIndicator: Bool
    let showShadow: Bool
    @StateObject private var coffeeShopService = CoffeeShopService()
    @State private var showingDetail = false
    @State private var isFavorite: Bool
    
    init(
        shop: CoffeeShop, 
        distance: String, 
        onViewDetails: @escaping () -> Void,
        showDragIndicator: Bool = true,
        showShadow: Bool = true
    ) {
        self.shop = shop
        self.distance = distance
        self.onViewDetails = onViewDetails
        self.showDragIndicator = showDragIndicator
        self.showShadow = showShadow
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
                        Text("8am - 9pm - See Hours")
                            .h4Style()
                    }
                }
                
                Spacer()
                
                Text(distance)
                    .h4MediumStyle()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Tags
            HStack {
                CoffeeTagView(text: "Good Vibes", color: Color(hex: "E8F5F0"))
                CoffeeTagView(text: "Quiet", color: Color(hex: "FCE8F3"))
                CoffeeTagView(text: "Has WiFi", color: Color(hex: "E8F0FC"))
            }
            .padding()
            
            // Action Buttons
            HStack(spacing: 12) {
                // Favorite Button
                Button(action: {
                    Task {
                        await toggleFavorite()
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : AppColor.foreground)
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
                    showingDetail = true
                    onViewDetails()
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
        .task {
            // Check favorite status when view appears
            await checkFavoriteStatus()
        }
    }
    
    private func checkFavoriteStatus() async {
        let userId = authService.currentUser?.id
        guard let userId = userId else {
            print("No user ID available")
            return
        }
        
        do {
            let favorites = try await coffeeShopService.getFavoriteCoffeeShops(by: userId.uuidString)
            print("Favorites: \(favorites)")
            isFavorite = favorites.contains(where: { $0.id == shop.id })
            print("Is favorite: \(isFavorite)")
        } catch {
            print("Error checking favorite status: \(error)")
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
            } else {
                await coffeeShopService.createFavorite(shopId: shop.id, userId: userId.uuidString)
            }
            isFavorite.toggle()
        } catch {
            print("Error toggling favorite: \(error)")
            // Revert the state if the operation failed
            isFavorite = !isFavorite
        }
    }
} 