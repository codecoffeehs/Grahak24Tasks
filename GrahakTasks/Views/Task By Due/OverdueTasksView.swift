//
//  OverdueTasksView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 14/01/26.
//

import SwiftUI

struct OverdueTasksView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var authStore: AuthStore
    
    // State for delete confirmation
    @State private var pendingDeleteTaskID = ""
    @State private var pendingDeleteTaskTitle = ""
    @State private var showDeleteAlert = false

    // Simple search
    @State private var searchText: String = ""
    
    private var countSubtitle: String {
        let count = taskStore.overdueCount
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
        guard !q.isEmpty else { return taskStore.allOverdueTasks }
        return taskStore.allOverdueTasks.filter { task in
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
                    ProgressView("Loading overdue tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredTasks.isEmpty {
                    ContentUnavailableView(
                        taskStore.allOverdueTasks.isEmpty && searchText.isEmpty ? "Yayy!! You have'nt missed anything" : "No results",
                        systemImage: taskStore.allOverdueTasks.isEmpty && searchText.isEmpty ? "checkmark.circle" : "magnifyingglass",
                        description: Text(taskStore.allOverdueTasks.isEmpty && searchText.isEmpty
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
            .navigationTitle("Overdue Tasks")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .principal) {
//                    VStack(spacing: 2) {
//                        Text("Overdue Tasks")
//                            .font(.headline)
//                        Text(countSubtitle)
//                            .font(.subheadline)
//                            .foregroundStyle(.secondary)
//                    }
//                    .accessibilityElement(children: .combine)
//                }
//            }
            // Make search available in all states so the clear (x) is always there.
            .searchable(text: $searchText, prompt: "Search tasks")
            // iOS 17+: keep search field visible even when list is empty/loading
            // .searchPresentationToolbarBehavior(.alwaysVisible)
//            .searchSuggestions {
//                if !searchText.isEmpty && filteredTasks.isEmpty {
//                    Button {
//                        searchText = ""
//                    } label: {
//                        Label("Clear search", systemImage: "xmark.circle")
//                    }
//                }
//            }
        }
        .task {
            if let token = authStore.token {
                await taskStore.fetchOverdueTasks(token: token)
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
