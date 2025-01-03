import SwiftUI
import PhotosUI
import Supabase

struct CheckInSheet: View {
    let coffeeShop: CoffeeShop
    @Binding var isPresented: Bool
    var onCheckInComplete: () -> Void
    
    @State private var note: String = ""
    @State private var selectedMood: CheckInMood = .relaxed
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    @EnvironmentObject private var authService: AuthenticationService
    @StateObject private var coffeeShopService = CoffeeShopService()
    @StateObject private var storageService = StorageService()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How are you feeling?")
                            .font(.headline)
                        
                        HStack(spacing: 12) {
                            ForEach(CheckInMood.allCases, id: \.self) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: selectedMood == mood,
                                    action: { selectedMood = mood }
                                )
                            }
                        }
                    }
                    
                    // Photo Picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a photo")
                            .font(.headline)
                        
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            if let data = selectedPhotoData,
                               let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 200)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(.gray)
                                    )
                            }
                        }
                        .onChange(of: selectedItem) { _ in
                            Task {
                                if let data = try? await selectedItem?.loadTransferable(type: Data.self) {
                                    selectedPhotoData = data
                                }
                            }
                        }
                    }
                    
                    // Note Field
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add a note")
                            .font(.headline)
                        
                        TextEditor(text: $note)
                            .frame(height: 100)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Check In Button
                    Button(action: submitCheckIn) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                            Text(isSubmitting ? "Checking in..." : "Check In")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColor.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting)
                }
                .padding()
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func submitCheckIn() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "Please log in to check in"
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                // First upload the photo if exists
                var photoUrl: String?
                if let photoData = selectedPhotoData {
                    photoUrl = try await uploadPhoto(photoData)
                }
                
                let checkIn = CheckIn(
                    shopId: coffeeShop.id,
                    note: note.isEmpty ? nil : note,
                    photoUrl: photoUrl,
                    mood: selectedMood,
                    checkedInAt: Date()
                )
                
                try await coffeeShopService.checkIn(
                    to: coffeeShop.id,
                    userId: userId.uuidString,
                    checkIn: checkIn
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onCheckInComplete()
                    isPresented = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSubmitting = false
                }
            }
        }
    }
    
    private func uploadPhoto(_ data: Data) async throws -> String {
        guard let compressedData = UIImage(data: data)?
            .jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImageData
        }
        
        guard let userId = authService.currentUser?.id else {
            throw StorageError.invalidResponse
        }
        
        return try await storageService.uploadCheckInPhoto(
            imageData: compressedData,
            userId: userId.uuidString,
            shopId: coffeeShop.id
        )
    }
}

struct MoodButton: View {
    let mood: CheckInMood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: moodIcon(for: mood))
                    .font(.system(size: 24))
                Text(mood.rawValue.capitalized)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? AppColor.primary : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
    }
    
    private func moodIcon(for mood: CheckInMood) -> String {
        switch mood {
        case .productive: return "briefcase.fill"
        case .relaxed: return "cup.and.saucer.fill"
        case .social: return "person.2.fill"
        case .focused: return "brain.head.profile"
        case .creative: return "paintbrush.fill"
        }
    }
} 