import SwiftUI

enum AppColor {
    static let primary = Color(hex: "5D4037")
    static let background = Color(hex: "FAF7F4")
    static let foreground = Color(hex: "1D1612")
    static let inputForeground = Color(hex: "6A6A6A")
}

enum TypeStyle {
    static let t1 = Font.custom("Nunito-SemiBold", size: 16)
    static let t1Color = Color(hex: "151E24")
    
    static let t2 = Font.custom("Nunito-Regular", size: 12)
    static let t2Color = Color(hex: "6A6A6A")
    
    static let h3 = Font.custom("Nunito-SemiBold", size: 14)
    static let h3Color = Color(hex: "1D1612")
    static let h3LineSpacing: CGFloat = 7
    
    static let h4 = Font.custom("Nunito-Regular", size: 12)
    static let h4Color = Color(hex: "1D1612")
    
    static let h4Medium = Font.custom("Nunito-Medium", size: 12)
    static let h4MediumColor = Color(hex: "1D1612")
    static let h4MediumLineSpacing: CGFloat = 6

    static func t1(_ text: Text) -> Text {
        text
            .font(t1)
            .foregroundColor(t1Color)
    }
    
    static func t2(_ text: Text) -> Text {
        text
            .font(t2)
            .foregroundColor(t2Color)
    }
    
    static func h3(_ text: Text) -> Text {
        text
            .font(h3)
            .foregroundColor(h3Color)
    }

    static func h4(_ text: Text) -> Text {
        text
            .font(h4)
            .foregroundColor(h4Color)
    }

    static func h4Medium(_ text: Text) -> Text {
        text
            .font(h4Medium)
            .foregroundColor(h4MediumColor)
    }
}

// Text extension for direct Text styling
extension Text {
    func t1Style() -> Text {
        TypeStyle.t1(self)
    }
    
    func t2Style() -> Text {
        TypeStyle.t2(self)
    }

    func h3Style() -> Text {
        TypeStyle.h3(self)
    }   

    func h4Style() -> Text {
        TypeStyle.h4(self)
    }

    func h4MediumStyle() -> Text {
        TypeStyle.h4Medium(self)
    }
}

// View extension for View styling
extension View {
    func t1Style() -> some View {
        self.modifier(TextStyleModifier(
            font: TypeStyle.t1,
            color: TypeStyle.t1Color
        ))
    }
    
    func t2Style() -> some View {
        self.modifier(TextStyleModifier(
            font: TypeStyle.t2,
            color: TypeStyle.t2Color
        ))
    }

    func h3Style() -> some View {
        self.modifier(TextStyleModifier(
            font: TypeStyle.h3,
            color: TypeStyle.h3Color,
            lineSpacing: TypeStyle.h3LineSpacing
        ))
    }

    func h4Style() -> some View {
        self.modifier(TextStyleModifier(
            font: TypeStyle.h4,
            color: TypeStyle.h4Color
        ))
    }

    func h4MediumStyle() -> some View {
        self.modifier(TextStyleModifier(
            font: TypeStyle.h4Medium,
            color: TypeStyle.h4MediumColor,
            lineSpacing: TypeStyle.h4MediumLineSpacing
        ))
    }
}

struct TextStyleModifier: ViewModifier {
    let font: Font
    let color: Color
    let lineSpacing: CGFloat?
    
    init(font: Font, color: Color, lineSpacing: CGFloat? = nil) {
        self.font = font
        self.color = color
        self.lineSpacing = lineSpacing
    }
    
    func body(content: Content) -> some View {
        content
            .font(font)
            .foregroundColor(color)
            .textCase(nil)
            .lineSpacing(lineSpacing ?? 0)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColor.primary)
            .foregroundColor(.white)
            .cornerRadius(8)
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct SocialButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white)
            .foregroundColor(.black)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: "D0D5DD"), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.9 : 1)
    }
}

struct RoundedTextFieldStyle: TextFieldStyle {
    let error: Bool
    
    init(error: Bool = false) {
        self.error = error
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(height: 44)
            .background(Color.white)
            .cornerRadius(8)
            .foregroundColor(AppColor.inputForeground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(error ? Color.red : Color(hex: "D0D5DD"), lineWidth: 1)
            )
    }
}

struct PasswordFieldStyle: TextFieldStyle {
    let error: Bool
    
    init(error: Bool = false) {
        self.error = error
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(height: 44)
            .background(Color.white)
            .cornerRadius(8)
            .foregroundColor(AppColor.inputForeground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(error ? Color.red : Color(hex: "D0D5DD"), lineWidth: 1)
            )
    }
}

struct CheckboxToggleStyle: ToggleStyle {
    var error: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .foregroundColor(error ? .red : (configuration.isOn ? AppColor.primary : .gray))
                .font(.system(size: 20, weight: .regular))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
            configuration.label
                .foregroundColor(error ? .red : .gray)
        }
    }
} 

struct CustomTextField: View {
    let placeholder: String
    let text: Binding<String>
    let isSecure: Bool
    
    init(_ placeholder: String, text: Binding<String>, isSecure: Bool = false) {
        self.placeholder = placeholder
        self.text = text
        self.isSecure = isSecure
    }
    
    var body: some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
            }
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .padding(.horizontal)
        .autocapitalization(.none)
    }
} 