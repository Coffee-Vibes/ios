import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchData<T: Decodable>(from endpoint: String) async throws -> T {
        let url = URL(string: "\(APIConfig.baseURL)\(endpoint)")!
        var request = URLRequest(url: url)
        request.setValue(APIConfig.apiKey, forHTTPHeaderField: "apikey") // Use API key from APIConfig
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response from server"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            throw NSError(domain: "NetworkError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server: \(httpResponse.statusCode), Body: \(responseBody)"])
        }
        
        // Log the raw data for debugging
        print("Raw response data: \(String(data: data, encoding: .utf8) ?? "No data")")
        
        let decodedData = try JSONDecoder().decode(T.self, from: data)
        return decodedData
    }
} 