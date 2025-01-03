import Foundation
import Supabase

class CoffeeShopReviewService: ObservableObject {
    @Published private(set) var isLoading = false
    private let supabaseClient = SupabaseConfig.client
    
    private func setLoading(_ value: Bool) {
        Task { @MainActor in
            isLoading = value
        }
    }
    
    // Create a new review
    func createReview(userId: UUID, shopId: String, rating: Int, reviewText: String) async throws {
        await setLoading(true)
        defer { Task { @MainActor in await setLoading(false) } }
        
        let response = try await supabaseClient
            .from("coffee_shop_reviews")
            .insert([
                "user_id": userId.uuidString,
                "shop_id": shopId,
                "rating": String(rating),
                "review_text": reviewText
            ])
            .execute()
        
        guard response.status == 201 else {
            throw NSError(domain: "CoffeeShopReviewService", code: response.status, 
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create review"])
        }
    }
    
    // Read reviews for a specific shop
    func getReviews(for shopId: String) async throws -> [CoffeeShopReview] {
        await setLoading(true)
        defer { Task { @MainActor in await setLoading(false) } }
        
        let response = try await supabaseClient
            .from("coffee_shop_reviews")
            .select("""
                review_id,
                user_id,
                shop_id,
                rating,
                review_text,
                created_at,
                modified_at,
                user_profiles (
                    user_id,
                    name,
                    profile_photo
                )
            """)
            .eq("shop_id", value: shopId)
            .order("created_at", ascending: false)
            .execute()
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        return try decoder.decode([CoffeeShopReview].self, from: response.data)
    }


    // Update an existing review
    func updateReview(reviewId: UUID, rating: Int, reviewText: String) async throws {
        await setLoading(true)
        defer { Task { @MainActor in await setLoading(false) } }
        
        let response = try await supabaseClient
            .from("coffee_shop_reviews")
            .update([
                "rating": String(rating),
                "review_text": reviewText,
                "modified_at": "NOW()"
            ])
            .eq("review_id", value: reviewId.uuidString)
            .execute()
        
        guard response.status == 200 else {
            throw NSError(domain: "CoffeeShopReviewService", code: response.status,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to update review"])
        }
    }
    
    // Delete a review
    func deleteReview(reviewId: UUID) async throws {
        await setLoading(true)
        defer { Task { @MainActor in await setLoading(false) } }
        
        let response = try await supabaseClient
            .from("coffee_shop_reviews")
            .delete()
            .eq("review_id", value: reviewId.uuidString)
            .execute()
        
        guard response.status == 204 else {
            throw NSError(domain: "CoffeeShopReviewService", code: response.status,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to delete review"])
        }
    }
    
    // Get user's review for a specific shop
    func getUserReview(userId: UUID, shopId: String) async throws -> CoffeeShopReview? {
        await setLoading(true)
        defer { Task { @MainActor in await setLoading(false) } }
        
        let response = try await supabaseClient
            .from("coffee_shop_reviews")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("shop_id", value: shopId)
            .execute()
        
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        
        let reviews = try decoder.decode([CoffeeShopReview].self, from: response.data)
        return reviews.first
    }
} 