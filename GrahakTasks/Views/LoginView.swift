import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @EnvironmentObject var auth : AuthStore
    var body: some View {
        VStack {
//            # Mark -- Added
            Spacer()
            VStack(spacing: 32) {

                // Header
                VStack(spacing: 8) {
                    Text("Welcome back")
                        .font(.largeTitle)
                        .fontWeight(.semibold)

                    Text("Sign in to continue")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)

                // Fields
                VStack(spacing: 16) {
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
                        await auth.login(username: username, password: password)
                    }
                } label: {
                    if auth.isLoading {
                        ProgressView()
                    } else {
                        Text("Log In")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .cornerRadius(14)
                    }
                }
                .disabled(
                    username.isEmpty ||
                    password.isEmpty ||
                    auth.isLoading
                )
                .buttonStyle(.glassProminent)


                // Navigation
                NavigationLink {
                    SignupView()
                } label: {
                    Text("Don’t have an account? Sign up")
                        .font(.footnote)
                        .foregroundColor(.blue)
                }
            }
            
            .padding(.horizontal, 24)
            .frame(maxWidth: 420)

            Spacer()
        }
        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Could'nt Sign Up")
        }
    }
}

