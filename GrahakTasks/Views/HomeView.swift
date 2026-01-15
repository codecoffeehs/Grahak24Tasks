import SwiftUI

struct HomeView: View {
    @StateObject private var auth = AuthStore()
    var body: some View {
        TabView {
            Tab("Home",systemImage: "house.fill"){
                TaskListView()
            }
            Tab("Category",systemImage: "folder.fill"){
                CategoryView()
            }
            Tab("Shared",systemImage: "person.line.dotted.person"){
                SharedView()
            }
            Tab("Profile",systemImage: "person.fill"){
                ProfileView()
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


