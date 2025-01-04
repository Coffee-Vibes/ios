import SwiftUI

struct SwipeableCoffeeShopCard: View {
    let shops: [CoffeeShop]
    let currentIndex: Int
    let onSwipe: (Int) -> Void
    let onViewDetails: () -> Void
    
    @GestureState private var translation: CGFloat = 0
    @State private var offset: CGFloat = 0
    @State private var currentOffset: CGFloat = 0
    
    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 48
    private let cardSpacing: CGFloat = 16
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: cardSpacing) {
                ForEach(Array(shops.enumerated()), id: \.element.id) { index, shop in
                    CoffeeShopCard(
                        shop: shop,
                        onViewDetails: onViewDetails,
                        showDragIndicator: false,
                        showLastVisited: false,
                        inverseViewDetailsColors: true
                    )
                    .frame(width: cardWidth)
                }
            }
            .offset(x: -CGFloat(currentIndex) * (cardWidth + cardSpacing) + offset + translation)
            .gesture(
                DragGesture()
                    .updating($translation) { value, state, _ in
                        state = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        var newIndex = currentIndex
                        
                        if value.predictedEndTranslation.width < -threshold && currentIndex < shops.count - 1 {
                            newIndex = currentIndex + 1
                        } else if value.predictedEndTranslation.width > threshold && currentIndex > 0 {
                            newIndex = currentIndex - 1
                        }
                        
                        withAnimation(.spring()) {
                            onSwipe(newIndex)
                            offset = 0
                        }
                    }
            )
        }
        .frame(height: 250)
        .padding(.horizontal, 24)
    }
} 