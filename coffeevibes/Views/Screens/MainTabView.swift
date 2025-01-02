import SwiftUI

struct MainTabView: View {
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                HomeScreen()
                    .tabItem {
                         Image("nav_home")
                            .renderingMode(.template)
                        Text("Home")
                    }
                
                // ExploreScreen()
                //     .tabItem {
                //         Image("nav_explore")
                //             .renderingMode(.template)
                //         Text("Explore")
                //     }
                
                FavoritesScreen()
                    .tabItem {
                        Image("nav_favorites")
                            .renderingMode(.template)
                        Text("Favorites")
                    }
                
                ProfileScreen()
                    .tabItem {
                        Image(systemName: "person.crop.circle.fill")
                        Text("Profile")
                    }
            }
            .accentColor(AppColor.primary)
            .padding(.top, 10)
            .background(Color.white)
            .cornerRadius(20, corners: [.topLeft, .topRight])
        }
//        .edgesIgnoringSafeArea(.bottom)
        .edgesIgnoringSafeArea(.all)
    }
} 
