import Foundation

class GooglePlacesService {
    static let shared = GooglePlacesService()
    private let apiKey = "AIzaSyDmMGOm9KSx7L8vHTh2Bsyw6x6r_gUjCkQ"
    
    func getPhotoURL(reference: String, maxWidth: Int = 800) -> URL? {
        // Extract the place ID and photo reference
        let components = reference.components(separatedBy: "/photos/")
        guard components.count == 2,
              let photoReference = components.last?.trimmingCharacters(in: .whitespaces) else {
            print("Invalid photo reference format: \(reference)")
            return nil
        }
        
        // Construct the Google Places Photo URL with proper encoding
        let baseURL = "https://maps.googleapis.com/maps/api/place/photo"
        guard var urlComponents = URLComponents(string: baseURL) else {
            print("Failed to create URL components")
            return nil
        }
        
        urlComponents.queryItems = [
            URLQueryItem(name: "maxwidth", value: String(maxWidth)),
            URLQueryItem(name: "photo_reference", value: photoReference),
            URLQueryItem(name: "key", value: apiKey)
        ]
        
        guard let url = urlComponents.url else {
            print("Failed to create URL from components")
            return nil
        }
        
        return url
    }
} 