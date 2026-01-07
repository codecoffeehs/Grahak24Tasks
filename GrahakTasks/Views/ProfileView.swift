import SwiftUI

struct ProfileView: View {

    @EnvironmentObject var auth: AuthStore

    // Read once from Keychain (simple & fine for now)
    private let fullName = KeychainService.read(key: "fullName") ?? "User"
    
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack {
            Form {

                // MARK: - Header
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.secondary)

                        Text(fullName)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                .listRowBackground(Color.clear)

                // MARK: - Preferences
                Section {
                    Label("Privacy Policy", systemImage: "lock.shield")
                    Label("Support", systemImage: "questionmark.circle")
                }

                // MARK: - Logout
                Section {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Text("Log Out")
                    }
                }
            }
            .alert("Log Out?",isPresented: $showLogoutConfirmation){
                Button("Yes",role: .destructive){
                    auth.logout()
                }
                Button("Cancel",role: .cancel){}
            } message: {
                Text("You Can Login Anytime")
            }

            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
