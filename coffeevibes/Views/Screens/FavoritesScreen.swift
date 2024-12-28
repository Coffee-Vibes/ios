import SwiftUI
import CoreLocation
import Combine

struct FavoritesScreen: View {
    @StateObject private var coffeeShopService = CoffeeShopService()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var favorites: [CoffeeShop] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
   
    
    var body: some View {
        VStack(spacing: 16) {
            // Categories ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                            .foregroundColor(.brown)
                            .padding()
                            .background(Color(.systemBackground))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.brown, lineWidth: 1)
                            )
                    }
                    
                    CategoryPill(title: "Study Spots", icon: "book.fill", isSelected: true)
                    CategoryPill(title: "Best for Dates", icon: "wifi", isSelected: false)
                    // Add more categories as needed
                }
                .padding(.horizontal)
            }
            
            // Lists Section
            VStack(alignment: .leading) {
                Text("Lists")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                        } else {
                            ForEach(favorites) { shop in
                                ShopCard(shop: shop, locationManager: locationManager)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Favorites")
        .onAppear {
            fetchFavorites()
        }
    }
    
    private func fetchFavorites() {
        let userId = authService.currentUser?.id
        guard let userId = userId else {
            errorMessage = "Please log in to view favorites"
            return
        }
        
        isLoading = true
        Task {
            do {
                print("User ID: \(userId)")
                let fetchedFavorites = try await coffeeShopService.getFavoriteCoffeeShops(by: userId.uuidString)
                favorites = fetchedFavorites
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }

    private func deleteFavorite(at offsets: IndexSet) {
        let userId = authService.currentUser?.id
        guard let userId = userId else {
            errorMessage = "Please log in to manage favorites"
            return
        }
        
        Task {
            for index in offsets {
                let shop = favorites[index]
                await coffeeShopService.deleteFavorite(shopId: shop.id, userId: userId.uuidString)
            }
            // Refresh the favorites list after deletion
            fetchFavorites()
        }
    }
}

struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
            Text(title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.brown : Color.blue.opacity(0.1))
        .foregroundColor(isSelected ? .white : .black)
        .clipShape(Capsule())
    }
}

struct ShopCard: View {
    @EnvironmentObject private var authService: AuthenticationService
    let shop: CoffeeShop
    @ObservedObject var locationManager: LocationManager
    @StateObject private var coffeeShopService = CoffeeShopService()
    @State private var isFavorite = true  // Since this is in favorites view
    
    
    var distance: Double? {
        guard let latitude = shop.latitude,
              let longitude = shop.longitude else { return nil }
        
        let shopLocation = CLLocation(latitude: latitude, longitude: longitude)
        return locationManager.calculateDistance(to: shopLocation)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Shop Image and Info
                Image(shop.coverPhoto)
                    .resizable()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(shop.name)
                        .font(.headline)
                    Text("Updated: 1 min ago")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if let distance = distance {
                    Text("\(distance, specifier: "%.1f") miles away")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            
            // Tags
            HStack {
                CoffeeTagView(text: "Good Vibes", color: .mint)
                CoffeeTagView(text: "Quiet", color: .purple.opacity(0.2))
                CoffeeTagView(text: "Has WIFI", color: .blue.opacity(0.2))
            }
            
            // Heart and View Details
            HStack {
                Button(action: {
                    Task {
                        await toggleFavorite()
                    }
                }) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(.brown)
                }
                
                Spacer()
                
                Button(action: {}) {
                    Text("View Details")
                        .foregroundColor(.brown)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.brown, lineWidth: 1)
                        )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func toggleFavorite() async {
        let userId = authService.currentUser?.id
        guard let userId = userId else {
            print("No user ID available")
            return
        }
        
        if isFavorite {
            await coffeeShopService.deleteFavorite(shopId: shop.id, userId: userId.uuidString)
        } else {
            await coffeeShopService.createFavorite(shopId: shop.id, userId: userId.uuidString)
        }
        isFavorite.toggle()
    }
}
