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
        
        // Handle rating decoding (could be String or Int in the database)
        if let ratingString = try? container.decode(String.self, forKey: .rating),
           let ratingInt = Int(ratingString) {
            self.rating = ratingInt
        } else {
            self.rating = try container.decode(Int.self, forKey: .rating)
        }
        
        self.reviewText = try container.decode(String.self, forKey: .reviewText)
        
        // Handle date decoding
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: createdAtString) {
            self.createdAt = date
        } else {
            self.createdAt = Date()
        }
        
        if let modifiedAtString = try? container.decode(String.self, forKey: .modifiedAt),
           let date = dateFormatter.date(from: modifiedAtString) {
            self.modifiedAt = date
        } else {
            self.modifiedAt = Date()
        }
    }
} 