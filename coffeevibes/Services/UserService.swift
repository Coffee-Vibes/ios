import Foundation
import Combine

class UserService: ObservableObject {
    func fetchUserDetails(email: String) async throws -> UserDetails {
        let endpoint = "/users?email=eq.\(email)"
        let userDetailsArray: [UserDetails] = try await NetworkManager.shared.fetchData(from: endpoint)
        
        // Return the first user details if available
        guard let userDetails = userDetailsArray.first else {
            throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No user details found"])
        }
        
        return userDetails
    }
} 