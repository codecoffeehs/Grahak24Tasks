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

            // Requests (currently still using SharedView until you rename it to RequestsView)
            RequestView()
                .tabItem {
                    Image(systemName: "tray.full")
                }

            // Profile
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                }

//            Tab(role: .search){
//                SearchView()
//            }
        }
        .task {
            await NotificationManager.shared.requestPermission()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
