//
//  UploadSyncView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import SwiftUI
import SwiftData

/// View for selecting and uploading chats to the server
struct UploadSyncView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = SyncViewModel()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView("Uploading chats...", value: viewModel.uploadProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .padding()
                        
                        Text("\(Int(viewModel.uploadProgress * 100))% complete")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                } else if viewModel.localChats.isEmpty {
                    ContentUnavailableView(
                        "No Chats Available",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Create some chats to upload to the server")
                    )
                } else {
                    List {
                        Section {
                            ForEach(viewModel.localChats) { chat in
                                ChatRowView(
                                    chat: chat,
                                    isSelected: viewModel.selectedLocalChats.contains(chat.id)
                                ) {
                                    viewModel.toggleLocalChatSelection(chat.id)
                                }
                            }
                        } header: {
                            HStack {
                                Text("Select Chats to Upload")
                                Spacer()
                                if !viewModel.localChats.isEmpty {
                                    Button(viewModel.selectedLocalChats.isEmpty ? "Select All" : "Deselect All") {
                                        if viewModel.selectedLocalChats.isEmpty {
                                            viewModel.selectAllLocalChats()
                                        } else {
                                            viewModel.deselectAllLocalChats()
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
            .navigationTitle("Upload Chats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Upload") {
                        Task {
                            await viewModel.uploadSelectedChats()
                        }
                    }
                    .disabled(viewModel.selectedLocalChats.isEmpty || viewModel.isLoading)
                }
            }
            .onAppear {
                viewModel.loadLocalChats(from: modelContext)
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
    
    // Add sample data
    let chat1 = Chat(title: "Sample Chat 1")
    let chat2 = Chat(title: "Sample Chat 2")
    container.mainContext.insert(chat1)
    container.mainContext.insert(chat2)
    
    return UploadSyncView()
        .modelContainer(container)
}
