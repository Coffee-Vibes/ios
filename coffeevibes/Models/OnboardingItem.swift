import Foundation

struct OnboardingItem: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let highlightedText: String
    let description: String
} 
