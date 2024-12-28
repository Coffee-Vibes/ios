import SwiftUI
import Supabase

struct CoffeeShopDetailView: View {
    let coffeeShop: CoffeeShop
    @StateObject private var coffeeShopService = CoffeeShopService()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isFavorite: Bool
    
    init(coffeeShop: CoffeeShop) {
        self.coffeeShop = coffeeShop
        _isFavorite = State(initialValue: coffeeShop.isFavorite)
    }
    
    @State private var reviews: [Review] = []
    @State private var isLoadingReviews = false
    @State private var reviewsErrorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @State private var showingCard = true
    
    private let supabaseClient = SupabaseConfig.client

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header Image and Back Button
                ZStack(alignment: .top) {
                    AsyncImage(url: URL(string: coffeeShop.coverPhoto)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView() // Show a loading indicator
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image("default_coffee_cover") // Fallback image on error
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        @unknown default:
                            Image("default_coffee_cover") // Fallback for unknown cases
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        }
                    }
                    .frame(height: 240)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.4), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Navigation Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 40)
                    .padding(.horizontal)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 24) {
                    // Shop Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(coffeeShop.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Updated: 1 min ago")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    
                    // Vibe Tags
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(coffeeShop.tags, id: \.self) { tag in
                                CoffeeTagView(
                                    text: tag,
                                    color: tagColor(for: tag)
                                )
                            }
                        }
                    }
                    
                    // Current Vibe Check
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Current Vibe Check")
                            .font(.headline)
                        
                        HStack {
                            VibeIndicator(
                                label: "Quiet",
                                color: .green,
                                progress: 0.8
                            )
                            
                            Spacer()
                            
                            VibeIndicator(
                                label: "Moderate",
                                color: .orange,
                                progress: 0.5
                            )
                            
                            Spacer()
                            
                            VibeIndicator(
                                label: "Crowded",
                                color: .red,
                                progress: 0.2
                            )
                        }
                        .padding(.horizontal)
                    }
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("About \(coffeeShop.name)")
                            .font(.headline)
                        
                        Text("Nestled in the heart of the city, \(coffeeShop.name) offers a serene escape with cozy seating, artisanal coffee, and a welcoming ambiance. Whether you're here to work, relax, or socialize, we've got you covered!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Popular Items
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Popular Items")
                                .font(.headline)
                            Spacer()
                            Button("View Full Menu") {
                                // Handle view menu
                            }
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "B27046"))
                        }
                        
                        // Menu items grid would go here
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .offset(y: -20)
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .task {
            await checkIfFavorite()
            await fetchReviews()
        }
    }
    
    private func tagColor(for tag: String) -> Color {
        switch tag.lowercased() {
        case "good vibes":
            return Color(hex: "E8F5F0")
        case "quiet":
            return Color(hex: "FCE8F3")
        case "relaxed":
            return Color(hex: "E8F0FC")
        default:
            return Color(hex: "E8F0FC")
        }
    }
    
    // Function to check if the coffee shop is a favorite
    private func checkIfFavorite() async {
        do {
            let userId = "219b4fab-3220-4644-bd89-6a183b46f226"
            let response = try await supabaseClient
                .from("favorites")
                .select()
                .eq("user_id", value: userId)
                .eq("shop_id", value: coffeeShop.id)
                .execute()
            
            let decoder = JSONDecoder()
            let favorites = try decoder.decode([FavoriteShop].self, from: response.data)
            isFavorite = favorites.contains { $0.id == coffeeShop.id }
        } catch {
            print("Error checking favorites: \(error)")
        }
    }
    
    // Function to toggle favorite status
    private func toggleFavorite() {
        Task {
            let userId = "219b4fab-3220-4644-bd89-6a183b46f226"

            if isFavorite {
                await coffeeShopService.deleteFavorite(shopId: coffeeShop.id, userId: userId)
            } else {
                await coffeeShopService.createFavorite(shopId: coffeeShop.id, userId: userId)
            }
            isFavorite.toggle()
        }
    }
    
    // Function to fetch reviews
    private func fetchReviews() async {
        isLoadingReviews = true
        do {
            reviews = try await coffeeShopService.getReviews(for: coffeeShop.id)
            reviewsErrorMessage = nil
        } catch {
            reviewsErrorMessage = error.localizedDescription
        }
        isLoadingReviews = false
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

struct ReviewRow: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.gray)
                
                VStack(alignment: .leading) {
                    Text("User ID: \(review.userId.uuidString)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        ForEach(0..<5) { index in
                            Image(systemName: "star.fill")
                                .foregroundColor(index < review.rating ? .yellow : .gray)
                                .font(.caption)
                        }
                        Text("• \(formattedDate(review.createdAt))")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Text(review.reviewText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.hour, .day], from: date, to: now)
        
        if let hours = components.hour, hours < 24 {
            return "\(hours) hours ago"
        } else if let days = components.day {
            return "\(days) days ago"
        } else {
            return "Just now"
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

// New supporting views
struct VibeIndicator: View {
    let label: String
    let color: Color
    let progress: CGFloat
    
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            ZStack {
                // Background arc
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                
                // Foreground arc representing progress
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90)) // Rotate to start from the top
                    .animation(.easeInOut, value: progress) // Animate the progress change
                
                // Center circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 40, height: 40)
            }
            .frame(width: 60, height: 60) // Adjust size as needed
        }
    }
}

#Preview {
    NavigationView {
//         CoffeeShopDetailView(coffeeShop: CoffeeShop.mockCoffeeShops[0])
    }
} 
