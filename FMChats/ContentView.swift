//
//  ContentView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]
    @State private var showingAddChat = false
    @State private var showingUploadSync = false
    @State private var showingDownloadSync = false
    @State private var showingServerSettings = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(chats) { chat in
                    NavigationLink {
                        QuestionsListView(chat: chat)
                    } label: {
                        chatRowView(for: chat)
                    }
                }
                .onDelete(perform: deleteChats)
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
#endif
            .navigationTitle("Chats")
            .toolbar {
#if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
#endif
                ToolbarItem {
                    Menu {
                        Button(action: { showingUploadSync = true }) {
                            Label("Upload to Server", systemImage: "arrow.up.circle")
                        }
                        Button(action: { showingDownloadSync = true }) {
                            Label("Download from Server", systemImage: "arrow.down.circle")
                        }
                        Divider()
                        Button(action: { showingServerSettings = true }) {
                            Label("Server Settings", systemImage: "server.rack")
                        }
                    } label: {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
                ToolbarItem {
                    Button(action: { showingAddChat = true }) {
                        Label("Add Chat", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddChat) {
                AddChatView()
            }
            .sheet(isPresented: $showingUploadSync) {
                UploadSyncView()
            }
            .sheet(isPresented: $showingDownloadSync) {
                DownloadSyncView()
            }
            .sheet(isPresented: $showingServerSettings) {
                ServerSettingsView()
            }
        } detail: {
            Text("Select a chat")
                .foregroundStyle(.secondary)
        }
    }

    private func deleteChats(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(chats[index])
            }
        }
    }
    
    @ViewBuilder
    private func chatRowView(for chat: Chat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(chat.title)
                .font(.headline)
            Text(chat.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                .font(.caption)
                .foregroundStyle(.secondary)
            if let questions = chat.questions, !questions.isEmpty {
                Text("\(questions.count) question\(questions.count == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Chat.self, inMemory: true)
}
