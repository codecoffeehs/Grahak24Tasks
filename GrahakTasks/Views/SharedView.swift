//
//  SharedView.swift
//  GrahakTasks
//
//  Created by Hemant Sharma on 10/01/26.
//

import SwiftUI

struct SharedView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var collabStore: CollabStore

    // Delete/unshare placeholders in case actions are added later
    @State private var pendingSharedTaskId: String = ""
    @State private var pendingSharedTaskTitle: String = ""
    @State private var showDeleteAlert: Bool = false

    private var hasSharedTasks: Bool {
        !collabStore.sharedTasks.isEmpty
    }

    // Row builder using existing TaskRow
    @ViewBuilder
    private func sharedRow(_ task: SharedTaskModel) -> some View {
        // No NavigationLink for now because SingleTaskView requires TaskModel.
        TaskRow(
            title: task.title,
            due: task.due,
            isCompleted: task.isCompleted,
            repeatType: task.repeatType,
            categoryTitle: task.categoryTitle,
            colorHex: task.color,
            categoryIcon: task.icon
        )
        // Placeholder swipe for future unshare/remove if needed
        // .swipeActions(edge: .leading, allowsFullSwipe: true) {
        //     Button(role: .destructive) {
        //         pendingSharedTaskId = task.id
        //         pendingSharedTaskTitle = task.title
        //         showDeleteAlert = true
        //     } label: {
        //         Image(systemName: "trash")
        //     }
        // }
    }

    var body: some View {
        NavigationStack {
            Group {
                if collabStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else if !hasSharedTasks {
                    ContentUnavailableView(
                        "No Shared Tasks",
                        systemImage: "person.2",
                        description: Text("Tasks shared with you will appear here.")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                } else {
                    List {
                        ForEach(collabStore.sharedTasks) { shared in
                            sharedRow(shared)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Shared")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                if let token = authStore.token {
                    await collabStore.fetchSharedTasks(token: token)
                }
            }
        }
        .task {
            if let token = authStore.token {
                await collabStore.fetchSharedTasks(token: token)
            }
        }
        // Delete/unshare confirmation (wired for future action)
        .alert("Remove Shared Task?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) {
                pendingSharedTaskId = ""
                pendingSharedTaskTitle = ""
            }
            Button("Remove", role: .destructive) {
                // Implement unshare/remove when API is available, then refresh list
                pendingSharedTaskId = ""
                pendingSharedTaskTitle = ""
                showDeleteAlert = false
            }
        } message: {
            Text("Are you sure you want to remove “\(pendingSharedTaskTitle)” from your shared list?")
        }
        // Error alert from CollabStore
        .alert("Error", isPresented: $collabStore.showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(collabStore.errorMessage ?? "Something went wrong")
        }
    }
}
