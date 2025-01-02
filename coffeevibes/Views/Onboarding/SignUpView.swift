import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    
    enum Event {
        case optCode(email: String)
        case back
    }
    
    @StateObject private var authService = AuthenticationService()
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isPasswordVisible = false
    @State private var agreedToTerms = false
    @State private var navigationPath = NavigationPath()
    
    @State private var nameError: String?
    @State private var emailError: String?
    @State private var passwordError: String?
    @State private var loginError: String?
    @State private var termsError = false
    @State private var currentNonce: String?
    let onEvent: (Event) -> Void
    
    var body: some View {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .center, spacing: 8) {
                    Image("logo")
                        .resizable()
                        .frame(width: 200, height: 200)                    
                    Text("Sign up to your account")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.black)
                    Text("Create your account now")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 40)
       
                
                // Sign Up Form
                VStack {
                    ScrollView {
                        VStack(spacing: 32) {
                            // Name/Email/Password Fields
                            VStack(alignment: .leading, spacing: 16) {
                                // Name Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Name")
                                        .foregroundColor(Color(hex: "1D1612"))
                                    TextField("Enter your name", text: $name)
                                        .textFieldStyle(RoundedTextFieldStyle(error: nameError != nil))
                                    if let error = nameError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                // Email Field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Email")
                                        .foregroundColor(Color(hex: "1D1612"))
                                    TextField("Enter your email", text: $email)
                                        .textFieldStyle(RoundedTextFieldStyle(error: emailError != nil))
                                        .textInputAutocapitalization(.never)
                                        .keyboardType(.emailAddress)
                                    if let error = emailError {
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                // Password Field
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
                            
                            // Terms and Conditions
                            Toggle(isOn: $agreedToTerms) {
                                HStack {
                                    Text("I agree with the")
                                        .foregroundColor(termsError ? .red : .gray)
                                    Button("Terms and Conditions") {
                                        // Handle terms and conditions
                                    }
                                    .foregroundColor(termsError ? .red : AppColor.primary)
                                }
                                .font(.system(size: 14, weight: .medium))
                            }
                            .toggleStyle(CheckboxToggleStyle(error: termsError))
                            
                            // Sign Up Button
                            Button(action: handleSignUp) {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign up")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(isLoading)
                            
                            if let error = loginError {
                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 8)
                            }
                            
                            // Social Login Options
                            VStack(spacing: 8) {
                                SignInWithAppleButton(.signUp) { request in
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
                                        Text("Continue with Google")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .buttonStyle(SocialButtonStyle())
                            }
                        }
                        .padding(24)
                    }
                    
                    Spacer()
                    
                    // Login Link
                    HStack {
                        Text("I have an account?")
                            .foregroundColor(.gray)
                        Button("Login") {
                            onEvent(.back)
                        }
                        .foregroundColor(AppColor.primary)
                    }
                    .font(.subheadline)
                    .padding(.bottom, 24)
                }
                .background(AppColor.background)
                .edgesIgnoringSafeArea(.bottom)
            }
            .background(AppColor.background)
            .edgesIgnoringSafeArea(.all)
            .navigationBarBackButtonHidden(true)
    }
    
    private func validateFields() -> Bool {
        var isValid = true
        
        // Reset errors
        nameError = nil
        emailError = nil
        passwordError = nil
        loginError = nil
        termsError = false
        
        // Validate name
        if name.isEmpty {
            nameError = "Name is required"
            isValid = false
        }
        
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
        
        // Validate terms agreement
        if !agreedToTerms {
            termsError = true
            isValid = false
        }
        
        return isValid
    }
    
    private func handleSignUp() {
        guard validateFields() else { return }
        
        isLoading = true
        
        Task {
            do {
                try await authService.signUp(
                    email: email,
                    password: password,
                    name: name
                )
                
                await MainActor.run {
                    isLoading = false
                    self.onEvent(.optCode(email: email))
                }
            } catch {
                await MainActor.run {
                    authService.authError = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            // Implement Google sign in
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
               let nonce = currentNonce,
               let identityToken = appleIDCredential.identityToken,
               let tokenString = String(data: identityToken, encoding: .utf8) {
                
                isLoading = true
                Task {
                    do {
                        let signInResult = try await authService.signInWithApple(
                            idToken: tokenString,
                            nonce: nonce,
                            isSignUp: true,
                            fullName: appleIDCredential.fullName,
                            email: appleIDCredential.email
                        )
                        
                        await MainActor.run {
                            isLoading = false
                            if authService.registrationComplete {
                                // User has profile, they're fully registered
                                UserDefaults.standard.set(true, forKey: "registration_complete")
                            } else {
                                // New user needs to verify email
                                self.onEvent(.optCode(email: signInResult.user.email ?? ""))
                            }
                        }
                    } catch {
                        await MainActor.run {
                            isLoading = false
                            loginError = error.localizedDescription
                            authService.authError = error.localizedDescription
                        }
                    }
                }
            }
        case .failure(let error):
            loginError = error.localizedDescription
            authService.authError = error.localizedDescription
        }
    }
} 
