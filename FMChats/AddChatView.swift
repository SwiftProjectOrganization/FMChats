//
//  AddChatView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import SwiftUI
import SwiftData

struct AddChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var chatTitle = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Chat Details") {
                    TextField("Title", text: $chatTitle)
                }
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createChat()
                    }
                    .disabled(chatTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func createChat() {
        let newChat = Chat(title: chatTitle.trimmingCharacters(in: .whitespaces))
        modelContext.insert(newChat)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    AddChatView()
        .modelContainer(for: Chat.self, inMemory: true)
}
