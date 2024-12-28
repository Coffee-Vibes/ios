import Foundation

struct Review: Identifiable, Decodable {
    let id: UUID
    let userId: UUID
    let shopId: UUID
    let rating: Int
    let reviewText: String
    let createdAt: Date
    let modifiedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id = "review_id"
        case userId = "user_id"
        case shopId = "shop_id"
        case rating
        case reviewText = "review_text"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
} 