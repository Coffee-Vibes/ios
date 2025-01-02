struct ProfileView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    // ... other content
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CommonStyles.colors.background)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Profile")
            .foregroundColor(CommonStyles.colors.text)
        }
    }
} 