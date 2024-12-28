import Foundation

struct APIConfig {
    static var baseURL: String {
        #if DEBUG
        return "https://adnprvpydjqfpqsqndqj.supabase.co/rest/v1"
        #else
        return "https://placeholder-for-production-url.com/rest/v1"
        #endif
    }
    
    static var apiKey: String {
        return ProcessInfo.processInfo.environment["API_KEY"] ?? "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkbnBydnB5ZGpxZnBxc3FuZHFqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzE0NDkzMjUsImV4cCI6MjA0NzAyNTMyNX0.P6kEyF1kvKUAqC0rDguRkqxPJk3o4FE57lME3-hmHP8"
    }
} 
