import Foundation

struct CoffeeShopReview: Identifiable, Decodable {
    let id: UUID
    let userId: UUID
    let shopId: String
    let rating: Int
    let reviewText: String
    let createdAt: Date
    let modifiedAt: Date
    var user: UserDetails?
    
    private enum CodingKeys: String, CodingKey {
        case id = "review_id"
        case userId = "user_id"
        case shopId = "shop_id"
        case rating
        case reviewText = "review_text"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
        case user = "user_profiles"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle UUID decoding
        if let idString = try? container.decode(String.self, forKey: .id) {
            self.id = UUID(uuidString: idString) ?? UUID()
        } else {
            self.id = UUID()
        }
        
        // Handle userId decoding
        if let userIdString = try? container.decode(String.self, forKey: .userId) {
            self.userId = UUID(uuidString: userIdString) ?? UUID()
        } else {
            self.userId = UUID()
        }
        
        self.shopId = try container.decode(String.self, forKey: .shopId)
        self.rating = try container.decode(Int.self, forKey: .rating)
        self.reviewText = try container.decode(String.self, forKey: .reviewText)
        self.createdAt = try container.decode(Date.self, forKey: .createdAt)
        self.modifiedAt = try container.decode(Date.self, forKey: .modifiedAt)
        
        // Decode user profile data more robustly
        if let userProfileData = try? container.decode(UserProfileData.self, forKey: .user) {
            self.user = UserDetails(
                userId: userProfileData.userId,
                name: userProfileData.name,
                email: "", // We don't receive email in this context
                profilePhoto: userProfileData.profilePhoto
            )
        } else {
            self.user = nil
        }
    }
}

// Helper struct to decode user profile data
private struct UserProfileData: Decodable {
    let userId: String
    let name: String?
    let profilePhoto: String?
    
    private enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case profilePhoto = "profile_photo"
    }
}

// Add this extension to UserDetails to support partial initialization
extension UserDetails {
    init(userId: String, name: String?, email: String, profilePhoto: String?) {
        self.userId = userId
        self.name = name
        self.email = email
        self.profilePhoto = profilePhoto
        self.isNotificationsEnabled = false
        self.bio = nil
        self.preferredVibes = nil
        self.createdAt = nil
        self.modifiedAt = nil
        self.phone = nil
        self.reviewCount = 0
        self.checkInCount = 0
        self.favoriteCount = 0
    }
} 
