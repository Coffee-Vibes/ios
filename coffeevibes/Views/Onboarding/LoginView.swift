import SwiftUI
import AuthenticationServices
import PhotosUI  // Required for ImagePicker
import CryptoKit // Add this import

struct LoginView: View {
    enum Event {
        case signUp
        case back
    }
    
    @StateObject private var authService = AuthenticationService()
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var rememberMe = false
    @State private var isPasswordVisible = false
    @State private var showingTestProfileSetup = false
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var loginError: String?
    @State private var currentNonce: String?
    
    let onEvent: (Event) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .center, spacing: 8) {
                Image("logo")
                    .resizable()
                   // .scaledToFit()
                    .frame(width: 200, height: 200)
                Text("Log in to your account")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.black)
                Text("Welcome back! Please enter your details.")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 20)
            .padding(.bottom, 20)
            
            // Login Form
            VStack {
                ScrollView {
                    VStack(spacing: 32) {
                        // Email/Password Fields
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .foregroundColor(Color(hex: "1D1612"))
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(RoundedTextFieldStyle(error: emailError != nil))
                                    .textInputAutocapitalization(.never)
                                if let error = emailError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .foregroundColor(Color(hex: "1D1612"))
                                ZStack(alignment: .trailing) {
                                    if isPasswordVisible {
                                        TextField("••••••••", text: $password)
                                            .textFieldStyle(PasswordFieldStyle(error: passwordError != nil))
                                    } else {
                                        SecureField("••••••••", text: $password)
                                            .textFieldStyle(PasswordFieldStyle(error: passwordError != nil))
                                    }
                                    
                                    Button(action: {
                                        isPasswordVisible.toggle()
                                    }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                            .foregroundColor(.gray)
                                            .padding(.trailing, 8)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(passwordError != nil ? Color.red : Color(hex: "D0D5DD"), lineWidth: 1)
                                )
                                if let error = passwordError {
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                         // Test Profile Setup Button
                        // Remember Me & Forgot Password
                        HStack {
                            Toggle("Remember for 30 days", isOn: $rememberMe)
                                .toggleStyle(CheckboxToggleStyle())
                                .font(.system(size: 14, weight: .medium))
                            Spacer()
                            
                            NavigationLink("Forgot password?") {
                                ForgotPasswordView()
                            }
                            .foregroundColor(AppColor.primary)
                            .font(.system(size: 14, weight: .semibold))
                        }
                        
                        // Login Button
                        Button(action: handleLogin) {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Login")
                                    .font(.headline)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isLoading)
                        
                        // Add error message display
                        if let error = loginError {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                        
                        // Social Login Options
                        VStack(spacing: 8) {
                            SignInWithAppleButton(.signIn) { request in
                                let nonce = authService.generateNonce()
                                currentNonce = nonce
                                request.requestedScopes = [.email, .fullName]
                                request.nonce = authService.sha256(nonce)
                            } onCompletion: { result in
                                handleAppleSignIn(result)
                            }
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 44)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(hex: "D0D5DD"), lineWidth: 1)
                            )
                            
                            Button(action: handleGoogleSignIn) {
                                HStack {
                                    Image("social_google")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text("Login with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .buttonStyle(SocialButtonStyle())
                        }
                    }
                    .padding(24)
                }
                
                Spacer()
                
                // Sign Up Link
                HStack {
                    Text("Don't have an account?")
                        .foregroundColor(.gray)
                    Button("Sign up") {
                        onEvent(.signUp)
                    }
                    .foregroundColor(AppColor.primary)
                }
                .font(.subheadline)
                .padding(.bottom, 34)
                
               
                .foregroundColor(AppColor.primary)
                .padding(.top, 8)
                .sheet(isPresented: $showingTestProfileSetup) {
                    NavigationView {
                        CreateProfileView()
                    }
                }
            }
            .background(AppColor.background)
            .edgesIgnoringSafeArea(.bottom)
        }
        .background(AppColor.background)
        .edgesIgnoringSafeArea(.all)
//        .navigationBarHidden(true)
    }
    
    private func validateFields() -> Bool {
        var isValid = true
        
        // Reset errors
        emailError = nil
        passwordError = nil
        loginError = nil
        
        // Validate email
        if email.isEmpty {
            emailError = "Email is required"
            isValid = false
        }
        
        // Validate password
        if password.isEmpty {
            passwordError = "Password is required"
            isValid = false
        }
        
        return isValid
    }
    
    private func handleLogin() {
        guard validateFields() else { return }
        
        isLoading = true
        Task {
            do {
                try await authService.signIn(email: email, password: password)
                isLoading = false
            } catch {
                await MainActor.run {
                    loginError = error.localizedDescription
                    authService.authError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
//            await authService.signInWithGoogle()
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {              
                if let nonce = currentNonce,
                   let identityToken = appleIDCredential.identityToken,
                   let tokenString = String(data: identityToken, encoding: .utf8) {
                    
                    isLoading = true
                    Task {
                        do {
                            try await authService.signInWithApple(
                                idToken: tokenString,
                                nonce: nonce,
                                isSignUp: false,
                                fullName: appleIDCredential.fullName,
                                email: appleIDCredential.email
                            )
                            isLoading = false
                        } catch {
                            print("❌ Error during Apple sign in: \(error)")
                            await MainActor.run {
                                isLoading = false
                                loginError = error.localizedDescription
                                authService.authError = error.localizedDescription
                            }
                        }
                    }
                }
            }
        case .failure(let error):
            print("❌ Apple sign in failed: \(error)")
            loginError = error.localizedDescription
            authService.authError = error.localizedDescription
        }
    }
}


