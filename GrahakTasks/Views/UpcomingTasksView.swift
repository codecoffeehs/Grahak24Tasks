//
//  TodayTasksView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 14/01/26.
//

import SwiftUI

struct UpcomingTasksView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var authStore: AuthStore

   

    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading upcoming tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if taskStore.allTodayTasks.isEmpty {
                    ContentUnavailableView(
                        "No task coming your way",
                        systemImage: "checkmark.circle",
                        description: Text("Enjoy your day or add a new task to get started.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(taskStore.allTodayTasks) { task in
                        NavigationLink {
                            SingleTaskView(task: task)
                        } label: {
                            TaskRow(
                                title: task.title,
                                due: task.due,
                                isCompleted: task.isCompleted,
                                repeatType: task.repeatType,
                                categoryTitle: task.categoryTitle,
                                colorHex: task.color,
                                categoryIcon: task.icon
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Upcoming (\(taskStore.allTodayTasks.count))")
        }
        .task{
            // Fetch when the view appears and whenever the token changes
            if let token = authStore.token {
                await taskStore.fetchUpcomingTasks(token: token)
            }
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }
    }
}
