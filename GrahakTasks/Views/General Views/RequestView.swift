import SwiftUI

struct RequestView: View {
    @EnvironmentObject private var auth: AuthStore
    @EnvironmentObject private var collabStore: CollabStore
    @EnvironmentObject private var taskStore: TaskStore

    @State private var isInitialLoad = true
    @State private var showAlert = false
    @State private var alertMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if collabStore.isLoading && collabStore.taskRequests.isEmpty {
                    loadingState()
                } else if let err = collabStore.errorMessage,
                          collabStore.taskRequests.isEmpty {
                    errorState(message: err)
                } else if collabStore.taskRequests.isEmpty {
                    emptyState()
                } else {
                    requestsList()
                }
            }
            .navigationTitle("Requests")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(uiColor: .systemGroupedBackground))
            .task {
                guard isInitialLoad else { return }
                isInitialLoad = false
                await reload()
            }
            .alert("Message", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage ?? "")
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private func requestsList() -> some View {
        List {
            ForEach(collabStore.taskRequests) { request in
                RequestRow(
                    request: request,
                    onAccept: { handleAccept(request) },
                    onReject: { handleReject(request) }
                )
                .listRowInsets(.init(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await reload() }
    }

    // MARK: - States

    private func loadingState() -> some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Loading requests…")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("Failed to load")
                .font(.headline)

            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task { await reload() }
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func emptyState() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)

            Text("No Requests Yet")
                .font(.headline)

            Text("When someone shares a task with you, their request will appear here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func handleAccept(_ request: TaskRequests) {
        Task {
            guard let token = auth.token else {
                alertMessage = "You must be logged in."
                showAlert = true
                return
            }

            // Optimistically remove the request
            let previous = collabStore.taskRequests
            collabStore.taskRequests.removeAll { $0.id == request.id }

            await collabStore.acceptInvite(
                token: token,
                inviteId: request.id
            )
            if let error = collabStore.errorMessage {
                // Rollback
                collabStore.taskRequests = previous
                alertMessage = error
            } else {
                alertMessage = "Request accepted."
            }
            showAlert = true
        }
    }

    private func handleReject(_ request: TaskRequests) {
        Task {
            guard let token = auth.token else {
                alertMessage = "You must be logged in."
                showAlert = true
                return
            }

            await collabStore.rejectInvite(token: token, inviteId: request.id)
            alertMessage = collabStore.errorMessage ?? "Request rejected."
            showAlert = true
        }
    }

    @MainActor
    private func reload() async {
        guard let token = auth.token else {
            collabStore.errorMessage = "You must be logged in."
            return
        }
        await collabStore.fetchTaskRequest(token: token)
    }
}

private struct RequestRow: View {
    let request: TaskRequests
    let onAccept: () -> Void
    let onReject: () -> Void
    
    private var requestedText: String {
        if let ago = DateParser.timeAgo(from: request.sharedOn) {
            return ago
        }
        if let date = ISODateHelper.parseISO(request.sharedOn) {
            return ISODateHelper.relativeOrAbsolute(date)
        }
        return request.sharedOn
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MAIN CONTENT
            HStack(alignment: .top, spacing: 12) {
                // icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(0.12))
                    
                    Image(systemName: "person.2.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                .frame(width: 42, height: 42)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(request.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    Text(request.invitedByUserEmail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Text("Requested \(requestedText)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            
            // DIVIDER
            Divider()
                .opacity(0.35)
                .padding(.leading, 68)
            
            // BUTTONS
            HStack(spacing: 10) {
                Button(action: onReject) {
                    Text("Reject")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.red.opacity(0.12), in: Capsule())
                }
                .foregroundStyle(.red)
                .buttonStyle(.borderless)
                
                Button(action: onAccept) {
                    Text("Accept")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(.blue, in: Capsule())
                }
                .foregroundStyle(.white)
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .padding(.vertical, 8)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(request.title), from \(request.invitedByUserEmail), requested \(requestedText)")
    }
    
    // MARK: - ISO Helper
    
    private enum ISODateHelper {
        
        static func parseISO(_ iso: String) -> Date? {
            let f1 = ISO8601DateFormatter()
            f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let d = f1.date(from: iso) { return d }
            
            let f2 = ISO8601DateFormatter()
            f2.formatOptions = [.withInternetDateTime]
            if let d = f2.date(from: iso) { return d }
            
            let formats = [
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd'T'HH:mm",
                "yyyy-MM-dd HH:mm:ss",
                "yyyy-MM-dd HH:mm"
            ]
            
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.timeZone = .current
            
            for f in formats {
                df.dateFormat = f
                if let d = df.date(from: iso) {
                    return d
                }
            }
            
            return nil
        }
        
        static func relativeOrAbsolute(_ date: Date, reference: Date = Date()) -> String {
            let rel = RelativeDateTimeFormatter()
            rel.unitsStyle = .full
            
            let diff = abs(reference.timeIntervalSince(date))
            let week: TimeInterval = 7 * 24 * 60 * 60
            
            if diff <= week {
                return rel.localizedString(for: date, relativeTo: reference)
            }
            
            let df = DateFormatter()
            df.dateFormat = "d MMM yyyy, HH:mm"
            return df.string(from: date)
        }
    }
}
