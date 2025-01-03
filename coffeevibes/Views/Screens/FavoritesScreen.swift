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
    @State private var selectedFilter: FavoriteFilter = .all
    
    private enum FavoriteFilter: String, CaseIterable {
        case all = "All"
        case nearby = "Nearby"
        case recent = "Recent"
        case mostVisited = "Most Visited"
        
        var icon: String {
            switch self {
            case .all: return "star.fill"
            case .nearby: return "location.fill"
            case .recent: return "clock.fill"
            case .mostVisited: return "heart.fill"
            }
        }
    }
    
    var filteredFavorites: [CoffeeShop] {
        switch selectedFilter {
        case .all:
            return favorites
        case .nearby:
            return favorites.sorted { shop1, shop2 in
                return (shop1.distance ?? Double.infinity) < (shop2.distance ?? Double.infinity)
            }
        case .recent:
            return favorites.sorted { shop1, shop2 in
                let date1 = shop1.lastVisitedDate ?? Date.distantPast
                let date2 = shop2.lastVisitedDate ?? Date.distantPast
                return date1 > date2
            }
        case .mostVisited:
            return favorites.sorted { shop1, shop2 in
                return (shop1.visitCount ?? 0) > (shop2.visitCount ?? 0)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                // Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(FavoriteFilter.allCases, id: \.self) { filter in
                            FilterPill(
                                title: filter.rawValue,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical, 8)
                
                // Lists Section
                VStack(alignment: .leading) {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if isLoading {
                                ProgressView()
                            } else {
                                ForEach(filteredFavorites) { shop in
                                    CoffeeShopCard(
                                        shop: shop,
                                        onViewDetails: {
                                            selectedShop = shop
                                            showingDetail = true
                                        },
                                        showDragIndicator: false,
                                        showShadow: true,
                                        useNavigationDestination: true,
                                        onFavoriteToggled: {
                                            favorites.removeAll { $0.id == shop.id }
                                        },
                                        inverseViewDetailsColors: false
                                    )
                                    .padding(.horizontal, 16)
                                }
                            }
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Favorites")
                        .titleStyle()
                }
            }
            .background(AppColor.background)
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

struct FilterPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? AppColor.primary : AppColor.secondary)
            .foregroundColor(isSelected ? .white : AppColor.foreground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.clear : AppColor.primary.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

