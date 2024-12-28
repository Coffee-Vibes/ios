import Foundation
import Combine
import Supabase

// Add this struct at the top of the file, outside the class
struct NearbySearchParams: Encodable {
    let lat: Double
    let lon: Double
    let radius: Double
}

@MainActor
class CoffeeShopService: ObservableObject {
    @Published var coffeeShops: [CoffeeShop] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedCoffeeShop: CoffeeShop?

    private let supabaseClient = SupabaseConfig.client

    // Function to get all coffee shops using async/await
    func getAllCoffeeShops() async {
        isLoading = true
        do {
            let response = try await supabaseClient
                .from("coffee_shops")
                .select()
                .execute()

            let decoder = JSONDecoder()
            let shops = try decoder.decode([CoffeeShop].self, from: response.data)
            coffeeShops = shops
            errorMessage = nil
        } catch {
            print("Error decoding coffee shops: \(error)")
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // Updated function to get coffee shops nearby based on user's location using RPC
    func getCoffeeShopsNearby(latitude: Double, longitude: Double) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let params = NearbySearchParams(
                lat: latitude,
                lon: longitude,
                radius: 16093.4  // 10mi radius
            )
            
            let response = try await supabaseClient
                .rpc("get_nearby_coffee_shops", params: params)
                .execute()

            let decoder = JSONDecoder()
            let shops = try decoder.decode([CoffeeShop].self, from: response.data)
            
            await MainActor.run {
                self.coffeeShops = shops
                self.errorMessage = nil
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("Error fetching nearby coffee shops: \(error)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

     
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

    // Function to get all favorite coffee shops by user ID using async/await
    func getFavoriteCoffeeShops(by userId: String) async throws -> [CoffeeShop] {   
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabaseClient
                .from("coffee_shops")
                .select("*, favorites!inner(*)") // Assuming a join with coffee_shops table
                .eq("favorites.user_id", value: userId)
                .execute()
            
            let data = response.data
            
            let decoder = JSONDecoder()
            let coffeeShops = try decoder.decode([CoffeeShop].self, from: data)
            print(coffeeShops)
            return coffeeShops
        } catch {
            print("Error fetching favorite coffee shops: \(error)")
            throw error
        }
    }

    // Function to get all coffee shops with favorite status for a user
    func getCoffeeShopsWithFavoriteStatus(by userId: String) async throws -> [CoffeeShop] {   
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabaseClient
                .from("coffee_shops")
                .select("""
                    *,
                    favorites!left(
                        user_id
                    )
                """)
                .execute()
            
            let decoder = JSONDecoder()
            let coffeeShopsWithFavorites = try decoder.decode([CoffeeShopWithFavorite].self, from: response.data)
            
            // Convert to CoffeeShop objects with isFavorite status
            let coffeeShops = coffeeShopsWithFavorites.map { shopWithFavorite -> CoffeeShop in
                var shop = CoffeeShop(from: shopWithFavorite)
                shop.isFavorite = shopWithFavorite.favorites?.contains { $0.user_id == userId } ?? false
                return shop
            }
            
            return coffeeShops
        } catch {
            print("Error fetching coffee shops with favorite status: \(error)")
            throw error
        }
    }

    func getReviews(for shopId: String) async throws -> [Review] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response = try await supabaseClient
                .from("reviews")
                .select()
                .eq("shop_id", value: shopId)
                .execute()
            
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm" // Simplified format
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // Set to UTC if your dates are in UTC
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            
            let reviews = try decoder.decode([Review].self, from: response.data)
            print("Reviews for shop \(shopId): \(reviews)")
            return reviews
        } catch {
            print("Error fetching reviews: \(error)")
            throw error
        }
    }
}
