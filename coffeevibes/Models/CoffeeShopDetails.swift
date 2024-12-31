import Foundation

struct CoffeeShopDetails: Codable {
    let shopRecord: CoffeeShop
    let isFavorite: Bool
    let isOpenNow: Bool
    let isClosingSoon: Bool
    let todayHours: String
    let distance: Double
    
    enum CodingKeys: String, CodingKey {
        case shopRecord = "shop_record"
        case isFavorite = "is_favorite"
        case isOpenNow = "is_open_now"
        case isClosingSoon = "is_closing_soon"
        case todayHours = "today_hours"
        case distance
    }
} 