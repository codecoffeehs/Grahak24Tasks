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

    // Add Task Sheet State
    @State private var showingAddTaskSheet = false
    @State private var newTaskTitle = ""
    @State private var newTaskDescription = ""
    @State private var setReminder = false
    @State private var dueDate = Date().addingTimeInterval(120)
    @State private var repeatType: RepeatType = .none
    @State private var isAddingTask = false // disables button during add

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
                                description: task.description,
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
                        // You can add swipe actions here later
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle(categoryTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddTaskSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
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
        .sheet(isPresented: $showingAddTaskSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Title")) {
                        TextField("Task title", text: $newTaskTitle)
                            .textInputAutocapitalization(.sentences)
                    }

                    Section {
                        Toggle(isOn: $setReminder) {
                            Label("Set Reminder", systemImage: "bell.badge")
                        }
                    }

                    if setReminder {
                        Section {
                            DatePicker(
                                "Due Date",
                                selection: $dueDate,
                                in: Date().addingTimeInterval(60)...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            Picker("Repeat", selection: $repeatType) {
                                ForEach(RepeatType.allCases) { option in
                                    Text(option.title).tag(option)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add Task")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            resetAddTaskForm()
                            showingAddTaskSheet = false
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            addTaskOptimistically()
                        }
                        .disabled(isAddingTask || newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
    }

    private func resetAddTaskForm() {
        newTaskTitle = ""
        setReminder = false
        dueDate = Date().addingTimeInterval(120)
        repeatType = .none
        isAddingTask = false
    }

    private func addTaskOptimistically() {
        guard let token = auth.token else { return }
        let trimmedTitle = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        isAddingTask = true
        showingAddTaskSheet = false

        // Temporary ID for optimistic update
        let tempId = UUID().uuidString

        // Use current time for now if not setting reminder
        let dueString: String? = setReminder ? ISO8601DateFormatter().string(from: dueDate) : nil
        let repeatValue: RepeatType? = setReminder ? repeatType : nil

        // Find category color/icon from a sample in categoryTasks, or fallback
        let color = taskStore.categoryTasks.first?.color ?? "#808080"
        let icon = taskStore.categoryTasks.first?.icon ?? "folder"

        // Build optimistic TaskModel
        let optimisticTask = TaskModel(
            id: tempId,
            title: trimmedTitle,
            description: trimmedDescription,
            isCompleted: false,
            due: dueString,
            repeatType: repeatValue,
            categoryId: categoryId,
            categoryTitle: categoryTitle,
            color: color,
            icon: icon
        )

        // Insert at top for fast feedback
        taskStore.categoryTasks.insert(optimisticTask, at: 0)

        // Save the index for possible rollback
        let optimisticIndex = 0

        Task {
            do {
                let newTask = try await TaskApi.createTask(
                    title: trimmedTitle,
                    description: trimmedDescription,
                    due: setReminder ? dueDate : nil,
                    repeatType: setReminder ? repeatType : nil,
                    categoryId: categoryId,
                    token: token
                )
                // Replace optimistic with backend result (or just refresh all)
                await MainActor.run {
                    // Find and replace the optimistic task
                    if let idx = taskStore.categoryTasks.firstIndex(where: { $0.id == tempId }) {
                        taskStore.categoryTasks[idx] = newTask
                    } else {
                        // fallback: append
                        taskStore.categoryTasks.insert(newTask, at: 0)
                    }
                    resetAddTaskForm()
                }
            } catch {
                // Remove optimistic task on failure and show error
                await MainActor.run {
                    if taskStore.categoryTasks.indices.contains(optimisticIndex),
                       taskStore.categoryTasks[optimisticIndex].id == tempId {
                        taskStore.categoryTasks.remove(at: optimisticIndex)
                    } else {
                        taskStore.categoryTasks.removeAll { $0.id == tempId }
                    }
                    taskStore.errorMessage = error.localizedDescription
                    taskStore.showErrorAlert = true
                    resetAddTaskForm()
                }
            }
        }
    }
}

#Preview {
    CategoryTasksView(categoryId: "demo-category-id", categoryTitle: "Finance")
        .environmentObject(TaskStore())
        .environmentObject(AuthStore())
}
