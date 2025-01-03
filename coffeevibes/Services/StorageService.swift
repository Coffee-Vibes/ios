import Foundation
import Supabase
import Combine

enum StorageError: Error {
    case invalidImageData
    case uploadFailed(Error)
    case invalidResponse
}

class StorageService: ObservableObject {
    private let supabaseClient = SupabaseConfig.client
    private let bucketId = "photos"
    
    private enum PhotoType {
        case profile
        case checkIn
        
        var folder: String {
            switch self {
            case .profile: return "profiles"
            case .checkIn: return "checkins"
            }
        }
    }
    
    func uploadCheckInPhoto(imageData: Data, userId: String, shopId: String) async throws -> String {
        // Create a unique filename using UUID with proper folder structure
        let filename = "\(PhotoType.checkIn.folder)/\(userId)/\(shopId)/\(UUID().uuidString).jpg"
        
        do {
            // Upload the file
            let file = try await supabaseClient.storage
                .from(bucketId)
                .upload(
                    path: filename,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg"
                    )
                )
            
            // Get the public URL
            let publicURL = try await supabaseClient.storage
                .from(bucketId)
                .createSignedURL(
                    path: file.path,
                    expiresIn: 365 * 24 * 60 * 60 // 1 year
                )
            
            return publicURL.absoluteString
            
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
    
    func uploadProfilePhoto(imageData: Data) async throws -> String {
        let filename = "\(PhotoType.profile.folder)/\(UUID().uuidString).jpg"
        
        do {
            // Upload the file
            let file = try await supabaseClient.storage
                .from(bucketId)
                .upload(
                    path: filename,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/jpeg"
                    )
                )
            
            // Get the public URL
            let publicURL = try supabaseClient.storage
                .from(bucketId)
                .getPublicURL(path: file.path)
            
            return publicURL.absoluteString
            
        } catch {
            throw StorageError.uploadFailed(error)
        }
    }
} 