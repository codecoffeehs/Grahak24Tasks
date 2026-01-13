import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @EnvironmentObject var auth: AuthStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {

        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome back")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue")
                        .font(.callout)
                        .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .padding(.vertical, 10)
                    .textInputAutocapitalization(.never)

                SecureField("Password", text: $password)
                    .padding(.vertical, 10)
            }
            
            // Primary Button
            PrimaryActionButton(title:"Log In",isLoading: auth.isLoading,isDisabled: email.isEmpty || password.isEmpty || auth.isLoading){
                await auth.login(email: email, password: password)
            }

            // Navigation
            NavigationLink {
                SignupView()
            } label: {
                Text("Don’t have an account? Sign up")
                    .font(.footnote)
                    .foregroundStyle(Color.blue)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)
        .background(
            Color(.systemBackground).ignoresSafeArea()
        )

        .overlay(alignment: .topLeading) {
            ZStack {
                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.orange.opacity(0.10), lineWidth: 1)
                    .frame(width: 460, height: 320)
                    .rotationEffect(.degrees(-18))

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.primary.opacity(0.07), lineWidth: 1)
                    .frame(width: 420, height: 290)
                    .rotationEffect(.degrees(-18))

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                    .frame(width: 380, height: 260)
                    .rotationEffect(.degrees(-18))
            }
            .offset(x: -180, y: -140)
            .allowsHitTesting(false)
        }



        .overlay(alignment: .bottomTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 90, style: .continuous)
                    .fill(Color.orange.opacity(0.04))
                    .frame(width: 360, height: 240)
                    .rotationEffect(.degrees(14))

                RoundedRectangle(cornerRadius: 70, style: .continuous)
                    .fill(Color.primary.opacity(0.025))
                    .frame(width: 300, height: 200)
                    .rotationEffect(.degrees(8))
            }
            .offset(x: 160, y: 140)
            .allowsHitTesting(false)
        }


        

        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Couldn't sign in")
        }
    }
}

#Preview {
   LoginView()
        .environmentObject(AuthStore())
}
