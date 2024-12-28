//
//  CoffeeVibesApp.swift
//  CoffeeVibes
//
//  Created by Brian Foster on 11/18/24.
//

import SwiftUI

@main
struct CoffeeVibesApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @ObservedObject private var authService = AuthenticationService()
    
    init() {
        FontManager.registerFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !hasSeenOnboarding && !authService.isUserLoggedIn {
                    OnboardingView()
                } else if !authService.isUserLoggedIn {
                    AuthCoordinator(viewModel: AuthCoordinatorViewModel())
                        .transition(
                            .asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .trailing)
                            )
                        )
                } else {
                    MainTabView()
                }
            }
            .environmentObject(authService)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: hasSeenOnboarding)
        }
    }
}
