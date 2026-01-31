//
//  TodayTasksView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 14/01/26.
//

import SwiftUI

struct TodayTasksView: View {
    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var authStore: AuthStore

    @State private var pendingDeleteTaskID = ""
    @State private var pendingDeleteTaskTitle = ""
    @State private var showDeleteAlert = false

    // Simple search
    @State private var searchText: String = ""

    private var countSubtitle: String {
        let count = taskStore.todayCount
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
        guard !q.isEmpty else { return taskStore.allTodayTasks }
        return taskStore.allTodayTasks.filter { task in
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
                    ProgressView("Loading today’s tasks…")
                        .progressViewStyle(.circular)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if filteredTasks.isEmpty {
                    ContentUnavailableView(
                        taskStore.allTodayTasks.isEmpty && searchText.isEmpty
                        ? "No tasks for today"
                        : "No results",
                        systemImage: taskStore.allTodayTasks.isEmpty && searchText.isEmpty
                        ? "checkmark.circle"
                        : "magnifyingglass",
                        description: Text(
                            taskStore.allTodayTasks.isEmpty && searchText.isEmpty
                            ? "Enjoy your day or add a new task to get started."
                            : "Try a different keyword."
                        )
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
            .navigationTitle("Today's Tasks")
            .navigationBarTitleDisplayMode(.inline)
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
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled(true)
        .task {
            if let token = authStore.token {
                await taskStore.fetchTodayTasks(token: token)
            }
        }
        .alert("Error", isPresented: $taskStore.showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskStore.errorMessage ?? "Something went wrong")
        }
    }
}
