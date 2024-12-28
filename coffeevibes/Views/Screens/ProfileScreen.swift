import SwiftUI
import Combine
import Supabase
import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @StateObject private var authService = AuthenticationService()
    @StateObject private var userService = UserService()
    @State private var userDetails: UserDetails?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedImage: UIImage?
    @State private var showingEditProfile = false
    @Environment(\.presentationMode) var presentationMode
    private let supabase = SupabaseConfig.client
    @State private var isFinish = false
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    ProfileHeader(userDetails: userDetails, isFinish: $isFinish)
                    SettingsSection()
                }
                .padding(10)
            }
            .background(Color(hex: "FAF7F4"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.headline)
                }
            }
            .onChange(of: isFinish) {
                if $1 {
                    Task {
                        fetchUserData()
                    }
                }
            }
            .onAppear {
                Task {
                    fetchUserData()
                }
            }
        }
    }
    
    private func fetchUserData() {
        guard let currentUserId = authService.currentUser?.id else {
            print("erorr fetchUserData")
            return
        }
        
        Task {
            do {
                let response: UserDetails = try await supabase.database
                    .from("user_profiles")
                    .select("*")
                    .eq("user_id", value: currentUserId)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    print("response \(response)")
                    userDetails = response
                    print("fetchUserData fetchUserData ")
                }
            } catch {
                print("Error fetching user data: \(error)")
            }
        }
    }
    
    private func handleLogout() {
        Task {
            do {
                try await authService.signOut()
                presentationMode.wrappedValue.dismiss()
            } catch {
                print("Logout failed: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Profile Components
struct ProfileHeader: View {
    var userDetails: UserDetails?
    @State var isImagePickerPresented: Bool = false
    @Binding var isFinish: Bool
    @State private var selectedImage: UIImage?
    private let supabase = SupabaseConfig.client
    @State private var reviewCount: Int = 0
    @State private var visitCount: Int = 0
    @State private var favoriteCount: Int = 0
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Image and Camera Button
            Button(action: {
                isFinish = false
                isImagePickerPresented = true
            }) {
                ZStack {
                    if let profilePhoto = userDetails?.profilePhoto,
                       let url = URL(string: profilePhoto) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.3)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color(hex: "B27046"))
                            .background(Circle().fill(.white))
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                    }
                    
                    Image(systemName: "camera.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(Color(hex: "B27046"))
                        .background(Circle().fill(.white))
                        .offset(x: 25, y: 25)
                }
            }
   
            
            // Name and Bio
            VStack(spacing: 4) {
                Text(userDetails?.name ?? "Alex Johnson")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1612"))
                
                Text(userDetails?.bio ?? "Coffee lover. Exploring one sip at\na time. Based in NYC")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(hex: "6A6A6A"))
                    .multilineTextAlignment(.center)
            }
            
            // Stats Row
            HStack(spacing: 10) {
                Spacer(minLength: .zero)
                StatItem(count: "\(reviewCount)+", title: "Awarded for\nwriting reviews")
                Divider().frame(height: 40)
                StatItem(count: "\(visitCount)+", title: "Visited coffee\nshops")
                Divider().frame(height: 40)
                StatItem(count: "\(favoriteCount)+", title: "Saved new\nfavorites")
                Spacer(minLength: .zero)
            }
            
            // Preferences Tags
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Preferences")
                    .font(.headline)
                if let preferredVibes = userDetails?.preferredVibes {
                    PreferenceTagsRow(tags: preferredVibes)
                } else {
                    HStack(spacing: 6) {
                        PreferenceTag(text: "Quiet spots", color: .mint)
                        PreferenceTag(text: "WiFi-ready cafes", color: .purple)
                        PreferenceTag(text: "Outdoor seating", color: .blue)
                        Spacer(minLength: .zero)
                    }
                }
            }
        }
        .padding(.horizontal)
        .sheet(isPresented: $isImagePickerPresented) {
            ImagePicker(selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage) { _ in
            if selectedImage != nil {
                saveProfile()
            }
        }
        .task {
            await fetchCounts()
        }
    }
    
    private func fetchCounts() async {
        guard let userId = userDetails?.userId else { return }
        
        do {
            // Fetch review count
            let reviewResponse = try await supabase.database
                .from("reviews")
                .select("""
                    count
                """)
                .eq("user_id", value: userId)
                .execute()
            
            if let countString = (try? reviewResponse.value as? [String: Int])?["count"] {
                reviewCount = countString
            }

            // Fetch visit count
            let visitResponse = try await supabase.database
                .from("visits")
                .select("""
                    count
                """)
                .eq("user_id", value: userId)
                .execute()
            
            if let countString = (try? visitResponse.value as? [String: Int])?["count"] {
                visitCount = countString
            }

            // Fetch favorites count
            let favoriteResponse = try await supabase.database
                .from("favorites")
                .select("""
                    count
                """)
                .eq("user_id", value: userId)
                .execute()
            
            if let countString = (try? favoriteResponse.value as? [String: Int])?["count"] {
                favoriteCount = countString
            }
            
        } catch {
            print("Error fetching counts: \(error)")
            // Keep the default values of 0 in case of error
        }
    }
    
    private func saveProfile() {
        Task {
            do {
                if let photoUrl = try await uploadProfilePhoto() {
                    // Save profile data to Supabase
                    try await supabase.database
                        .from("user_profiles")
                        .update(["profile_photo": photoUrl])
                        .eq("user_id", value: userDetails?.userId ?? "")
                        .execute()
                    
                    await MainActor.run {
                        UserDefaults.standard.set(true, forKey: "registration_complete")
                    }
                }
            } catch {
                print("Error uploading profile photo: \(error)")
            }
        }
    }
    
    private func uploadProfilePhoto() async throws -> String? {
        guard let image = selectedImage,
              let imageData = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        
        let fileName = "\(UUID().uuidString).jpg"
        let filePath = "profile-photos/\(fileName)"
        
        do {
            _ = try await supabase.storage
                .from("profile-photo-bucket")
                .upload(
                    path: filePath,
                    file: imageData,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: "image/png"
                    )
                )
            
            // Get the public URL for the uploaded image
            let publicURL = try supabase.storage
                .from("profile-photo-bucket")
                .getPublicURL(path: filePath)
            isFinish = true
            print("publicUrl: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            isFinish = false
            print("Error uploading profile photo: \(error)")
            throw error
        }
    }
}
        

struct PreferenceTagsRow: View {
    let tags: [String]
    let colors: [Color] = [.mint, .purple, .blue, .green, .orange, .pink]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Array(tags.enumerated()), id: \.element) { index, tag in
                    PreferenceTag(
                        text: tag,
                        color: colors[index % colors.count]
                    )
                }
                Spacer(minLength: .zero)
            }
        }
    }
}

struct PreferenceTag: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(16)
    }
}

struct StatsSection: View {
    var body: some View {
        HStack(spacing: 30) {
            StatItem(count: "25", title: "Visits")
            StatItem(count: "15", title: "Reviews")
            StatItem(count: "8", title: "Favorites")
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct StatItem: View {
    let count: String
    let title: String
    
    var body: some View {
        VStack {
            Text(count)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct AchievementsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Achievements")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    AchievementBadge(title: "Explorer", icon: "map.fill")
                    AchievementBadge(title: "Reviewer", icon: "star.fill")
                    AchievementBadge(title: "Early Bird", icon: "sunrise.fill")
                }
            }
        }
    }
}

struct AchievementBadge: View {
    let title: String
    let icon: String
    
    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.yellow)
            Text(title)
                .font(.caption)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(10)
    }
}

struct SettingsSection: View {
    @StateObject private var authService = AuthenticationService()
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(SettingItem.allCases, id: \.self) { item in
                if item == .logout {
                    // Special case for logout - use Button instead of NavigationLink
                    Button {
                        showingLogoutConfirmation = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .frame(width: 24)
                                .foregroundColor(.black)
                            Text(item.rawValue)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: "6A6A6A"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(Color.white)
                    }
                } else {
                    NavigationLink {
                        if item == .promotions {
                            PromotionsView()
                                .navigationBarBackButtonHidden()
                        } else if item == .editProfile {
                            EditProfileView()
                                .navigationBarBackButtonHidden()
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: item.icon)
                                .frame(width: 24)
                                .foregroundColor(.black)
                            Text(item.rawValue)
                                .foregroundColor(.black)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: "6A6A6A"))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(Color.white)
                    }
                }
            }
        }
        .background(Color(hex: "F2F4F7"))
        .cornerRadius(12)
        .padding(.horizontal, 16)
        .confirmationDialog(
            "Are you sure you want to log out?",
            isPresented: $showingLogoutConfirmation,
            titleVisibility: .visible
        ) {
            Button("Log Out", role: .destructive) {
                Task {
                    try? await authService.signOut()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

enum SettingItem: String, CaseIterable {
    case promotions = "Promotions & Loyalty"
    case editProfile = "Edit profile"
    case feedback = "Feedback"
    case settings = "App Settings"
    case terms = "Terms and conditions"
    case logout = "Log Out"
    
    var icon: String {
        switch self {
        case .promotions: return "ticket"
        case .editProfile: return "pencil.line"
        case .feedback: return "headphones"
        case .settings: return "gearshape"
        case .terms: return "doc.text"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService()
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var selectedPreferences: Set<String> = []
    @State private var isLoading = false
    private let supabase = SupabaseConfig.client
    
    let preferences = [
        "Quiet spots",
        "WiFi-ready cafes",
        "Outdoor seating",
        "Group hangouts"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Name Field
                VStack(alignment: .leading) {
                    Text("Name")
                        .foregroundColor(Color(hex: "1D1612"))
                        .font(.system(size: 14, weight: .semibold))
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(RoundedTextFieldStyle())
                }
                
                // Bio Field
                VStack(alignment: .leading) {
                    Text("Bio")
                        .foregroundColor(Color(hex: "1D1612"))
                        .font(.system(size: 14, weight: .semibold))
                    TextEditor(text: $bio)
                        .frame(height: 80)
                        .padding(8)
                        .background(Color.white)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                }
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Preferences")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1612"))
                    
                    FlowLayout(spacing: 8, alignment: .leading) {
                        ForEach(preferences, id: \.self) { preference in
                            PreferenceButton(
                                title: preference,
                                isSelected: selectedPreferences.contains(preference),
                                action: {
                                    if selectedPreferences.contains(preference) {
                                        selectedPreferences.remove(preference)
                                    } else {
                                        selectedPreferences.insert(preference)
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .padding()
        }
        .background(AppColor.background)
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: saveProfile) {
                    if isLoading {
                        ProgressView()
                    } else {
                        Text("Save")
                    }
                }
            }
        }
        .onAppear {
            loadUserData()
        }
    }
    
    private func loadUserData() {
        guard let currentUserId = authService.currentUser?.id else { return }
        
        Task {
            do {
                let response: UserDetails = try await supabase.database
                    .from("user_profiles")
                    .select("*")
                    .eq("user_id", value: currentUserId)
                    .single()
                    .execute()
                    .value
                
                await MainActor.run {
                    name = response.name ?? ""
                    bio = response.bio ?? ""
                    if let vibes = response.preferredVibes {
                        selectedPreferences = Set(vibes)
                    }
                }
            } catch {
                print("Error loading user data: \(error)")
            }
        }
    }
    
    private func saveProfile() {
        guard let currentUserId = authService.currentUser?.id else { return }
        isLoading = true
        
        Task {
            do {
                let arrayString = "{" + Array(selectedPreferences).map { "\"\($0)\"" }.joined(separator: ",") + "}"
                
                try await supabase.database
                    .from("user_profiles")
                    .update([
                        "name": name,
                        "bio": bio,
                        "preferred_vibes": arrayString
                    ])
                    .eq("user_id", value: currentUserId)
                    .execute()
                
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                print("Error saving profile: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
