import SwiftUI

struct HomeView: View {
    @StateObject private var auth = AuthStore()
    var body: some View {
        TabView {
            Tab("Home",systemImage: "house"){
                TaskListView()
            }
            Tab("Collab",systemImage: "person.line.dotted.person"){
                CollaboratorView()
            }
            Tab("Categories",systemImage: "folder.fill"){
                CategoryView()
            }
            Tab("Profile",systemImage: "person"){
                ProfileView()
            }
            
            Tab(role: .search){
                SearchView()
            }
        }
        .task {
            await NotificationManager.shared.requestPermission()
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}
#Preview {
    HomeView()
        .environmentObject(AuthStore())
        .environmentObject(TaskStore())
}

