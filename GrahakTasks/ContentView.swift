//
//  ContentView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 06/01/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var auth:AuthStore
    @EnvironmentObject var task:TaskStore
    var body: some View {
        if auth.isAuthenticated{
            HomeView()
                .transition(.move(edge: .trailing))
        }else{
            NavigationStack{
                LoginView()
                    .transition(.move(edge: .leading))
                
            }
        }
        
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStore())
        .environmentObject(TaskStore())
}
