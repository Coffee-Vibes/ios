import Foundation

struct UserDetails: Codable {
    var userId: String
    var name: String?
    var email: String
    var phone: String?
    var profilePhoto: String?
    var isNotificationsEnabled: Bool
    var bio: String?
    var preferredVibes: [String]?
    var createdAt: String?
    var modifiedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case email
        case phone
        case profilePhoto = "profile_photo"
        case isNotificationsEnabled = "is_notifications_enabled"
        case bio
        case preferredVibes = "preferred_vibes"
        case createdAt = "created_at"
        case modifiedAt = "modified_at"
    }
} 
