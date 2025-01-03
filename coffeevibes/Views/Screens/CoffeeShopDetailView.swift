import SwiftUI
import Supabase
import Foundation

struct CoffeeShopDetailView: View {
    let coffeeShop: CoffeeShop
    @StateObject private var coffeeShopService = CoffeeShopService()
    @EnvironmentObject private var authService: AuthenticationService
    @State private var isFavorite: Bool
    @State private var showingReviewSheet = false
    
    init(coffeeShop: CoffeeShop) {
        self.coffeeShop = coffeeShop
        _isFavorite = State(initialValue: coffeeShop.isFavorite)
    }
    
    @State private var reviews: [CoffeeShopReview] = []
    @State private var isLoadingReviews = false
    @State private var reviewsErrorMessage: String?
    @Environment(\.dismiss) private var dismiss
    @State private var showingCard = true
    @State private var scrollOffset: CGFloat = 0
    private let maxHeaderHeight: CGFloat = 300
    private let minHeaderHeight: CGFloat = 200
    
    private let supabaseClient = SupabaseConfig.client
    @StateObject private var reviewService = CoffeeShopReviewService()

    var body: some View {
        VStack(spacing: 0) {
            // Fixed Header
            GeometryReader { geometry in
                let headerHeight = max(minHeaderHeight, minHeaderHeight + geometry.frame(in: .global).minY)
                
                // Header Image
                ZStack(alignment: .top) {
                    AsyncImage(url: GooglePlacesService.shared.getPhotoURL(reference: coffeeShop.coverPhoto)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(height: headerHeight)
                                .clipped()
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .black.opacity(0.7),
                                            .black.opacity(0.3),
                                            .clear
                                        ]),
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .offset(y: -geometry.frame(in: .global).minY)
                        case .failure:
                            Image("onboard1")
                                .resizable()
                                .scaledToFill()
                                .frame(height: headerHeight)
                                .clipped()
                                .offset(y: -geometry.frame(in: .global).minY)
                        @unknown default:
                            Image("onboard1")
                                .resizable()
                                .scaledToFill()
                                .frame(height: headerHeight)
                                .clipped()
                                .offset(y: -geometry.frame(in: .global).minY)
                        }
                    }
                    
                    // Navigation Bar
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding(.top, 44)
                    .padding(.horizontal)
                }
            }
            .frame(height: minHeaderHeight)
            
            // Scrollable Content with rounded corners
            ZStack {
                // Background that extends to bottom
                Color.white
                    .edgesIgnoringSafeArea(.bottom)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Shop Info
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(coffeeShop.name)
                                    .t1Style()
                                Text(coffeeShop.todayHours ?? "Hours not available")
                                    .t2Style()
                            }
                            
                            Spacer()
                            
                            if let distance = coffeeShop.distance {
                                Text(String(format: "%.1f miles away", distance))
                                    .h4MediumStyle()
                            }
                        }
                        
                        // Action Buttons
                        HStack(spacing: 12) {
                            if let website = coffeeShop.websiteUrl {
                                ActionIconButton(
                                    icon: "globe",
                                    action: {
                                        if let url = URL(string: website) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                )
                            }
                            
                            if let phone = coffeeShop.phone {
                                ActionIconButton(
                                    icon: "phone",
                                    action: {
                                        #if targetEnvironment(simulator)
                                        print("Phone calls not supported in simulator")
                                        #else
                                        let formattedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                                        let phoneUrl = "tel://" + formattedPhone
                                        
                                        if let url = URL(string: phoneUrl),
                                           UIApplication.shared.canOpenURL(url) {
                                            UIApplication.shared.open(url)
                                        }
                                        #endif
                                    }
                                )
                            }
                            
                            ActionIconButton(
                                icon: "location",
                                action: {
                                    if let encodedAddress = coffeeShop.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                       let url = URL(string: "maps://?address=\(encodedAddress)") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            )
                            
                            ActionIconButton(
                                icon: "square.and.arrow.up",
                                action: {
                                    let shopInfo = """
                                    Check out \(coffeeShop.name)!
                                    Address: \(coffeeShop.address)
                                    Hours: \(coffeeShop.todayHours ?? "Hours not available")
                                    """
                                    let activityVC = UIActivityViewController(
                                        activityItems: [shopInfo],
                                        applicationActivities: nil
                                    )
                                    
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window = windowScene.windows.first,
                                       let rootVC = window.rootViewController {
                                        rootVC.present(activityVC, animated: true)
                                    }
                                }
                            )
                        }
                        .padding(.horizontal)
                        
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
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About \(coffeeShop.name)")
                                .font(.headline)
                            
                            Text(coffeeShop.description ?? coffeeShop.summary ?? "Nestled in the heart of the city, \(coffeeShop.name) offers a serene escape with cozy seating, artisanal coffee, and a welcoming ambiance. Whether you're here to work, relax, or socialize, we've got you covered!")
                                .t2Style()
                        }
                        
                        // Contact Info
                        VStack(alignment: .leading, spacing: 6) {
                            if let website = coffeeShop.websiteUrl {
                                Button(action: {
                                    if let url = URL(string: website) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "globe")
                                            .frame(width: 24)
                                        Text(website)
                                            .t2Style()
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                    .padding(.vertical, 4)
                            }
                            
                            if let phone = coffeeShop.phone {
                                Button(action: {
                                    #if targetEnvironment(simulator)
                                    print("Phone calls not supported in simulator")
                                    #else
                                    let formattedPhone = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                                    let phoneUrl = "tel://" + formattedPhone
                                    
                                    if let url = URL(string: phoneUrl),
                                       UIApplication.shared.canOpenURL(url) {
                                        UIApplication.shared.open(url)
                                    }
                                    #endif
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "phone")
                                            .frame(width: 24)
                                        Text(phone)
                                            .t2Style()
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                Divider()
                                    .padding(.vertical, 4)
                            }
                            
                            Button(action: {
                                if let encodedAddress = coffeeShop.address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                                   let url = URL(string: "maps://?address=\(encodedAddress)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "location")
                                        .frame(width: 24)
                                    Text(coffeeShop.address)
                                        .t2Style()
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .foregroundColor(AppColor.foreground)
                        
                        // Reviews Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Reviews")
                                    .font(.headline)
                                
                                Button(action: {
                                    showingReviewSheet = true
                                }) {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(AppColor.primary)
                                        .font(.system(size: 20))
                                }
                                
                                Spacer()
                                
                                Button("See All") {
                                    // Handle view menu
                                }
                                .font(.subheadline)
                                .foregroundColor(Color(hex: "B27046"))
                            }
                            .sheet(isPresented: $showingReviewSheet) {
                                AddReviewSheet(
                                    coffeeShop: coffeeShop,
                                    isPresented: $showingReviewSheet,
                                    onReviewAdded: {
                                        Task {
                                            await fetchReviews()
                                        }
                                    }
                                )
                            }
                            
                            // Add Rating Cups
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    let fillLevel = (coffeeShop.averageRating ?? 0) - Double(index)
                                    Image(systemName: fillLevel >= 1.0 ? "cup.and.saucer.fill" :
                                          fillLevel >= 0.5 ? "cup.and.saucer" :
                                          "cup.and.saucer")
                                        .foregroundColor(fillLevel >= 0.5 ? AppColor.primary : Color.gray.opacity(0.3))
                                        .font(.system(size: 18))
                                }
                                
                                if let rating = coffeeShop.averageRating {
                                    Text(String(format: "%.1f", rating))
                                        .foregroundColor(AppColor.foreground)
                                        .font(.system(size: 16, weight: .medium))
                                        .padding(.leading, 8)
                                }
                            }
                            .padding(.top, 4)
                            
                            // Reviews List
                            if isLoadingReviews {
                                ProgressView()
                            } else if let error = reviewsErrorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(reviews.prefix(5)) { review in
                                        ReviewRow(review: review)
                                        
                                        if review.id != reviews.prefix(5).last?.id {
                                            Divider()
                                                .foregroundColor(Color.gray.opacity(0.2))
                                        }
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Add bottom padding
                        Color.clear.frame(height: 40)
                    }
                    .padding()
                }
            }
            .background(Color.white)
            .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
            .offset(y: -20)
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
        .task {
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
 
    
    // Function to fetch reviews
    private func fetchReviews() async {
        isLoadingReviews = true
        do {
            reviews = try await reviewService.getReviews(for: coffeeShop.id)
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
    let review: CoffeeShopReview
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Profile and Rating
            HStack(spacing: 12) {
                // Profile Image
                if let profileImage = review.user?.profilePhoto,
                   let url = URL(string: profileImage) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        default:
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .foregroundColor(Color.gray.opacity(0.8))
                        }
                    }
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                        .foregroundColor(Color.gray.opacity(0.8))
                }
                
                // Name and Rating
                VStack(alignment: .leading, spacing: 4) {
                    Text(review.user?.name ?? "Anonymous")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1612"))
                    
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: "cup.and.saucer.fill")
                                .foregroundColor(index < review.rating ? AppColor.primary : Color.gray.opacity(0.3))
                                .font(.system(size: 12))
                        }
                    }
                }
                
                Spacer()
                
                // Time
                Text(formattedDate(review.createdAt))
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray)
            }
            
            // Review Text
            VStack(alignment: .leading, spacing: 4) {
                Text(review.reviewText)
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "6A6A6A"))
                    .lineLimit(isExpanded ? nil : 2)
                
                if review.reviewText.count > 100 {
                    Button(action: {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }) {
                        Text(isExpanded ? "Show Less" : "Read More...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "B27046"))
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let minutes = components.minute, minutes < 60 {
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if let hours = components.hour, hours < 24 {
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else if let days = components.day {
            return "\(days) day\(days == 1 ? "" : "s") ago"
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

struct ActionIconButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .padding(12)
                .background(AppColor.primary)
                .cornerRadius(8)
        }
    }
}

// #Preview {
//     NavigationView {
// //         CoffeeShopDetailView(coffeeShop: CoffeeShop.mockCoffeeShops[0])
//     }
// } 
