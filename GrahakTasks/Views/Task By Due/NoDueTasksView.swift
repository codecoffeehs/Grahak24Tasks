//
//  TodayTasksView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 14/01/26.
//

import SwiftUI

struct NoDueTasksView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var authStore: AuthStore
    
    @State private var pendingDeleteTaskID = ""
    @State private var pendingDeleteTaskTitle = ""
    @State private var showDeleteAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading no due tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if taskStore.allNoDueTasks.isEmpty {
                    ContentUnavailableView(
                        "Yayy!! You have'nt missed anything",
                        systemImage: "checkmark.circle",
                        description: Text("Enjoy your day or add a new task to get started.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(taskStore.allNoDueTasks) { task in
                        NavigationLink {
                            SingleTaskView(task: task)
                        } label: {
                            TaskRow(
                                title: task.title,
                                description: task.description,
                                due: task.due,
                                isCompleted: task.isCompleted,
                                repeatType: task.repeatType,
                                categoryTitle: task.categoryTitle,
                                colorHex: task.color,
                                categoryIcon: task.icon
                            )
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    // Stage for confirmation
                                    pendingDeleteTaskID = task.id
                                    pendingDeleteTaskTitle = task.title
                                    showDeleteAlert = true
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("Delete task")
                                .accessibilityHint("Opens confirmation alert to permanently delete this task")
                                .accessibilityIdentifier("delete_task_button")
                            }
                            
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button {
                                    Task {
                                        if let token = authStore.token {
                                            await taskStore.toggleTask(id: task.id, token: token)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "checkmark")
                                }
                                .tint(.green)
                                .accessibilityLabel("Complete task")
                                .accessibilityHint("Marks this task as completed")
                                .accessibilityIdentifier("complete_task_button")

                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("No Due (\(taskStore.noDueCount))")
        }
        .task{
            if let token = authStore.token {
                await taskStore.fetchNoDueTasks(token: token)
            }
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }
    }
}
