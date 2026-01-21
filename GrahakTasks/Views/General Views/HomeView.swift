import SwiftUI

struct HomeView: View {
    @StateObject private var auth = AuthStore()
    var body: some View {
        TabView {
            // Home
            TaskListView()
                .tabItem {
                    Image(systemName: "house.fill")
                }

            // Categories
            CategoryView()
                .tabItem {
                    Image(systemName: "folder.fill")
                }

            // Requests
            RequestView()
                .tabItem {
                    Image(systemName: "tray.full")
                }

            // Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                }
        }
        .task {
            await NotificationManager.shared.requestPermission()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
