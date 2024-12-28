import SwiftUI
import SDWebImageSwiftUI

struct ExploreScreen: View {
    @StateObject private var coffeeShopService = CoffeeShopService()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var searchText = ""
    @State private var selectedTab: String = "Explore"
    @State private var showingDetail = false
    @State private var selectedShop: CoffeeShop?

    private let tabs = ["Explore", "Playlists"]
    
    var filteredShops: [CoffeeShop] {
        let shops = coffeeShopService.coffeeShops
        
        if searchText.isEmpty {
            return shops
        }
        
        return shops.filter { shop in
            let matchesSearch = searchText.isEmpty ||
                shop.name.localizedCaseInsensitiveContains(searchText)
            return matchesSearch
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .center, spacing: 16) {
                Text("Explore the Perfect\nCoffee Spot")
                    .font(.system(size: 18, weight: .semibold))
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color(hex: "1D1612"))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)

                SearchBar(text: $searchText)
                    .padding(.horizontal, 20)
                
                HStack(spacing: 11) {
                    ForEach(tabs, id: \.self) { tab in
                        ZStack {
                            Rectangle()
                                .frame(height: 37)
                                .foregroundColor(Color(hex: "6A6A6A"))
                                .cornerRadius(10)
                                .offset(y: 1)
                            
                            Rectangle()
                                .frame(height: 37)
                                .foregroundColor(Color(hex: "FAF7F4"))
                                .cornerRadius(10)
                            
                            Text(tab)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .regular))
                                .foregroundColor(selectedTab == tab ? Color(hex: "5D4037") : Color(hex: "6A6A6A"))
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                print("Selected tab: \(tab)")
                                selectedTab = tab
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                if selectedTab == "Explore" {
                    // Vibes Section
                    VStack(alignment: .leading) {
                        Text("Trending Coffee Shops")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1D1612"))
                        
                        ScrollView {
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                ForEach(filteredShops, id: \.id) { shop in
                                    TrendingCoffeeShopCard(coffeeShop: shop)
                                        .onTapGesture {
                                            selectedShop = shop
                                            showingDetail = true
                                        }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                } else {
                    // Trending Section
                    VStack(alignment: .leading) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(0...7, id: \.self) { index in
                                    Image("playlist_example")
//                                    TrendingCoffeeShopCard
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                Spacer()
            }
            .navigationDestination(isPresented: $showingDetail) {
                if let selectedShop {
                    CoffeeShopDetailView(coffeeShop: selectedShop)
                }
            }
            .background(Color(hex: "FAF7F4"))
        }
        .task {
            await fetchCoffeeShops()
        }
    }

    private func fetchCoffeeShops() async {
        if let userId = authService.currentUser?.id {
            do {
                let shops = try await coffeeShopService.getCoffeeShopsWithFavoriteStatus(by: userId.uuidString)
                coffeeShopService.coffeeShops = shops
            } catch {
                // Handle error
                print("Error fetching coffee shops: \(error)")
            }
        } else {
            await coffeeShopService.getAllCoffeeShops()
        }
    }
}

struct TrendingCoffeeShopCard: View {
    let coffeeShop: CoffeeShop
    let vibeItemSize = (UIScreen.main.bounds.width - 20 * 2 - 11) / 2
    
    var body: some View {
        VStack(spacing: .zero) {
            ZStack(alignment: .topTrailing) {
                AnimatedImage(url: URL(string: coffeeShop.logoUrl ?? ""))
                    .resizable()
                    .scaledToFill()

//                Image(systemName: "cup.and.saucer.fill")
//                    .font(.system(size: 30))
//                    .foregroundColor(.blue)
//                    .frame(width: vibeItemSize, height: vibeItemSize)
                
                Button(action: {}) {
                    Image(systemName: "heart")
                        .foregroundColor(Color(hex: "1D1612"))
                        .frame(width: 24, height: 24)
                }
                .frame(width: 32, height: 32)
                .background(.white)
                .cornerRadius(10)
                .padding(8)
            }
            .frame(width: vibeItemSize, height: vibeItemSize)
            .background(Color(hex: "F7F0E1"))
            .cornerRadius(10)
            .padding(.bottom, 12)

            HStack(spacing: .zero) {
                Text(coffeeShop.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1612"))
                    .lineLimit(1)
                Spacer(minLength: .zero)
                
                Image("star")
                    .resizable()
                    .frame(width: 16, height: 16)
                
                Text(String(format: "%.1f", coffeeShop.averageRating ?? 0))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1612"))
            }
            .padding(.bottom, 8)
            
            ScrollView {
                HStack(spacing: .zero) {
                    HStack(spacing: 8) {
                        ForEach(coffeeShop.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8)
                                .frame(height: 19)
                                .background(tagColor(for: tag))
                                .cornerRadius(10)
                        }
                    }
                    Spacer(minLength: .zero)
                }
            }
        }
    }
}

enum VibeCategory: String, CaseIterable {
    case study = "Study Spots"
    case date = "Date Night"
    case outdoor = "Outdoor Seating"
    case quiet = "Quiet Places"
    case social = "Social Spots"
    case work = "Work Friendly"
}

struct VibeCategoryCard: View {
    let category: VibeCategory
    
    var body: some View {
        VStack {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 30))
                .foregroundColor(.blue)
            
            Text(category.rawValue)
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
} 

#Preview() {
    ExploreScreen()
}
