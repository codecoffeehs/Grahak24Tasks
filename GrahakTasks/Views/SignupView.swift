import SwiftUI

struct SignupView: View {
    @State private var fullName = ""
    @State private var username = ""
    @State private var password = ""

    @EnvironmentObject var auth: AuthStore

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 32) {

                // Header
                VStack(spacing: 8) {
                    Text("Create account")
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    Text("Start organizing your tasks")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)

                // Fields
                VStack(spacing: 16) {
                    TextField("Full name", text: $fullName)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)

                    TextField("Username", text: $username)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                        .autocapitalization(.none)

                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(14)
                }

                // Button
                Button {
                    Task {
                        await auth.signup(
                            fullName: fullName,
                            username: username,
                            password: password
                        )
                    }
                } label: {
                    if auth.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign Up")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .buttonStyle(.glassProminent)
                .disabled(!FormValid.isValid(username: username, password: password, isLoading: auth.isLoading))
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: 420)

            Spacer()
        }
        // 🔴 Error Alert
        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Could'nt Sign Up")
        }
    }
}
