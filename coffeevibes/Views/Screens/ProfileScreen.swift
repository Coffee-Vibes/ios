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
                StatItem(count: "10+", title: "Awarded for\nwriting reviews")
                Divider().frame(height: 40)
                StatItem(count: "24+", title: "Visited coffee\nshops")
                Divider().frame(height: 40)
                StatItem(count: "5+", title: "Saved new\nfavorites")
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
    
    var body: some View {
        VStack(spacing: 1) {
            ForEach(SettingItem.allCases, id: \.self) { item in
                if item == .logout {
                    // Special case for logout - use Button instead of NavigationLink
                    Button {
                        Task {
                            try? await authService.signOut()
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
                } else {
                    NavigationLink {
                        if item == .promotions {
                            PromotionsView()
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
    @State private var name = ""
    @State private var bio = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Information")) {
                    TextField("Name", text: $name)
                    TextField("Bio", text: $bio)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Save profile changes
                        dismiss()
                    }
                }
            }
        }
    }
}
