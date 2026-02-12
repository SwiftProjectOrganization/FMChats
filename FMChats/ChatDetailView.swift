//
//  ChatDetailView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import SwiftUI
import SwiftData
import FoundationModels

struct ChatDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var chat: Chat
    
    @State private var newQuestion = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var languageModelSession: LanguageModelSession?
    
    private var sortedQuestions: [Question] {
        (chat.questions ?? []).sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Question list
            ScrollViewReader { proxy in
                List {
                    ForEach(sortedQuestions) { question in
                        VStack(alignment: .leading, spacing: 12) {
                            // Question
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(.blue)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("You")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(question.questionText)
                                        .textSelection(.enabled)
                                }
                            }
                            
                            // Answer
                            if let answer = question.answerText {
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundStyle(.purple)
                                        .font(.title3)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Model")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        Text(answer)
                                            .textSelection(.enabled)
                                    }
                                }
                            } else {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .controlSize(.small)
                                    Text("Generating response...")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.leading, 32)
                            }
                        }
                        .padding(.vertical, 8)
                        .id(question.id)
                    }
                }
                .onChange(of: chat.questions?.count) { _, _ in
                    if let lastQuestion = sortedQuestions.last {
                        withAnimation {
                            proxy.scrollTo(lastQuestion.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            HStack(spacing: 12) {
                TextField("Ask a question...", text: $newQuestion, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .disabled(isProcessing)
                    .onSubmit {
                        submitQuestion()
                    }
                
                Button(action: submitQuestion) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(newQuestion.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                }
                .disabled(newQuestion.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .navigationTitle(chat.title)
        .task {
            await initializeSession()
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { message in
            Text(message)
        }
    }
    
    private func initializeSession() async {
        // Check if model is available
        guard SystemLanguageModel.default.availability == .available else {
            errorMessage = "Language model is not available on this device"
            return
        }
        
        // Create or restore session
        languageModelSession = LanguageModelSession(instructions: "You are a helpful assistant. Provide clear and concise answers.")
    }
    
    private func submitQuestion() {
        let questionText = newQuestion.trimmingCharacters(in: .whitespaces)
        guard !questionText.isEmpty else { return }
        
        // Create and insert question
        let question = Question(questionText: questionText)
        modelContext.insert(question)
        chat.questions?.append(question)
        
        // Clear input
        newQuestion = ""
        
        // Generate response
        Task {
            await generateResponse(for: question)
        }
    }
    
    private func generateResponse(for question: Question) async {
        isProcessing = true
        defer { isProcessing = false }
        
        guard let session = languageModelSession else {
            errorMessage = "Session not initialized"
            return
        }
        
        do {
            // Generate response using FoundationModels
            let response = try await session.respond(to: question.questionText)
            
            // Store the answer
            await MainActor.run {
                question.answerText = response.content
                try? modelContext.save()
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to generate response: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    @Previewable @State var sampleChat: Chat = {
        let chat = Chat(title: "Sample Chat")
        let question1 = Question(questionText: "What is Swift?")
        question1.answerText = "Swift is a powerful and intuitive programming language for iOS, macOS, watchOS, and tvOS."
        chat.questions?.append(question1)
        return chat
    }()
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chat.self, configurations: config)
    
    NavigationStack {
        ChatDetailView(chat: sampleChat)
    }
    .modelContainer(container)
}
