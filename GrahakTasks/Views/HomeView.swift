import SwiftUI

struct HomeView: View {
    @StateObject private var auth = AuthStore()
    var body: some View {
        TabView {

            TaskListView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .task {
            await NotificationManager.shared.requestPermission()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}


