import SwiftUI

struct OTPVerificationView: View {
    
    enum Event {
        case createProfile
        case back
    }
    
    let onEvent: (Event) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @State private var otpCode = ["", "", "", "", "", ""]
    @State private var currentField = 0
    @FocusState private var focusedField: Int?
    @State private var timeRemaining = 535
    @State private var isLoading = false
    @State private var errorMessage: String?
    let email: String
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 32) {
            // Email Icon
            Image(systemName: "envelope.fill")
                .font(.system(size: 40))
                .foregroundColor(.yellow)
                .padding(.vertical, 32)
            
            // Title and Description
            VStack(spacing: 16) {
                Text("Check your email")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("We just sent you 6-digit code. Looks like very soon you will be logged in!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // OTP Input Fields
            VStack(spacing: 8) {
                Text("Enter the code into field below")
                    .foregroundColor(.gray)
                
                HStack(spacing: 8) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPTextField(text: $otpCode[index], 
                                   isFocused: currentField == index,
                                   fieldIndex: index)
                            .focused($focusedField, equals: index)
                            .onChange(of: otpCode[index]) { newValue in
                                if newValue.count == 1 {
                                    if index < 5 {
                                        currentField = index + 1
                                        focusedField = index + 1
                                    } else {
                                        focusedField = nil
                                    }
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            
            // Timer
            Text("Resend code in \(timeString(from: timeRemaining))")
                .foregroundColor(.gray)
                .font(.subheadline)
                .onReceive(timer) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    }
                }
            
            // Verify Button
            Button(action: handleVerification) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Verify email")
                        .font(.headline)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading || otpCode.contains(""))
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }
            
            // Resend Link
            HStack {
                Text("Didn't receive the email?")
                    .foregroundColor(.gray)
                Button("Click to resend") {
                    handleResendCode()
                }
                .foregroundColor(AppColor.primary)
                .disabled(timeRemaining > 0)
            }
            .font(.subheadline)
            
            // Back Button
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "arrow.left")
                    Text("Back to log in")
                }
                .foregroundColor(AppColor.primary)
            }
            .padding(.top, 32)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentField = 0
                focusedField = 0
            }
        }
    }
    
    private func handleVerification() {
        isLoading = true
        let code = otpCode.joined()
        
        Task {
            do {
                try await authService.verifyOTP(email: email, token: code)
                await MainActor.run {
                    isLoading = false
                    onEvent(.createProfile)
                }
            } catch {
//                onEvent(.createProfile)
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    private func handleResendCode() {
        Task {
            do {
                try await authService.resendOTP(email: email)
                timeRemaining = 72 // Reset timer
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

struct OTPTextField: View {
    @Binding var text: String
    var isFocused: Bool
    let fieldIndex: Int
    
    var body: some View {
        TextField("", text: $text)
            .keyboardType(.numberPad)
            .multilineTextAlignment(.center)
            .foregroundColor(Color(hex: "1D1612"))
            .frame(width: 48, height: 48)
            .background(Color.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isFocused ? AppColor.primary : AppColor.primary.opacity(0.2), lineWidth: 1)
            )
            .onChange(of: text) { newValue in
                if newValue.count > 1 {
                    text = String(newValue.prefix(1))
                }
            }
    }
}

// Add this utility class for programmatic navigation
class NavigationUtil {
    static func navigate<V: View>(to view: V) {
        if let window = UIApplication.shared.windows.first {
            window.rootViewController = UIHostingController(rootView: view)
            window.makeKeyAndVisible()
        }
    }
} 
