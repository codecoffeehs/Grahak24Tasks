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
        }else{
            NavigationStack{
                LoginView()
                
            }
        }
        
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthStore())
        .environmentObject(TaskStore())
}
