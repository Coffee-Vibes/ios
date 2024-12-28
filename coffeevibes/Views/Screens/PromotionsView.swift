//
//  PromotionsView.swift
//  CoffeeVibes
//
//  Created by Andrew Trach on 12/6/24.
//

import SwiftUI

struct PromotionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Navbar
                navBar
                
                // Loyalty Card
                loyaltyCard
                
                // Today's Deals Section
                dealsSectionView
                
                // Rewards Section
                rewardsSectionView
            }
            .padding(.horizontal, 16)
        }
        .background(Color.white)
    }
    
    private var navBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "arrow.left")
                    .foregroundColor(.black)
            }
            
            Text("Promotions & Loyalty")
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
    
    private var loyaltyCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "3C2A21"))
            VStack {
                HStack {
                    Text("Your Loyalty Points")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                }
                .padding(.top)
                .padding(.horizontal)
                
                HStack(spacing: 16) {
                    // Circle Progress with Trophy
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: 0.65)
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                        
                        Image(systemName: "trophy.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.yellow)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("325pts")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("175 more points to unlock a free coffee!")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
    
    private var dealsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Exclusive Deals")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    dealCard(
                        title: "20% off your next order!",
                        highlightedWord: "next",
                        image: "coffee-deal",
                        expiryTime: "03:15:20"
                    )
                    
                    dealCard(
                        title: "Free pastry with any coffee order!",
                        highlightedWord: "pastry",
                        image: "pastry-deal",
                        expiryTime: "05:30:00"
                    )
                }
            }
        }
    }
    
    private func dealCard(title: String, highlightedWord: String, image: String, expiryTime: String) -> some View {
        ZStack {
            // Background Image
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.6), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                
                Spacer()
                
                HStack {
                    Button(action: {}) {
                        Text("Redeem Now")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "D4A574"))
                    }
                    
                    Spacer()
                    
                    Text("Expires in \(expiryTime)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding()
        }
        .frame(width: 280, height: 160)
    }
    
    private var rewardsSectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Redeem Your Rewards")
                .font(.title3)
                .fontWeight(.bold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    rewardCard(
                        title: "Free coffee",
                        points: "500",
                        image: "coffee-reward"
                    )
                    
                    rewardCard(
                        title: "$5 Gift Card",
                        points: "1000",
                        image: "gift-card"
                    )
                }
            }
        }
    }
    
    private func rewardCard(title: String, points: String, image: String) -> some View {
        ZStack {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 280, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.7), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
            
            VStack(alignment: .leading) {
                Spacer()
                
                HStack {
                    Text("\(title) (\(points) points)")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text("\(points) points")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Button(action: {}) {
                    Text("Redeem Now")
                        .font(.subheadline)
                        .foregroundColor(Color(hex: "D4A574"))
                }
            }
            .padding()
        }
        .frame(width: 280, height: 160)
    }
}


#Preview {
    PromotionsView()
}
