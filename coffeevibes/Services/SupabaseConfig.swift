import Foundation
import Supabase

struct SupabaseConfig {
    static let client: SupabaseClient = {
        // Fetch the API_BASE_URL from the Info.plist
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("Invalid API_BASE_URL in Info.plist")
        }
        
        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbnBydnB5ZGpxZnBxc3FuZHFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE0NDkzMjUsImV4cCI6MjA0NzAyNTMyNX0.P6kEyF1kvKUAqC0rDguRkqxPJk3o4FE57lME3-hmHP8"
        )
    }()
}
