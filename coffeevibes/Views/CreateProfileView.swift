import SwiftUI
import PhotosUI
import Supabase
import UIKit
import Combine

extension UIImage {
    func toPngData() -> Data? {
        return self.pngData()
    }
}

// Add this struct before CreateProfileView
public struct CreateProfileView: View {
    @EnvironmentObject private var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = "12345"
    @State private var bio: String = ""
    @State private var selectedImage: UIImage?
    @State private var isImagePickerPresented = false
    @State private var notificationsEnabled = false
    @State private var selectedPreferences: Set<String> = []
    @State private var isLoading = false
    private let supabase = SupabaseConfig.client
    @State private var uploadError: String?
    @State private var userId: UUID?
    @State private var isLoadingUserData = false
//    @State private var shouldNavigateToHome = false
    
    let preferences = [
        "Quiet spots",
        "WiFi-ready cafes",
        "Outdoor seating",
        "Group hangouts"
    ]
    
    private struct ProfileUpdateData: Encodable {
        let name: String
        let bio: String
        let preferred_vibes: String
        let is_notifications_enabled: String
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Header
                Text("Create Your CoffeeMe Profile")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1612"))
                    .multilineTextAlignment(.center)
                    
                
                Text("Let's customize your experience to\nmatch your vibe.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "6A6A6A"))
                    .multilineTextAlignment(.center)
                
                // Profile Image Button
                Button(action: { isImagePickerPresented = true }) {
                    ZStack {
                        if let image = selectedImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 120, height: 120)
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80)
                                .foregroundColor(.gray)
                        }
                        
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(AppColor.primary)
                            .background(Circle().fill(.white))
                            .offset(x: 40, y: 40)
                    }
                }
                .sheet(isPresented: $isImagePickerPresented) {
                    ImagePicker(selectedImage: $selectedImage)
                }
                
                Text("Add a profile picture")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "1D1612"))
                
                // Name Field
                VStack(alignment: .leading) {
                    Text("Name")
                        .foregroundColor(Color(hex: "1D1612"))
                        .font(.system(size: 14, weight: .semibold))
                    TextField("Enter your name", text: $name)
                        .textFieldStyle(RoundedTextFieldStyle())
                        .disabled(isLoadingUserData)
                        .overlay(
                            isLoadingUserData ? 
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .padding(.trailing, 8)
                                .frame(maxWidth: .infinity, alignment: .center) : nil
                        )
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
                
                // Notifications Toggle
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.brown)
                        .padding(12)
                        .background(Color.brown.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text("Notifications")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(hex: "1D1612"))
                        Text("Receive updates about new coffee shops near you.")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(Color(hex: "6A6A6A"))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationsEnabled)
                        .tint(AppColor.primary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                
                // Preferences Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Pick Your Preferences")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color(hex: "1D1612"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
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
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Save Button
                Button(action: saveProfile) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Save Profile and Start Exploring")
                                .font(.headline)
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 24)
            }
            .padding()
        }
        .background(AppColor.background)
        .navigationBarBackButtonHidden()
        .onAppear {
            print("🔍 CreateProfileView appeared")
            print("🔍 Current authService.currentUser?.id: \(authService.currentUser?.id.uuidString ?? "nil")")
            userId = authService.currentUser?.id
            print("🔍 Set userId to: \(userId?.uuidString ?? "nil")")
            guard let userName = UserDefaults.standard.string(forKey: "pending_user_name") else { return }
            name = userName
        }
        .onChange(of: notificationsEnabled) { newValue in
            if newValue {
                allowNotification()
            }
        }
    }
    
    func allowNotification() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
            getNotificationSettings()
            if !success {
                // Handle case where permission was denied
                DispatchQueue.main.async {
                    self.notificationsEnabled = false
                }
            }
        }
    }
    
    private func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    private func uploadProfilePhoto() async throws -> String? {
        guard let image = selectedImage,
              let imageData = image.toPngData() else {
            return nil
        }
        
        let fileName = "\(UUID().uuidString).png"
        let filePath = "profile-photos/\(fileName)"
        
        do {
            let result = try await supabase.storage
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
            print("publicUrl: \(publicURL.absoluteString)")
            return publicURL.absoluteString
            
        } catch {
            print("Error uploading profile photo: \(error)")
            throw error
        }
    }
    
    private func saveProfile() {
        guard !name.isEmpty else {
            uploadError = "Name is required"
            return
        }
        
        isLoading = true
        
        Task {
            do {
                print("🔍 Starting profile save...")
                print("🔍 Current user ID: \(userId?.uuidString ?? "nil")")
                print("🔍 Name to save: \(name)")
                
                // Convert preferences to array string
                let arrayString = "{" + Array(selectedPreferences).map { "\"\($0)\"" }.joined(separator: ",") + "}"
                print("🔍 Preferences to save: \(arrayString)")

                // Create properly typed update data
                let updateData = ProfileUpdateData(
                    name: name,
                    bio: bio,
                    preferred_vibes: arrayString,
                    is_notifications_enabled: String(notificationsEnabled)
                )
                print("🔍 Update data prepared: \(updateData)")

                // Save profile data to Supabase
                let response = try await supabase.database
                    .from("user_profiles")
                    .update(updateData)
                    .eq("user_id", value: userId?.uuidString ?? "")
                    .execute()
                
                print("🔍 Supabase response: \(response)")
                
                await MainActor.run {
                    isLoading = false
                    print("✅ Profile updated successfully")
                    UserDefaults.standard.set(true, forKey: "registration_complete")
                    authService.registrationComplete = true
                }
            } catch {
                print("❌ Error saving profile: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                if let supabaseError = error as? PostgrestError {
                    print("❌ Supabase error code: \(supabaseError.code ?? "none")")
                    print("❌ Supabase error message: \(supabaseError.message)")
                }
                
                await MainActor.run {
                    isLoading = false
                    uploadError = error.localizedDescription
                }
            }
        }
    }
}

struct PreferenceButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColor.primary : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .black)
                .cornerRadius(20)
        }
    }
}

struct FlowLayout: Layout {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    
    init(spacing: CGFloat, alignment: HorizontalAlignment = .center) {
        self.spacing = spacing
        self.alignment = alignment
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        
        // Break down the width calculation into separate variables
        var maxWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for row in rows {
            let rowWidth = row.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width }
            let rowHeight = row.first?.sizeThatFits(.unspecified).height ?? 0
            
            maxWidth = max(maxWidth, rowWidth + CGFloat(row.count - 1) * spacing)
            totalHeight += rowHeight
        }
        
        return CGSize(width: maxWidth, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            let rowHeight = row.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            
            for subview in row {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
                x += size.width + spacing
            }
            
            y += rowHeight + spacing
        }
    }
    
    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[LayoutSubview]] {
        var rows: [[LayoutSubview]] = [[]]
        var currentRow = 0
        var x: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if x + size.width > (proposal.width ?? .infinity) {
                currentRow += 1
                rows.append([])
                x = size.width + spacing
            } else {
                x += size.width + spacing
            }
            
            rows[currentRow].append(subview)
        }
        
        return rows
    }
}

struct ImagePicker: View {
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showCamera = false
    
    var body: some View {
        List {
            Button(action: { showCamera = true }) {
                Label("Take Photo", systemImage: "camera")
            }
            
            PhotosPicker(selection: $photosPickerItem,
                        matching: .images) {
                Label("Choose from Library", systemImage: "photo.on.rectangle")
            }
        }
        .onChange(of: photosPickerItem) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImage = image
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(selectedImage: $selectedImage, isPresented: $showCamera)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.isPresented = false
            // Dismiss the ImagePicker sheet after camera capture
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(name: NSNotification.Name("DismissImagePicker"), object: nil)
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

