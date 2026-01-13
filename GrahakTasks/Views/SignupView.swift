import SwiftUI

struct SignupView: View {
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""

    @EnvironmentObject var auth: AuthStore
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {

        VStack(spacing: 24) {
            Spacer()

            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Create account")
                    .font(.largeTitle.bold())

                Text("Start organizing your tasks")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Fields
            VStack(spacing: 16) {
                TextField("Full name", text: $fullName)
                    .padding(.vertical, 10)

                TextField("Email", text: $email)
                    .padding(.vertical, 10)
                    .textInputAutocapitalization(.never)

                SecureField("Password", text: $password)
                    .padding(.vertical, 10)
            }

            //Primary Button
            PrimaryActionButton(title:"Sign Up",isLoading: auth.isLoading,isDisabled: email.isEmpty || password.isEmpty || fullName.isEmpty || auth.isLoading){
                await auth.signup(fullName: fullName, email: email, password: password)
            }

            // Navigation
            NavigationLink {
                LoginView()
            } label: {
                Text("Already have an account? Log in")
                    .font(.footnote)
                    .foregroundStyle(Color.blue)
            }

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: 420)

        // Background
        .background(
            Color(.systemBackground).ignoresSafeArea()
        )

        .overlay(alignment: .topTrailing) {
            ZStack {
                RoundedRectangle(cornerRadius: 130, style: .continuous)
                    .stroke(Color.orange.opacity(0.08), lineWidth: 1)
                    .frame(width: 480, height: 340)
                    .rotationEffect(.degrees(14))

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    .frame(width: 440, height: 310)
                    .rotationEffect(.degrees(14))

                RoundedRectangle(cornerRadius: 110, style: .continuous)
                    .stroke(Color.primary.opacity(0.035), lineWidth: 1)
                    .frame(width: 400, height: 280)
                    .rotationEffect(.degrees(14))
            }
            .offset(x: 200, y: -120)
            .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomLeading) {
            ZStack {
                RoundedRectangle(cornerRadius: 100, style: .continuous)
                    .fill(Color.orange.opacity(0.035))
                    .frame(width: 420, height: 260)
                    .rotationEffect(.degrees(-8))

                RoundedRectangle(cornerRadius: 80, style: .continuous)
                    .fill(Color.primary.opacity(0.02))
                    .frame(width: 340, height: 210)
                    .rotationEffect(.degrees(-4))
            }
            .offset(x: -180, y: 160)
            .allowsHitTesting(false)
        }


        .alert("Error", isPresented: $auth.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(auth.errorMessage ?? "Couldn't sign up")
        }
    }
}
#Preview{
    SignupView().environmentObject(AuthStore())
}
