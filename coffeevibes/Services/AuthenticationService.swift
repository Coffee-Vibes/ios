import Foundation
import Supabase
import AuthenticationServices
import CryptoKit

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var registrationComplete = false
    
    private let supabase = SupabaseConfig.client
    private let userService = UserService()
    
    // Replace @AppStorage with a simple UserDefaults check
    private var hasCompletedAppleSignIn: Bool {
        get { UserDefaults.standard.bool(forKey: "hasCompletedAppleSignIn") }
        set { UserDefaults.standard.set(newValue, forKey: "hasCompletedAppleSignIn") }
    }
    
    init() {
        setupAuthStateListener()
        checkCurrentSession()                            
        let registrationComplete = UserDefaults.standard.bool(forKey: "registration_complete")
        self.registrationComplete = registrationComplete
    }
    
    private func checkCurrentSession() {
        if let session = supabase.auth.currentSession {
            self.currentUser = session.user
            if !session.accessToken.isEmpty {
                KeychainService.shared.saveToken(session.accessToken)
            }
        }
    }
    
    private func setupAuthStateListener() {
        Task { @MainActor in
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn:
                    self.currentUser = session?.user
                    if let accessToken = session?.accessToken, !accessToken.isEmpty {
                        KeychainService.shared.saveToken(accessToken)
                    }
                    self.registrationComplete = UserDefaults.standard.bool(forKey: "registration_complete")
                case .signedOut:
                    self.currentUser = nil
                    self.registrationComplete = false
                    UserDefaults.standard.set(false, forKey: "registration_complete")
                    KeychainService.shared.deleteToken()
                default:
                    break
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let result = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        self.currentUser = result.user
        self.registrationComplete = true
        UserDefaults.standard.set(true, forKey: "registration_complete")
        
        if !result.accessToken.isEmpty {
            KeychainService.shared.saveToken(result.accessToken)
        }
    }
    
    // Add this struct at the top of the file or in a separate User model file
    struct UserRecord: Codable {
        let id: UUID
        let email: String
        let name: String
        let created_at: String
        
        enum CodingKeys: String, CodingKey {
            case id = "user_id"  // Map 'id' to 'user_id' in the database
            case email
            case name
            case created_at
        }
    }
    
    // Update the signUp method
    func signUp(email: String, password: String, name: String) async throws {
        do {
            // 1. Create the auth user first
            let signUpResult = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(name)]
            )
            
            let user = signUpResult.user
            // 2. Store info for OTP verification and profile creation
            UserDefaults.standard.set(email, forKey: "pending_user_email")
            UserDefaults.standard.set(name, forKey: "pending_user_name")
            UserDefaults.standard.set(password, forKey: "pending_user_password")
            
            // 3. Send OTP email for verification
            try await supabase.auth.signInWithOTP(
                email: email,
                shouldCreateUser: false // Important: set to false since user already exists
            )
            
            self.registrationComplete = false
        } catch {
            print("❌ Error during sign up: \(error)")  // Add error logging
            throw error
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        self.currentUser = nil
        self.registrationComplete = false
        KeychainService.shared.deleteToken() // Delete token on sign out
    }
    
    func fetchUserDetails(email: String) async throws -> UserDetails {
        let userDetails = try await userService.fetchUserDetails(email: email)
        return userDetails
    }
    
    var isUserLoggedIn: Bool {
        if currentUser != nil {
            return registrationComplete
        } else {
            return false
        }
    }
    
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    // Then verify OTP and complete profile creation
    func verifyOTP(email: String, token: String) async throws {
        let result = try await supabase.auth.verifyOTP(
            email: email,
            token: token,
            type: .email
        )
        
        if let user = result.session?.user {
            // Create user record in user_profiles table
            let userRecord = UserRecord(
                id: user.id,
                email: email,
                name: UserDefaults.standard.string(forKey: "pending_user_name") ?? "",
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("user_profiles")
                .insert(userRecord)
                .execute()
            
            // Update current user and save token
            self.currentUser = user
            self.registrationComplete = false
            
            if let session = result.session {
                KeychainService.shared.saveToken(session.accessToken)
            }
        }
    }
    
    func resendOTP(email: String) async throws {
        try await supabase.auth.signInWithOTP(
            email: email,
            shouldCreateUser: true
        )
    }
    
    struct AuthResponse {
        let user: User
        let session: Session
        
        init(session: Session) {
            self.user = session.user
            self.session = session
        }
    }
    
    func signInWithApple(idToken: String, nonce: String, isSignUp: Bool, fullName: PersonNameComponents? = nil, email: String? = nil) async throws -> AuthResponse {
        do {
            let session = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
            
            self.currentUser = session.user
            
            // Check if user has a profile
            let hasProfile = try await checkUserProfileExists(userId: session.user.id)
            print("🍎 hasProfile \(hasProfile)")
            
            if !hasProfile {
                // This is a new user (sign up flow)
                // Store info for profile creation using Supabase user's email
                UserDefaults.standard.set(session.user.email, forKey: "pending_user_email")
                
                // Get name from Apple credentials or use default
                let userName = if let givenName = fullName?.givenName,
                                let familyName = fullName?.familyName {
                    "\(givenName) \(familyName)"
                } else {
                    "Coffee Lover"
                }
                UserDefaults.standard.set(userName, forKey: "pending_user_name")
                
                // Set registration as incomplete since profile needs to be created
                self.registrationComplete = false
                UserDefaults.standard.set(false, forKey: "registration_complete")
                
                if (isSignUp) {
                    // Send OTP verification email using Supabase user's email
                    if let userEmail = session.user.email {
                        try await supabase.auth.signInWithOTP(
                            email: userEmail,
                            shouldCreateUser: false
                        )
                }
                }
            } else {
                // Existing user (sign in flow)
                self.registrationComplete = true
                UserDefaults.standard.set(true, forKey: "registration_complete")
            }
            
            KeychainService.shared.saveToken(session.accessToken)
            return AuthResponse(session: session)
        } catch {
            print("❌ Error during Apple Sign In: \(error)")
            throw error
        }
    }
    
    func generateNonce(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
    
    func checkUserProfileExists(userId: UUID) async throws -> Bool {
        do {
            let response = try await supabase
                .from("user_profiles")
                .select("user_id")  // Only select what we need
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            // Check if we got any results
            if let count = response.count {
                return count > 0
            }
            print("❌ No user profile found for user \(userId)")
            return false
        } catch {
            print("❌ Error checking user profile: \(error)")
            throw error
        }
    }
} 
