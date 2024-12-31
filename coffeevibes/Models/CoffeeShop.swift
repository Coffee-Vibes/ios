import Foundation

// Add CoffeeShopWithFavorite struct at the top level
struct CoffeeShopWithFavorite: Codable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String
    let postalCode: String
    let logoUrl: String?
    let latitude: Double?
    let longitude: Double?
    let averageRating: Double?
    let coverPhoto: String
    let tags: [String]
    let favorites: [FavoriteInfo]?
    let specialHours: [ShopHours]?
    let regularHours: [ShopHours]?
    
    struct FavoriteInfo: Codable {
        let user_id: String
    }
    
    private enum CodingKeys: String, CodingKey {
        case id = "shop_id"
        case name
        case address
        case city
        case state
        case postalCode = "postal_code"
        case logoUrl = "logo_url"
        case latitude
        case longitude
        case averageRating = "average_rating"
        case coverPhoto = "cover_photo"
        case tags
        case favorites
        case specialHours = "coffee_shop_special_hours"
        case regularHours = "coffee_shop_hours"
    }
}

struct ShopHours: Codable {
    let openTime: String
    let closeTime: String
    
    private enum CodingKeys: String, CodingKey {
        case openTime = "open_time"
        case closeTime = "close_time"
    }
}

struct CoffeeShop: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let city: String
    let state: String
    let postalCode: String
    let logoUrl: String?
    let latitude: Double?
    let longitude: Double?
    let averageRating: Double?
    let coverPhoto: String
    let tags: [String]
    var isFavorite: Bool = false
    var todaysHours: ShopHours?
    
    private enum CodingKeys: String, CodingKey {
        case id = "shop_id"
        case name
        case address
        case city
        case state
        case postalCode = "postal_code"
        case logoUrl = "logo_url"
        case latitude
        case longitude
        case averageRating = "average_rating"
        case coverPhoto = "cover_photo"
        case tags = "tags"
        case todaysHours = "todays_hours"
    }
    
    init?(from dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? String,
              let name = dictionary["name"] as? String,
              let address = dictionary["address"] as? String,
              let city = dictionary["city"] as? String,
              let state = dictionary["state"] as? String,
              let postalCode = dictionary["postalCode"] as? String,
              let logoUrl = dictionary["logoUrl"] as? String,
              let latitude = dictionary["latitude"] as? Double,
              let longitude = dictionary["longitude"] as? Double,
              let averageRating = dictionary["average_rating"] as? Double,
              let coverPhoto = dictionary["coverPhoto"] as? String,
              let tags = dictionary["tags"] as? [String] else {
            return nil
        }
        self.id = id
        self.name = name
        self.address = address
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.logoUrl = logoUrl
        self.latitude = latitude
        self.longitude = longitude
        self.averageRating = averageRating
        self.coverPhoto = coverPhoto
        self.tags = tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        address = try container.decode(String.self, forKey: .address)
        city = try container.decode(String.self, forKey: .city)
        state = try container.decode(String.self, forKey: .state)
        postalCode = try container.decode(String.self, forKey: .postalCode)
        logoUrl = try container.decodeIfPresent(String.self, forKey: .logoUrl)
        latitude = try container.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try container.decodeIfPresent(Double.self, forKey: .longitude)
        averageRating = try container.decodeIfPresent(Double.self, forKey: .averageRating)
        coverPhoto = try container.decode(String.self, forKey: .coverPhoto)
        tags = try container.decode([String].self, forKey: .tags)
    }
    
    init(from withFavorite: CoffeeShopWithFavorite) {
        self.id = withFavorite.id
        self.name = withFavorite.name
        self.address = withFavorite.address
        self.city = withFavorite.city
        self.state = withFavorite.state
        self.postalCode = withFavorite.postalCode
        self.logoUrl = withFavorite.logoUrl
        self.latitude = withFavorite.latitude
        self.longitude = withFavorite.longitude
        self.averageRating = withFavorite.averageRating
        self.coverPhoto = withFavorite.coverPhoto
        self.tags = withFavorite.tags
        // isFavorite will be set separately
    }
    
    static func == (lhs: CoffeeShop, rhs: CoffeeShop) -> Bool {
        lhs.id == rhs.id
    }
}
