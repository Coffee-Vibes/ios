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
    @State private var showingCard = true
    @GestureState private var dragOffset: CGFloat = 0
    @State private var userTrackingMode: MapUserTrackingMode = .none
    
    // Add a constant for the default zoom level
    private let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if isLoading && coffeeShopService.coffeeShops.isEmpty {
                LoadingView()
            } else if let region = region {
                Map(coordinateRegion: .constant(region),
                    showsUserLocation: true,
                    userTrackingMode: $userTrackingMode,
                    annotationItems: createAnnotations()) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        switch item.type {
                        case .coffeeShop(let shop):
                            CoffeeShopMarker(
                                shop: shop,
                                onSelect: {
                                    selectedShop = shop
                                    showingCard = true
                                    centerOnLocation(
                                        latitude: shop.latitude ?? 0,
                                        longitude: shop.longitude ?? 0
                                    )
                                },
                                isSelected: selectedShop?.id == shop.id
                            )
                        case .userLocation:
                            UserLocationMarker()
                        }
                    }
                }
                .mapStyle(.standard(elevation: .flat, emphasis: .muted, pointsOfInterest: .excludingAll, showsTraffic: false))
                .colorScheme(.light)
            } else {
                LoadingView()
            }
            
            if let selected = selectedShop, showingCard {
                SelectedCoffeeShopView(
                    shop: selected,
                    onNavigateToDetail: {
                        showingCard = false
                    }
                )
                .transition(.move(edge: .bottom))
                .offset(y: dragOffset)
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
        Button(action: onSelect) {
            Image(isSelected ? "coffee_marker_selected" : "coffee_marker")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(8)
                .background(Color(hex: "FCF3ED"))
                .clipShape(Circle())
        }
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
                distance: "0.5 miles away",
                onViewDetails: onNavigateToDetail
            )
            .padding(.horizontal)
            .padding(.bottom, 115)
        }
       // .background(Color(hex: "FAF7F4"))
       // .cornerRadius(16, corners: [.topLeft, .topRight])
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
