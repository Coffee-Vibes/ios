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
}
