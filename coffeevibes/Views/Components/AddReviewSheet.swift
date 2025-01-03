import SwiftUI

struct AddReviewSheet: View {
    let coffeeShop: CoffeeShop
    @Binding var isPresented: Bool
    var onReviewAdded: () -> Void
    
    @State private var rating: Int = 0
    @State private var reviewText: String = ""
    @State private var isSubmitting = false
    @EnvironmentObject private var authService: AuthenticationService
    @State private var errorMessage: String?
    @StateObject private var reviewService = CoffeeShopReviewService()
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Rate your experience")
                    .font(.headline)
                
                // Rating Selection
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 30))
                            .foregroundColor(index <= rating ? AppColor.primary : Color.gray.opacity(0.3))
                            .onTapGesture {
                                rating = index
                            }
                    }
                }
                .padding(.bottom)
                
                // Review Text
                Text("Write your review")
                    .font(.headline)
                
                TextEditor(text: $reviewText)
                    .frame(height: 120)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Add Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        submitReview()
                    }
                    .disabled(rating == 0 || reviewText.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func submitReview() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "Please log in to submit a review"
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                try await reviewService.createReview(
                    userId: userId,
                    shopId: coffeeShop.id,
                    rating: rating,
                    reviewText: reviewText
                )
                // Dispatch UI updates to the main thread
                await MainActor.run {
                    isSubmitting = false
                    isPresented = false
                    onReviewAdded()
                }
            } catch {
                // Dispatch UI updates to the main thread
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
} 