import SwiftUI
import Speech

struct HomeScreen: View {
    @StateObject private var coffeeShopService = CoffeeShopService()
    @StateObject private var locationManager = LocationManager()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var searchText = ""
    @State private var selectedFilters: Set<String> = []
    @State private var isShowingMap = true
    @State private var isShowingDetail = false
    @State private var showingFilterSheet = false
    @State private var isCardShowing = false
    @State private var filterDistance: Double = 5.0
    @State private var selectedShop: CoffeeShop?
    
    var filteredShops: [CoffeeShop] {
        let shops = coffeeShopService.coffeeShops
        
        if searchText.isEmpty && selectedFilters.isEmpty {
            return shops
        }
        
        return shops.filter { shop in
            let matchesSearch = searchText.isEmpty || 
                shop.name.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilters.isEmpty || 
                !selectedFilters.isDisjoint(with: shop.tags.map { $0.lowercased() })
            return matchesSearch && matchesFilter
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Map or List Content
                if coffeeShopService.isLoading {
                    ProgressView()
                        .padding()
                    Spacer()
                } else if let error = coffeeShopService.errorMessage {
                    errorView(error)
                } else {
                    ZStack(alignment: .bottomTrailing) {
                        // Content
                        if isShowingMap {
                            MapView(
                                isLoading: coffeeShopService.isLoading,
                                isShowingCard: $isCardShowing
                            )
                             .ignoresSafeArea()
                        } else {
                            VStack(spacing: 0) {
                                // Add spacing for search bar and filters
                                Color.clear
                                    .frame(height: 120) // Adjust this value based on the combined height of search + filters
                                
                                List(filteredShops) { shop in
                                    CoffeeShopCard(
                                        shop: shop,
                                        onViewDetails: {
                                            selectedShop = shop
                                            isShowingDetail = true
                                        },
                                        showDragIndicator: false,
                                        showShadow: true,
                                        useNavigationDestination: true,
                                        onFavoriteToggled: {
                                            Task {
                                                if let userId = authService.currentUser?.id {
                                                    if shop.isFavorite {
                                                        await coffeeShopService.deleteFavorite(
                                                            shopId: shop.id,
                                                            userId: userId.uuidString
                                                        )
                                                    } else {
                                                        await coffeeShopService.createFavorite(
                                                            shopId: shop.id,
                                                            userId: userId.uuidString
                                                        )
                                                    }
                                                    // Refresh the shops list to update favorite status
                                                    if let location = locationManager.currentLocation {
                                                        let shops = try? await coffeeShopService.getCoffeeShopsNearby(
                                                            userId: userId.uuidString,
                                                            latitude: location.coordinate.latitude,
                                                            longitude: location.coordinate.longitude,
                                                            radiusInMiles: filterDistance
                                                        )
                                                        if let shops = shops {
                                                            coffeeShopService.coffeeShops = shops
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    )
                                    .padding(.horizontal, 16)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color(hex: "FAF7F4"))
                                    .padding(.vertical, 8)
                                }
                                .listStyle(PlainListStyle())
                                .scrollContentBackground(.hidden)
                                .background(Color(hex: "FAF7F4"))
                            }
                        }
                        
                        // Group toggle buttons
                        VStack {
                            Spacer()
                            viewToggleButtons
                                .padding(.bottom, isCardShowing ? 192 : 42)
                                .padding(.trailing, 16)
                                .animation(.spring(), value: isCardShowing)
                        }
                    }
                }
                
                // Search Bar Overlay
                if !isShowingDetail {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            SearchBar(text: $searchText)
                            FilterToggleButton {
                                showingFilterSheet = true
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Quick Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                FilterButton(title: "Good Vibes", icon: "filter_goodvibes", isSelected: selectedFilters.contains("good vibes")) {
                                    toggleFilter("Good Vibes")
                                }
                                FilterButton(title: "Has WiFi", icon: "filter_wifi", isSelected: selectedFilters.contains("has wifi")) {
                                    toggleFilter("Has WiFi")
                                }
                                FilterButton(title: "Quiet", icon: "filter_quiet", isSelected: selectedFilters.contains("quiet")) {
                                    toggleFilter("Quiet")
                                }
                                FilterButton(title: "Crowded", icon: "filter_crowded", isSelected: selectedFilters.contains("crowded")) {
                                    toggleFilter("Crowded")
                                }
                                FilterButton(title: "Trendy & Busy", icon: "filter_trending", isSelected: selectedFilters.contains("trendy")) {
                                    toggleFilter("Trendy")
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .background(
                        isShowingMap ? 
                            Color.clear : // Transparent when showing map
                            Color.white.opacity(0.98) // Solid when showing list
                    )
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            CoffeeShopFilterView(
                initialDistance: filterDistance,
                onApplyFilters: { distance in
                    filterDistance = distance
                    if let location = locationManager.currentLocation,
                       let userId = authService.currentUser?.id {
                        Task {
                            do {
                                let shops = try await coffeeShopService.getCoffeeShopsNearby(
                                    userId: userId.uuidString,
                                    latitude: location.coordinate.latitude,
                                    longitude: location.coordinate.longitude,
                                    radiusInMiles: distance
                                )
                                coffeeShopService.coffeeShops = shops
                            } catch {
                                print("Error fetching nearby coffee shops: \(error)")
                            }
                        }
                    }
                }
            )
        }
        .task {
            guard locationManager.currentLocation == nil else { return }
            
            // Wait for location with timeout
            let timeout = Date().addingTimeInterval(10) // 10 second timeout
            while locationManager.currentLocation == nil && Date() < timeout {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            if let userLocation = locationManager.currentLocation {
                if let userId = authService.currentUser?.id {
                    do {
                        let shops = try await coffeeShopService.getCoffeeShopsNearby(
                            userId: userId.uuidString,
                            latitude: userLocation.coordinate.latitude,
                            longitude: userLocation.coordinate.longitude,
                            radiusInMiles: 10
                        )
                        coffeeShopService.coffeeShops = shops
                    } catch {
                        print("Error fetching nearby coffee shops: \(error)")
                    }
                }
            }
        }
        .onChange(of: locationManager.currentLocation) { location in
            if let location = location {
                Task {
                    if let userId = authService.currentUser?.id {
                        do {
                            let shops = try await coffeeShopService.getCoffeeShopsNearby(
                                userId: userId.uuidString,
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude,
                                radiusInMiles: 10
                            )
                            coffeeShopService.coffeeShops = shops
                        } catch {
                            print("Error fetching nearby coffee shops: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    // Helper Views
    private var viewToggleButtons: some View {
        HStack(spacing: 0) {
            Button(action: { isShowingMap = true }) {
                Image(systemName: "map")
                    .foregroundColor(isShowingMap ? .white : .gray)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isShowingMap ? AppColor.primary : .white)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 12,
                                    bottomLeadingRadius: 12,
                                    bottomTrailingRadius: 0,
                                    topTrailingRadius: 0
                                )
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
            
            Button(action: { isShowingMap = false }) {
                Image(systemName: "list.bullet")
                    .foregroundColor(isShowingMap ? .gray : .white)
                    .frame(width: 24, height: 24)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isShowingMap ? .white : AppColor.primary)
                            .clipShape(
                                .rect(
                                    topLeadingRadius: 0,
                                    bottomLeadingRadius: 0,
                                    bottomTrailingRadius: 12,
                                    topTrailingRadius: 12
                                )
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.15),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            }
        }
        .padding(.bottom, 42)
        .padding(.trailing, 16)
    }
    
    private func errorView(_ error: String) -> some View {
        VStack {
            Text("Error loading coffee shops")
                .font(.headline)
                .foregroundColor(.red)
            Text(error)
                .font(.caption)
                .foregroundColor(.gray)
            Button("Retry") {
                Task {
                    if let location = locationManager.currentLocation,
                       let userId = authService.currentUser?.id {
                        do {
                            let shops = try await coffeeShopService.getCoffeeShopsNearby(
                                userId: userId.uuidString,
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude,
                                radiusInMiles: 10
                            )
                            coffeeShopService.coffeeShops = shops
                        } catch {
                            print("Error fetching nearby coffee shops: \(error)")
                        }
                    } else {
                        // Show appropriate error message if location or user ID is not available
                        coffeeShopService.errorMessage = locationManager.currentLocation == nil ? 
                            "Unable to get location" : "Please log in to continue"
                    }
                }
            }
            .padding()
        }
        .padding()
    }
    
    // Toggle filter selection
    private func toggleFilter(_ filter: String) {
        let lowercasedFilter = filter.lowercased()
        if selectedFilters.contains(lowercasedFilter) {
            selectedFilters.remove(lowercasedFilter)
        } else {
            selectedFilters.insert(lowercasedFilter)
        }
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.currentLocation {
            // Your existing location centering logic
        } else {
            locationManager.requestLocation()
        }
    }
    

}

struct SearchBar: View {
    @Binding var text: String
    @StateObject private var speechRecognizer = SpeechRecognitionManager()
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color(hex: "151E24"))
            
            TextField("Search for coffee or vibes...", text: $text)
                .textFieldStyle(.plain)
                .foregroundColor(Color(hex: "6A6A6A"))
            
            Button(action: {
                speechRecognizer.startRecording { transcribedText in
                    text = transcribedText
                }
            }) {
                Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                    .foregroundColor(speechRecognizer.isRecording ? AppColor.primary : Color(hex: "151E24"))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 48)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "D0D5DD"), lineWidth: 1)
        )
        .onAppear {
            speechRecognizer.requestAuthorization()
        }
        .alert("Speech Recognition Error", 
               isPresented: .constant(speechRecognizer.errorMessage != nil)) {
            Button("OK") {
                speechRecognizer.errorMessage = nil
            }
        } message: {
            if let errorMessage = speechRecognizer.errorMessage {
                Text(errorMessage)
            }
        }
    }
}

struct FilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(icon)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(isSelected ? .white : Color(hex: "151E24"))
                
                Text(title)
                    .font(.system(size: 14))
            }
            .padding(.horizontal, 16)
            .frame(height: 36)
            .background(isSelected ? Color(hex: "5D4037") : .white)
            .foregroundColor(isSelected ? .white : Color(hex: "151E24"))
            .cornerRadius(43)
            .overlay(
                RoundedRectangle(cornerRadius: 43)
                    .stroke(Color(hex: "D0D5DD"), lineWidth: 1)
            )
        }
    }
}

struct FilterToggleButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(Color(hex: "151E24"))
                .frame(width: 24, height: 24)
                .padding(.horizontal, 12)
                .frame(height: 48)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "D0D5DD"), lineWidth: 1)
                )
        }
    }
}
