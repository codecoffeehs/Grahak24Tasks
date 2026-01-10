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
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authStore)
                .environmentObject(taskStore)
        }
    }
}
