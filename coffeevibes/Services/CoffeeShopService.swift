import Foundation
import Combine
import Supabase

// Add this struct at the top of the file, outside the class
struct NearbySearchParams: Encodable {
    let lat: Double
    let lon: Double
    let radius: Double
}

struct ShopSearchParams: Encodable {
    let userId: String
    let lat: Double
    let lon: Double
    let radius: Double
    
    enum CodingKeys: String, CodingKey {
        case userId = "p_user_id"
        case lat = "p_user_lat"
        case lon = "p_user_lon"
        case radius = "p_radius"
    }
}

// Add this struct to handle the response format
struct CoffeeShopResponse: Codable {
    let shopRecord: CoffeeShop
    let isFavorite: Bool
    let isOpenNow: Bool
    let isClosingSoon: Bool
    let todayHours: String?
    let distance: Double?
    
    enum CodingKeys: String, CodingKey {
        case shopRecord = "shop_record"
        case isFavorite = "is_favorite"
        case isOpenNow = "is_open_now"
        case isClosingSoon = "is_closing_soon"
        case todayHours = "today_hours"
        case distance
    }
}

struct CheckIn: Codable {
    let shopId: String
    let note: String?
    let photoUrl: String?
    let mood: CheckInMood
    let checkedInAt: Date
    
    enum CodingKeys: String, CodingKey {
        case shopId = "shop_id"
        case note
        case photoUrl = "photo_url"
        case mood
        case checkedInAt = "checked_in_at"
    }
}

enum CheckInMood: String, Codable, CaseIterable {
    case productive
    case relaxed
    case social
    case focused
    case creative
}

@MainActor
class CoffeeShopService: ObservableObject {
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCoffeeShop: CoffeeShop?

    private let supabaseClient = SupabaseConfig.client

    // Function to get all coffee shops using async/await
 



     
    // Function to get a specific coffee shop by shop_id using async/await
     func getCoffeeShop(shopId: String) async -> CoffeeShop? { // Update return type
        isLoading = true
        defer { isLoading = false } // Ensure loading state is reset
        do {
            let response = try await supabaseClient
                .from("coffee_shops")
                .select()
                .eq("shop_id", value: shopId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            let shop = try decoder.decode(CoffeeShop.self, from: response.data)
            selectedCoffeeShop = shop
            errorMessage = nil
            return shop // Return the shop
        } catch {
            print("Error fetching coffee shop details: \(error)")
            errorMessage = error.localizedDescription
            return nil // Return nil on error
        }
    }

 func getFavoriteCoffeeShop(userId: String, shopId: String) async -> CoffeeShop? { // Update return type
        isLoading = true
        defer { isLoading = false } // Ensure loading state is reset
        do {
            let response = try await supabaseClient
                .from("favorites")
                .select()
                .eq("user_id", value: userId)
                .eq("shop_id", value: shopId)
                .single()
                .execute()

            let decoder = JSONDecoder()
            let shop = try decoder.decode(CoffeeShop.self, from: response.data)
            selectedCoffeeShop = shop
            errorMessage = nil
            return shop // Return the shop
        } catch {
            print("Error fetching coffee shop details: \(error)")
            errorMessage = error.localizedDescription
            return nil // Return nil on error
        }
    }

    // Function to create a favorite coffee shop
    func createFavorite(shopId: String, userId: String) async {
        print("Creating favorite for shop \(shopId) and user \(userId)")
        // Check if the favorite already exists
               let existingFavorite = await getFavoriteCoffeeShop(userId: userId, shopId: shopId)
               if existingFavorite != nil {
                   errorMessage = "This coffee shop is already in your favorites."
                   return
               }

               let data: [String: String] = ["shop_id": shopId, "user_id": userId]
               do {
                   let response = try await supabaseClient
                       .from("favorites")
                       .insert(data)
                       .execute()
                   
                   if response.status == 201 {
                       print("Favorite created successfully")
                   }
               } catch {
                   print("Error creating favorite: \(error)")
                   errorMessage = error.localizedDescription
               }
    }

    // Function to delete a favorite coffee shop
    func deleteFavorite(shopId: String, userId: String) async {
        print("Deleting favorite for shop \(shopId) and user \(userId)")
        do {
            let response = try await supabaseClient
                .from("favorites")
                .delete()
                .eq("shop_id", value: shopId)
                .eq("user_id", value: userId)
                .execute()
            
            if response.status == 204 {
                print("Favorite deleted successfully")
            }
        } catch {
            print("Error deleting favorite: \(error)")
            errorMessage = error.localizedDescription
        }
    }

  

    // Function to get all coffee shops with favorite status for a user
 

    @MainActor
    func getCoffeeShopsNearby(userId: String, latitude: Double, longitude: Double, radiusInMiles: Double) async throws -> [CoffeeShop] {
        isLoading = true
        defer { isLoading = false }
        
        let params = ShopSearchParams(
            userId: userId,
            lat: latitude,
            lon: longitude,
            radius: radiusInMiles * 1609.34
        )
        
        do {
            let response = try await supabaseClient
                .rpc("get_coffee_shops_nearby", params: params)
                .execute()
            
            print("Response data: \(String(data: response.data, encoding: .utf8) ?? "No data")")
            let decoder = JSONDecoder()
            let shopResponses = try decoder.decode([CoffeeShopResponse].self, from: response.data)
            
            let shops = shopResponses.map { response -> CoffeeShop in
                var shop = response.shopRecord
                shop.isFavorite = response.isFavorite
                shop.isOpenNow = response.isOpenNow
                shop.isClosingSoon = response.isClosingSoon
                shop.todayHours = response.todayHours
                shop.distance = response.distance
                return shop
            }
            
            self.coffeeShops = shops
            return shops
        } catch {
            print("Error fetching nearby coffee shops: \(error)")
            throw error
        }
    }

    @MainActor
    func getAllFavoriteCoffeeShops(userId: String, latitude: Double, longitude: Double, radiusInMiles: Double) async throws -> [CoffeeShop] {
        isLoading = true
        defer { isLoading = false }
        
        let params = ShopSearchParams(
            userId: userId,
            lat: latitude,
            lon: longitude,
            radius: radiusInMiles * 1609.34
        )
        
        do {
            let response = try await supabaseClient
                .rpc("get_coffee_shops_favorites", params: params)
                .execute()
            
            let decoder = JSONDecoder()
            let shopResponses = try decoder.decode([CoffeeShopResponse].self, from: response.data)
            
            return shopResponses.map { response -> CoffeeShop in
                var shop = response.shopRecord
                shop.isFavorite = response.isFavorite
                shop.isOpenNow = response.isOpenNow
                shop.isClosingSoon = response.isClosingSoon
                shop.todayHours = response.todayHours
                shop.distance = response.distance
                return shop
            }
        } catch {
            print("Error fetching favorite coffee shops: \(error)")
            throw error
        }
    }

    private struct VisitRequest: Encodable {
        let shopId: String
        let userId: String
        let visitedAt: String
        
        enum CodingKeys: String, CodingKey {
            case shopId = "shop_id"
            case userId = "user_id"
            case visitedAt = "visited_at"
        }
    }

    private struct ShopUpdateRequest: Encodable {
        let visitCount: String
        let lastVisited: String
        
        enum CodingKeys: String, CodingKey {
            case visitCount = "visit_count"
            case lastVisited = "last_visited"
        }
    }

    func trackVisit(for shopId: String, userId: String) async throws {
        let path = "coffee_shop_visits"
        let visitRequest = VisitRequest(
            shopId: shopId,
            userId: userId,
            visitedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabaseClient
            .from(path)
            .insert(visitRequest)
            .execute()
            
        // Update the visit count and last visited timestamp
        let updateRequest = ShopUpdateRequest(
            visitCount: "visit_count + 1",
            lastVisited: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabaseClient
            .from("coffee_shops")
            .update(updateRequest)
            .eq("shop_id", value: shopId)
            .execute()
    }

    // Add this struct inside CoffeeShopService
    private struct CheckInRequest: Encodable {
        let shopId: String
        let userId: String
        let checkedInAt: String
        let note: String?
        let photoUrl: String?
        let mood: String
        
        enum CodingKeys: String, CodingKey {
            case shopId = "shop_id"
            case userId = "user_id"
            case checkedInAt = "checked_in_at"
            case note
            case photoUrl = "photo_url"
            case mood
        }
    }

    func checkIn(to shopId: String, userId: String, checkIn: CheckIn) async throws {
        let path = "coffee_shop_checkins"
        let checkInRequest = CheckInRequest(
            shopId: shopId,
            userId: userId,
            checkedInAt: ISO8601DateFormatter().string(from: Date()),
            note: checkIn.note,
            photoUrl: checkIn.photoUrl,
            mood: checkIn.mood.rawValue
        )
        
        try await supabaseClient
            .from(path)
            .insert(checkInRequest)
            .execute()
    }
    
    struct CheckInResponse: Codable {
        let id: UUID
        let shopId: String
        let userId: String
        let note: String?
        let photoUrl: String?
        let mood: CheckInMood
        let checkedInAt: Date
        
        enum CodingKeys: String, CodingKey {
            case id
            case shopId = "shop_id"
            case userId = "user_id"
            case note
            case photoUrl = "photo_url"
            case mood
            case checkedInAt = "checked_in_at"
        }
    }
    
    func getRecentCheckIns(for shopId: String, limit: Int = 10) async throws -> [CheckInResponse] {
        let response = try await supabaseClient
            .from("coffee_shop_checkins")
            .select()
            .eq("shop_id", value: shopId)
            .order("checked_in_at", ascending: false)
            .limit(limit)
            .execute()
            
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([CheckInResponse].self, from: response.data)
    }
}
