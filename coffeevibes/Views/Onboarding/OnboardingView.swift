import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    var body: some View {
        ZStack {
            Color(hex: "EED3B8")
                .ignoresSafeArea()
            
            mainContent
        }
    }
    
    private var mainContent: some View {
        VStack(spacing: 20) {
            topContent
            bottomContent
        }
    }
    
    private var topContent: some View {
        VStack(spacing: 0) {
            logoView
            Spacer(minLength: .zero)
            pageContentView
        }
    }
    
    private var logoView: some View {
        Image("logo")
            .resizable()
           
            .frame(width: 253, height: 215)
            .padding(.top, 20)
    }
    
    private var pageContentView: some View {
        TabView(selection: $viewModel.currentPage) {
            ForEach(0..<viewModel.onboardingItems.count, id: \.self) { index in
                Image(viewModel.onboardingItems[index].image)
                    .resizable()
                    .scaledToFit()
                    .padding(.horizontal, 40)
                    .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: UIScreen.main.bounds.height * 0.35)
    }
    
    private var bottomContent: some View {
        VStack(spacing: 0) {
            whiteBackground
        }
        .frame(height: 300)
    }
    
    private var whiteBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 33)
                .fill(Color.white)
                .ignoresSafeArea()
            
            contentOverlay
        }
    }
    
    private var contentOverlay: some View {
        VStack(spacing: 0) {
            paginationDotsView
            Spacer()
            textContentView
            Spacer()
            buttonsView
        }
        .padding(.top, 20)
    }
    
    private var paginationDotsView: some View {
        HStack(spacing: 8) {
            ForEach(0..<viewModel.onboardingItems.count, id: \.self) { index in
                Rectangle()
                    .fill(viewModel.currentPage == index ? Color(hex: "5D4037") : Color(hex: "F2E6D9"))
                    .frame(width: 33, height: 8)
                    .cornerRadius(6)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var textContentView: some View {
        Group {
            Text(viewModel.onboardingItems[viewModel.currentPage].title)
                .foregroundColor(.black) +
            Text(" ") +
            Text(viewModel.onboardingItems[viewModel.currentPage].highlightedText)
                .foregroundColor(Color(hex: "5D4037")) +
            Text(" ") +
            Text(viewModel.onboardingItems[viewModel.currentPage].description)
                .foregroundColor(.black)
        }
        .font(CustomFont.nunitoSemiBold.size(24))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }
    
    private var buttonsView: some View {
        VStack(spacing: 12) {
            Button(action: viewModel.handleNavigation) {
                let title = (viewModel.currentPage == viewModel.onboardingItems.count-1) ? "Let’s Explore" : "Get Started"
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color(hex: "5D4037"))
                    .cornerRadius(10)
            }
            .padding(.horizontal, 24)
            
            Button("Skip") {
                viewModel.completeOnboarding()
            }
            .foregroundColor(.black)
            .font(.headline)
            .padding(.bottom, 24)
            .opacity(viewModel.currentPage == viewModel.onboardingItems.count-1 ? 0 : 1)
        }
    }
}

// Helper extension to create Color from hex string
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Add this extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
} 
