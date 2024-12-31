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
    @State private var selectedShop: CoffeeShop?
    @State private var showingDetail = false
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                // Categories ScrollView
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .foregroundColor(AppColor.primary)
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(AppColor.primary, lineWidth: 1)
                                )
                        }
                        
                        CategoryPill(title: "Good Vibes", icon: "hand.thumbsup.fill", isSelected: true)
                        CategoryPill(title: "Has WiFi", icon: "wifi", isSelected: false)
                        CategoryPill(title: "Quiet", icon: "speaker.slash.fill", isSelected: false)
                    }
                    .padding(.horizontal)
                }
                
                // Lists Section
                VStack(alignment: .leading) {
                    Text("Lists")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1612"))
                        .padding(.horizontal)
                    
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if isLoading {
                                ProgressView()
                            } else {
                                ForEach(favorites) { shop in
                                    CoffeeShopCard(
                                        shop: shop,
                                        onViewDetails: {
                                            selectedShop = shop
                                            showingDetail = true
                                        },
                                        showDragIndicator: false,
                                        showShadow: false,
                                        useNavigationDestination: true,
                                        onFavoriteToggled: {
                                            favorites.removeAll { $0.id == shop.id }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Favorites")
            .background(Color(hex: "FAF7F4"))
            .onAppear {
                locationManager.requestLocation()
            }
            .task {
                await waitForLocationAndFetchFavorites()
            }
            .onChange(of: locationManager.currentLocation) { _ in
                Task {
                    await fetchFavorites()
                }
            }
        }
    }
    
    private func fetchFavorites() {
        let userId = authService.currentUser?.id
        guard let userId = userId else {
            errorMessage = "Please log in to view favorites"
            return
        }
        
        // Get current location
        guard let location = locationManager.currentLocation else {
            errorMessage = "Unable to get location"
            return
        }
        
        isLoading = true
        Task {
            do {
                print("User ID: \(userId)")
                let fetchedFavorites = try await coffeeShopService.getAllFavoriteCoffeeShops(
                    userId: userId.uuidString,
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    radiusInMiles: 50 // Using a larger radius for favorites
                )
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

    private func waitForLocationAndFetchFavorites() async {
        let timeout = Date().addingTimeInterval(5)
        while locationManager.currentLocation == nil && Date() < timeout {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        await fetchFavorites()
    }
}

struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
            Text(title)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? AppColor.primary : Color(hex: "F7F0E1"))
        .foregroundColor(isSelected ? .white : AppColor.foreground)
        .clipShape(Capsule())
    }
}

