//
//  DownloadSyncView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import SwiftUI
import SwiftData

/// View for selecting and downloading chats from the server
struct DownloadSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SyncViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.serverChats.isEmpty {
                    ProgressView("Loading chats from server...")
                        .padding()
                } else if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView("Downloading chats...", value: viewModel.downloadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .padding()
                        
                        Text("\(Int(viewModel.downloadProgress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if viewModel.serverChats.isEmpty {
                    ContentUnavailableView(
                        "No Chats on Server",
                        systemImage: "server.rack",
                        description: Text("Upload some chats to the server first")
                    )
                } else {
                    List {
                        Section {
                            ForEach(viewModel.serverChats) { chat in
                                ChatRowView(
                                    chat: chat,
                                    isSelected: viewModel.selectedServerChats.contains(chat.id)
                                ) {
                                    viewModel.toggleServerChatSelection(chat.id)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Select Chats to Download")
                                Spacer()
                                if !viewModel.serverChats.isEmpty {
                                    Button(viewModel.selectedServerChats.isEmpty ? "Select All" : "Deselect All") {
                                        if viewModel.selectedServerChats.isEmpty {
                                            viewModel.selectAllServerChats()
                                        } else {
                                            viewModel.deselectAllServerChats()
                                        }
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.red)
                        Spacer()
                        Button("Dismiss") {
                            viewModel.errorMessage = nil
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                }
                
                if let successMessage = viewModel.successMessage {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(successMessage)
                            .font(.caption)
                            .foregroundStyle(.green)
                        Spacer()
                        Button("Dismiss") {
                            viewModel.successMessage = nil
                        }
                        .font(.caption)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                }
            }
            .navigationTitle("Download Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Download") {
                        Task {
                            await viewModel.downloadSelectedChats(to: modelContext)
                        }
                    }
                    .disabled(viewModel.selectedServerChats.isEmpty || viewModel.isLoading)
                }
            }
            .task {
                await viewModel.loadServerChats()
            }
        }
    }
}

/// Row view for displaying a chat with selection checkbox
private struct ChatRowView: View {
    let chat: ChatDTO
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .gray)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(chat.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(chat.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let questions = chat.questions, !questions.isEmpty {
                        Text("\(questions.count) question\(questions.count == 1 ? "" : "s")")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chat.self, configurations: config)
    
    return DownloadSyncView()
        .modelContainer(container)
}
