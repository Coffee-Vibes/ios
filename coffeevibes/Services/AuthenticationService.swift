import Foundation
import Supabase
import AuthenticationServices

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
    
    func signInWithApple(idToken: String, nonce: String, fullName: PersonNameComponents? = nil, email: String? = nil) async throws {
        do {
            let response = try await supabase.auth.signInWithIdToken(
                credentials: .init(
                    provider: .apple,
                    idToken: idToken,
                    nonce: nonce
                )
            )
           
            // Check if user_profiles record exists
            let existingProfile = try? await supabase
                .from("user_profiles")
                .select()
                .eq("user_id", value: response.user.id)
                .single()
                .execute()
            
            if existingProfile == nil {
                // Create new profile with default name
                let userRecord = UserRecord(
                    id: response.user.id,
                    email: response.user.email ?? "",
                    name: "Coffee Lover", // Default name that user can update later
                    created_at: ISO8601DateFormatter().string(from: Date())
                )

                do {
                    let insertResponse = try await supabase
                        .from("user_profiles")
                        .insert(userRecord)
                        .execute()
                } catch {
                    print("❌ Error creating user profile: \(error)")
                    // Continue with sign in even if profile creation fails
                }
            } else {
                print("🍎 Existing profile found, skipping profile creation")
            }
            
            self.currentUser = response.user
            self.registrationComplete = true
            UserDefaults.standard.set(true, forKey: "registration_complete")
            
            KeychainService.shared.saveToken(response.accessToken)
         } catch {
            print("❌ Error during Apple Sign In: \(error)")
            throw error
        }
    }
} 
