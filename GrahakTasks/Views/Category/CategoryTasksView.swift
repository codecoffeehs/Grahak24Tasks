//
//  CategoryTasksView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 14/01/26.
//

import SwiftUI

struct CategoryTasksView: View {
    let categoryId: String
    let categoryTitle: String

    @EnvironmentObject private var taskStore: TaskStore
    @EnvironmentObject private var auth: AuthStore


    var body: some View {
        NavigationStack {
            Group {
                if taskStore.isLoading {
                    ProgressView("Loading…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if taskStore.categoryTasks.isEmpty {
                    ContentUnavailableView(
                        "No Tasks in \(categoryTitle)",
                        systemImage: "tray",
                        description: Text("Add a task to this category to see it here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(taskStore.categoryTasks) { task in
                        NavigationLink {
                            SingleTaskView(task: task)
                        } label: {
                            TaskRow(
                                title: task.title,
                                due: task.due,
                                isCompleted: task.isCompleted,
                                repeatType: task.repeatType,
                                categoryTitle:task.categoryTitle,
                                colorHex: task.color,
                                categoryIcon: task.icon
                            )
                        }
                    }
                    .swipeActions{
                        
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(categoryTitle)
            .alert("Error", isPresented: $taskStore.showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(taskStore.errorMessage ?? "Something went wrong")
            }
        }
        .task {
            if let token = auth.token {
                await taskStore.fetchTasksForCategory(token: token, categoryId: categoryId)
            }
        }
    }
}

#Preview {
    CategoryTasksView(categoryId: "demo-category-id", categoryTitle: "Finance")
        .environmentObject(TaskStore())
        .environmentObject(AuthStore())
}

