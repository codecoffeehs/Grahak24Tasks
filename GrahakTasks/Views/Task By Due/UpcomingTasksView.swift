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
    
    // Simple search
    @State private var searchText: String = ""
    
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
    
    private var filteredTasks: [TaskModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return taskStore.allUpcomingTasks }
        return taskStore.allUpcomingTasks.filter { task in
            if task.title.lowercased().contains(q) { return true }
            if task.description.lowercased().contains(q) { return true }
            if task.categoryTitle.lowercased().contains(q) { return true }
            return false
        }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading upcoming tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTasks.isEmpty {
                    ContentUnavailableView(
                        taskStore.allUpcomingTasks.isEmpty && searchText.isEmpty ? "No task coming your way" : "No results",
                        systemImage: taskStore.allUpcomingTasks.isEmpty && searchText.isEmpty ? "checkmark.circle" : "magnifyingglass",
                        description: Text(taskStore.allUpcomingTasks.isEmpty && searchText.isEmpty
                                          ? "Enjoy your day or add a new task to get started."
                                          : "Try a different keyword.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(filteredTasks) { task in
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
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .navigationTitle("Upcoming Tasks")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    VStack(spacing: 2) {
//                        Text("Upcoming Tasks")
//                            .font(.headline)
//                        Text(countSubtitle)
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                    }
//                    .accessibilityElement(children: .combine)
//                }
//            }
            .searchable(text: $searchText, prompt: "Search tasks")
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
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
    }
}
