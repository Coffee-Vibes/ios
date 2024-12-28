import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @State private var email = ""
    @State private var isLoading = false
    @State private var message: String?
    @State private var isError = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Forgot Password")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Enter your email to reset your password")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Email Field
            VStack(alignment: .leading) {
                Text("Email")
                    .foregroundColor(AppColor.foreground)
                TextField("Enter your email", text: $email)
                    .textFieldStyle(RoundedTextFieldStyle())
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }
            .padding(.top, 16)
            
            // Reset Button
            Button(action: handleResetPassword) {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Reset password")
                        .font(.headline)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading || email.isEmpty)
            
            if let message = message {
                Text(message)
                    .foregroundColor(isError ? .red : .green)
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Back to Login Button
            Button(action: { dismiss() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.left")
                    Text("Back to log in")
                }
                .foregroundColor(AppColor.primary)
            }
            .padding(.bottom, 16)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
    
    private func handleResetPassword() {
        isLoading = true
        Task {
            do {
                try await authService.resetPassword(email: email)
                await MainActor.run {
                    message = "Password reset email sent. Please check your inbox."
                    isError = false
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isError = true
                    isLoading = false
                }
            }
        }
    }
} 