//
//  OnboardingViewModel.swift
//  CoffeeVibes
//
//  Created by Andrew Trach on 12/5/24.
//

import Foundation
import SwiftUI

class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    
    let onboardingItems = [
        OnboardingItem(
            image: "onboard1",
            title: "Welcome to Coffee Vibes, your guide to the",
            highlightedText: "perfect coffee",
            description: "experience"
        ),
        OnboardingItem(
            image: "onboard2",
            title: "Find coffee spots based on the vibe you're craving:",
            highlightedText: "good vibes, quiet, has WiFi,",
            description: "and more."
        ),
        OnboardingItem(
            image: "onboard3",
            title: "See the real-time vibe of any coffee shop with our",
            highlightedText: "Vibe Check",
            description: "Gauge."
        )
    ]
    
    func handleNavigation() {
         if currentPage == onboardingItems.count - 1 {
             completeOnboarding()
         } else {
             withAnimation {
                 currentPage += 1
             }
         }
     }
     
     func completeOnboarding() {
         hasSeenOnboarding = true
     }
}
