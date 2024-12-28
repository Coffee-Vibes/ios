import SwiftUI

enum CustomFont: String {
    case nunitoSemiBold = "Nunito-SemiBold"
    
    func size(_ size: CGFloat) -> Font {
        return .custom(self.rawValue, size: size)
    }
}

final class FontManager {
    static func registerFonts() {
        // Keep track of registered fonts to avoid duplicates
        var registeredFonts = Set<String>()
        
        if let fontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            for url in fontURLs {
                let fontName = url.lastPathComponent
                // Only register if not already registered
                if !registeredFonts.contains(fontName) {
                    CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
                    registeredFonts.insert(fontName)
                }
            }
        }
    }
} 