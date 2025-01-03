import Foundation

// Add CoffeeShopWithFavorite struct at the top level

    




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
    let description: String?
    let summary: String?
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
    var isOpenNow: Bool = false
    var isClosingSoon: Bool = false
    var todayHours: String?
    var distance: Double?
    var websiteUrl: String?
    var phone: String?
    var lastVisited: Date?
    var visitCount: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id = "shop_id"
        case name
        case description
        case summary
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
        case isFavorite = "is_favorite"
        case isOpenNow = "is_open_now"
        case isClosingSoon = "is_closing_soon"
        case todayHours = "today_hours"
        case distance
        case websiteUrl = "website_url"
        case phone
        case lastVisited = "last_visited"
        case visitCount = "visit_count"
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
              let tags = dictionary["tags"] as? [String],   
              let isFavorite = dictionary["is_favorite"] as? Bool,
              let isOpenNow = dictionary["is_open_now"] as? Bool,
              let isClosingSoon = dictionary["is_closing_soon"] as? Bool,
              let todayHours = dictionary["today_hours"] as? String,
              let distance = dictionary["distance"] as? Double,
              let tags = dictionary["tags"] as? [String],
              let websiteUrl = dictionary["website_url"] as? String,
              let phone = dictionary["phone"] as? String else {
            return nil
        }
        self.id = id
        self.name = name
        self.description = dictionary["description"] as? String
        self.summary = dictionary["summary"] as? String
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
        self.isFavorite = isFavorite
        self.isOpenNow = isOpenNow
        self.isClosingSoon = isClosingSoon
        self.todayHours = todayHours
        self.distance = distance
        self.websiteUrl = websiteUrl
        self.phone = phone
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name) 
        description = try container.decodeIfPresent(String.self, forKey: .description)
        summary = try container.decodeIfPresent(String.self, forKey: .summary)
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
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isOpenNow = try container.decodeIfPresent(Bool.self, forKey: .isOpenNow) ?? false
        isClosingSoon = try container.decodeIfPresent(Bool.self, forKey: .isClosingSoon) ?? false
        todayHours = try container.decodeIfPresent(String.self, forKey: .todayHours)
        distance = try container.decodeIfPresent(Double.self, forKey: .distance)
        websiteUrl = try container.decodeIfPresent(String.self, forKey: .websiteUrl)
        phone = try container.decodeIfPresent(String.self, forKey: .phone)
        lastVisited = try container.decodeIfPresent(Date.self, forKey: .lastVisited)
        visitCount = try container.decodeIfPresent(Int.self, forKey: .visitCount)
    }
    
   
    
    static func == (lhs: CoffeeShop, rhs: CoffeeShop) -> Bool {
        lhs.id == rhs.id
    }
}
