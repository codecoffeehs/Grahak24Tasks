//
//  GrahakTasksApp.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 06/01/26.
//

import SwiftUI

@main
struct GrahakTasksApp: App {
    @StateObject private var authStore = AuthStore()
    @StateObject private var taskStore = TaskStore()
    @StateObject private var categoryStore = CategoryStore()
    @StateObject private var collabStore = CollabStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .environmentObject(taskStore)
                .environmentObject(categoryStore)
                .environmentObject(collabStore)
        }
    }
}
