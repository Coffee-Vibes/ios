import Foundation
struct FavoriteShop: Decodable {
    let id: String
    let userId: String
    
    // Add other properties as needed based on your database schema

     private enum CodingKeys: String, CodingKey {
        case id = "shop_id"
        case userId = "user_id"
    }
}
