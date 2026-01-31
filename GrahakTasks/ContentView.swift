//
//  ContentView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 06/01/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth: AuthStore
    @EnvironmentObject var task: TaskStore
    @EnvironmentObject var category: CategoryStore

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    var body: some View {
        Group {
            if !hasSeenWelcome {
                WelcomeScreen()
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else if auth.isAuthenticated {
                HomeView()
                    .transition(.move(edge: .trailing))
            } else {
                NavigationStack {
                    LoginView()
                        .transition(.move(edge: .leading))
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: hasSeenWelcome)
        .animation(.easeInOut(duration: 0.35), value: auth.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStore.shared)   // Use the singleton so preview reflects the same instance
        .environmentObject(TaskStore())
        .environmentObject(CategoryStore())
}
