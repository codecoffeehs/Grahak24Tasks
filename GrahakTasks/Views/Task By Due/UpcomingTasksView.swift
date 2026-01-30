//
//  UpcomingTasksView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 14/01/26.
//

import SwiftUI

struct UpcomingTasksView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var authStore: AuthStore

    // State for delete confirmation
    @State private var pendingDeleteTaskID = ""
    @State private var pendingDeleteTaskTitle = ""
    @State private var showDeleteAlert = false
    
    private var countSubtitle: String {
        let count = taskStore.noDueCount
        if taskStore.isLoading {
            return "Loading…"
        } else if count == 0 {
            return "No items"
        } else if count == 1 {
            return "1 item"
        } else {
            return "\(count) items"
        }
    }
    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading upcoming tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if taskStore.allUpcomingTasks.isEmpty {
                    ContentUnavailableView(
                        "No task coming your way",
                        systemImage: "checkmark.circle",
                        description: Text("Enjoy your day or add a new task to get started.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(taskStore.allUpcomingTasks) { task in
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
//                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
//                                Button(role: .destructive) {
//                                    // Stage for confirmation
//                                    pendingDeleteTaskID = task.id
//                                    pendingDeleteTaskTitle = task.title
//                                    showDeleteAlert = true
//                                } label: {
//                                    Image(systemName: "trash")
//                                }
//                                .accessibilityLabel("Delete task")
//                                .accessibilityHint("Opens confirmation alert to permanently delete this task")
//                                .accessibilityIdentifier("delete_task_button")
//                            }
//                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
//                                Button {
//                                    Task {
//                                        if let token = authStore.token {
//                                            await taskStore.toggleTask(id: task.id, token: token)
//                                        }
//                                    }
//                                } label: {
//                                    Image(systemName: "checkmark")
//                                }
//                                .tint(.green)
//                                .accessibilityLabel("Complete task")
//                                .accessibilityHint("Marks this task as completed")
//                                .accessibilityIdentifier("complete_task_button")
//                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Upcoming Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Upcoming Tasks")
                            .font(.headline)
                        Text(countSubtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .task {
            if let token = authStore.token {
                await taskStore.fetchUpcomingTasks(token: token)
            }
        }
        .alert("Delete Task?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                pendingDeleteTaskID = ""
                pendingDeleteTaskTitle = ""
            }

            Button("Delete", role: .destructive) {
                let taskId = pendingDeleteTaskID
                pendingDeleteTaskID = ""
                pendingDeleteTaskTitle = ""
                showDeleteAlert = false

                Task {
                    if let token = authStore.token {
                        await taskStore.deleteTask(id: taskId, token: token)
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete “\(pendingDeleteTaskTitle)”? This action cannot be undone.")
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }

    }
}
