import SwiftUI

struct CoffeeShopCard: View {
    @EnvironmentObject private var authService: AuthenticationService
    let shop: CoffeeShop
    let distance: String
    let onViewDetails: () -> Void
    @StateObject private var coffeeShopService = CoffeeShopService()
    @State private var showingDetail = false
    @State private var isFavorite: Bool
    
    init(shop: CoffeeShop, distance: String, onViewDetails: @escaping () -> Void) {
        self.shop = shop
        self.distance = distance
        self.onViewDetails = onViewDetails
        _isFavorite = State(initialValue: shop.isFavorite)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 4)
            
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
                    HStack(spacing: 8) {
                        Text("View Details")
                            .font(.system(size: 14, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(AppColor.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppColor.background)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppColor.primary, lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
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