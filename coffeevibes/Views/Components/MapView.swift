import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var coffeeShopService = CoffeeShopService()
    @EnvironmentObject private var authService: AuthenticationService
    let isLoading: Bool
    @Binding var isShowingCard: Bool
    @StateObject private var locationManager = LocationManager()
    @State private var region: MKCoordinateRegion?
    @State private var selectedShop: CoffeeShop?
    @State private var showingCard = false
    @GestureState private var dragOffset: CGFloat = 0
    @State private var userTrackingMode: MapUserTrackingMode = .none
    @State private var currentShopIndex: Int = 0
    
    // Add a constant for the default zoom level
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isLoading && coffeeShopService.coffeeShops.isEmpty {
                LoadingView()
            } else if let region = region {
                Map(coordinateRegion: .constant(region),
                    showsUserLocation: false,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: createAnnotations()) { item in
                    MapAnnotation(coordinate: item.coordinate, anchorPoint: CGPoint(x: 0.5, y: 1.0)) {
                        switch item.type {
                        case .coffeeShop(let shop):
                            CoffeeShopMarker(
                                shop: shop,
                                onSelect: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        // Deselect first if tapping a different marker
                                        if selectedShop?.id != shop.id {
                                            selectedShop = nil
                                            showingCard = false
                                        }
                                        
                                        // Small delay to ensure clean state transition
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedShop = shop
                                                if let index = coffeeShopService.coffeeShops.firstIndex(where: { $0.id == shop.id }) {
                                                    currentShopIndex = index
                                                }
                                                showingCard = true
                                                centerOnLocation(
                                                    latitude: shop.latitude ?? 0,
                                                    longitude: shop.longitude ?? 0
                                                )
                                            }
                                        }
                                    }
                                },
                                isSelected: selectedShop?.id == shop.id
                            )
                            .zIndex(selectedShop?.id == shop.id ? 1 : 0)
                        case .userLocation:
                            UserLocationMarker()
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
                .colorScheme(.light)
                .onTapGesture {
                    withAnimation(.spring()) {
                        showingCard = false
                        selectedShop = nil
                    }
                }
            } else {
                LoadingView()
            }
            
            if !coffeeShopService.coffeeShops.isEmpty && showingCard {
                SwipeableCoffeeShopCard(
                    shops: coffeeShopService.coffeeShops,
                    currentIndex: currentShopIndex,
                    onSwipe: { newIndex in
                        currentShopIndex = newIndex
                        if let shop = coffeeShopService.coffeeShops[safe: newIndex] {
                            selectedShop = shop
                            centerOnLocation(
                                latitude: shop.latitude ?? 0,
                                longitude: shop.longitude ?? 0
                            )
                        }
                    },
                    onViewDetails: {
                        showingCard = false
                    }
                )
                .transition(.move(edge: .bottom))
                .offset(y: dragOffset - 60)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            if value.translation.height > 0 {
                                state = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation(.spring()) {
                                    showingCard = false
                                    selectedShop = nil
                                }
                            }
                        }
                )
                .onAppear {
                    isShowingCard = true
                }
                .onDisappear {
                    isShowingCard = false
                }
            }
            
            LocationButton(action: centerOnUserLocation)
                .padding(.bottom, isShowingCard ? 382 : 232)
                .padding(.trailing, 30)
                .animation(.spring(), value: isShowingCard)
        }
        .onAppear {
            locationManager.requestLocation()
        }
        .onChange(of: locationManager.currentLocation) { location in
            if let location = location {
                withAnimation(.easeInOut(duration: 0.5)) {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: defaultSpan
                    )
                }
                
                // Fetch coffee shops when location updates
                Task {
                    if let userId = authService.currentUser?.id {
                        do {
                            let shops = try await coffeeShopService.getCoffeeShopsNearby(
                                userId: userId.uuidString,
                                latitude: location.coordinate.latitude,
                                longitude: location.coordinate.longitude,
                                radiusInMiles: 10
                            )
                            print("Fetched \(shops.count) shops")
                            await MainActor.run {
                                coffeeShopService.coffeeShops = shops
                            }
                        } catch {
                            print("Error fetching nearby coffee shops: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    private var locationInfoLayer: some View {
        LocationInfoView(location: locationManager.currentLocation)
    }
    
    // MARK: - Helper Methods
    
    private func createAnnotations() -> [MapItem] {
        var items = coffeeShopService.coffeeShops.map { shop in
            MapItem(type: .coffeeShop(shop))
        }
        if let userLocation = locationManager.currentLocation {
            items.append(MapItem(type: .userLocation(userLocation.coordinate)))
        }
        return items
    }
    
    private func centerOnUserLocation() {
        if let userLocation = locationManager.currentLocation {
            withAnimation(.easeInOut(duration: 0.8)) {
                region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    span: defaultSpan
                )
                userTrackingMode = .follow
            }
        } else {
            locationManager.requestLocation()
        }
    }
    
    private func centerOnLocation(latitude: Double, longitude: Double) {
        withAnimation(.easeInOut(duration: 0.5)) { // Add animation here too for consistency
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                span: defaultSpan // Use the default span
            )
        }
    }
}

// MARK: - Supporting Types

private struct MapItem: Identifiable {
    let id = UUID()
    let type: AnnotationType
    
    var coordinate: CLLocationCoordinate2D {
        switch type {
        case .coffeeShop(let shop):
            return CLLocationCoordinate2D(
                latitude: shop.latitude ?? 0,
                longitude: shop.longitude ?? 0
            )
        case .userLocation(let coordinate):
            return coordinate
        }
    }
}

private enum AnnotationType {
    case coffeeShop(CoffeeShop)
    case userLocation(CLLocationCoordinate2D)
}

// MARK: - Supporting Views

private struct CoffeeShopMarker: View {
    let shop: CoffeeShop
    let onSelect: () -> Void
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Marker Image
            Image(isSelected ? "coffee_marker_selected" : "coffee_marker")
                .resizable()
                .frame(width: 100, height: 100)
                .scaledToFit()
                .offset(y: 30)
            
            // Shop name label
            Text(shop.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColor.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.3))
                        .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 1)
                )
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .offset(y: -10)
        }
        .offset(y: -70)
        .contentShape(Rectangle()) // Make entire area tappable
        .background(
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .frame(width: 120, height: 160) // Larger hit target
        )
        .onTapGesture {
            onSelect()
        }
    }
}

// Update the MarkerButtonStyle to handle the new layout
private struct MarkerButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .contentShape(
                Rectangle()
                    .size(width: 100, height: 130) // Increased height to account for label
            )
    }
}

private struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            // Outer semi-transparent circle
            Circle()
                .fill(AppColor.primary.opacity(0.2))
                .frame(width: 20, height: 20)
            
            // Center brown circle
            Circle()
                .fill(AppColor.primary)
                .frame(width: 16, height: 16)
        }
    }
}

// MARK: - Supporting Views

private struct LocationInfoView: View {
    let location: CLLocation?
    
    var body: some View {
        if let userLocation = location {
            VStack {
                Text("User Location:")
                    .font(.headline)
                    .foregroundColor(.black)
                Text("Lat: \(userLocation.coordinate.latitude), Lon: \(userLocation.coordinate.longitude)")
                    .foregroundColor(.black)
            }
            .padding()
            .background(Color.white.opacity(0.8))
            .cornerRadius(8)
            .padding()
        }
    }
}

private struct SelectedCoffeeShopView: View {
    let shop: CoffeeShop
    let onNavigateToDetail: () -> Void
    @State private var showingDetail = false
    
    var body: some View {
        VStack {
            CoffeeShopCard(
                shop: shop,
                onViewDetails: onNavigateToDetail,
                inverseViewDetailsColors: true
            )
            .padding(.horizontal)
            .padding(.bottom, 115)
        }
        .onChange(of: showingDetail) { newValue in
            if newValue {
                onNavigateToDetail()
            }
        }
    }
}

private struct LocationButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image("gps")
                .resizable()
                .frame(width: 24, height: 24)
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(
                    color: Color.black.opacity(0.15),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        }
    }
}

extension MKMapView {
    func setMapStyle() {
        let mapConfiguration = MKStandardMapConfiguration()
        mapConfiguration.pointOfInterestFilter = .excludingAll
        mapConfiguration.emphasisStyle = .muted
        self.preferredConfiguration = mapConfiguration
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color(hex: "5D4037"))
            Text("Loading nearby coffee shops...")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(hex: "FAF7F4"))
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 
