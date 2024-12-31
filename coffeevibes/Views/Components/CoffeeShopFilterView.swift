import SwiftUI

struct CoffeeShopFilterView: View {
    @Environment(\.dismiss) var dismiss
    @State private var distance: Double
    @State private var useLocation = true
    @State private var showOpenOnly = true
    @State private var selectedVibes: Set<String> = ["Good Vibes"]
    let onApplyFilters: (Double) -> Void
    
    // Add initializer to set initial state
    init(initialDistance: Double, onApplyFilters: @escaping (Double) -> Void) {
        _distance = State(initialValue: initialDistance)
        self.onApplyFilters = onApplyFilters
    }
    
    let vibes = [
        "Quiet", "Good Vibes", "Outdoor Seating",
        "Has WiFi", "Study-Friendly", "Crowded"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Pull indicator
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .cornerRadius(2)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title
                        Text("Refine Your Search")
                            .t1Style()
                            .padding(.horizontal)
                        
                        // Location Section
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Search near your location")
                                    .t1Style()
                                Spacer()
                                Toggle("", isOn: $useLocation)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5D4037")))
                                    .labelsHidden()
                            }
                            
                            Text("Use My Location")
                                .t2Style()
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Vibes Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Vibes")
                                  .t1Style()
                            
                            FlowLayout(spacing: 8, alignment: .leading) {
                                ForEach(vibes, id: \.self) { vibe in
                                    Button(action: {
                                        if selectedVibes.contains(vibe) {
                                            selectedVibes.remove(vibe)
                                        } else {
                                            selectedVibes.insert(vibe)
                                        }
                                    }) {
                                        Text(vibe)
                                            .font(.subheadline)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(selectedVibes.contains(vibe) ? Color(hex: "5D4037") : Color(hex: "F4F4F4"))
                                            .foregroundColor(selectedVibes.contains(vibe) ? .white : .black)
                                            .cornerRadius(20)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Distance Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Distance")
                                  .t1Style()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("\(Int(distance)) mile\(distance == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $distance, in: 1...20)
                                    .tint(Color(hex: "5D4037"))
                            }
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                        
                        // Open Now Toggle
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Open Now")
                                    .t1Style()
                                Spacer()
                                Toggle("", isOn: $showOpenOnly)
                                    .toggleStyle(SwitchToggleStyle(tint: Color(hex: "5D4037")))
                                    .labelsHidden()
                            }
                            
                            Text("Only show open shops")
                                .t2Style()
                        }
                        .padding(.horizontal)
                        
                        Divider()
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 24)
                }
                
                // Action Buttons in fixed position
                VStack(spacing: 16) {
                    Divider()
                    
                    HStack(spacing: 16) {
                        Button("Reset") {
                            selectedVibes.removeAll()
                            distance = 5.0
                            useLocation = true
                            showOpenOnly = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.white)
                        .foregroundColor(AppColor.primary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppColor.primary, lineWidth: 1)
                        )
                        
                        Button("Apply filter") {
                            onApplyFilters(distance)
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColor.primary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
                .background(Color(hex: "FAF7F4"))
            }
            .background(Color(hex: "FAF7F4"))
            .navigationBarHidden(true)
        }
        .presentationDetents([.height(620)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(30)
        .presentationBackground {
            Color(hex: "FAF7F4")
                .cornerRadius(20)
        }
    }
} 
