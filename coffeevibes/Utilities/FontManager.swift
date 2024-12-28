import SwiftUI

enum CustomFont: String {
    case nunitoSemiBold = "Nunito-SemiBold"
    
    func size(_ size: CGFloat) -> Font {
        return .custom(self.rawValue, size: size)
    }
}

final class FontManager {
    static func registerFonts() {
        if let fontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) {
            for url in fontURLs {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }
} 