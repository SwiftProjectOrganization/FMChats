//
//  QuestionDetailView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/14/26.
//

import SwiftUI
import SwiftData
import FoundationModels

struct QuestionDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var chat: Chat
    
    // If question is nil, we're creating a new one
    @State private var question: Question?
    
    @State private var questionText = ""
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var languageModelSession: LanguageModelSession?
    
    // Flag to track if this is a new question being created
    private let isNewQuestion: Bool
    
    init(chat: Chat, question: Question?) {
        self.chat = chat
        self.isNewQuestion = question == nil
        _question = State(initialValue: question)
        _questionText = State(initialValue: question?.questionText ?? "")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if isNewQuestion {
                    // Input area for new question
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ask a Question")
                            .font(.headline)
                        
                        TextField("Enter your question...", text: $questionText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...10)
                            .disabled(isProcessing)
                        
                        Button(action: submitQuestion) {
                            HStack {
                                if isProcessing {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text(isProcessing ? "Submitting..." : "Submit Question")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(questionText.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else if let question = question {
                    // Display existing question
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "person.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("You")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(question.questionText)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                
                // Display answer if available
                if let question = question, let answer = question.answerText {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .foregroundStyle(.purple)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Model")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(answer)
                                    .font(.body)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                } else if question != nil && isProcessing {
                    // Show loading state
                    HStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.regular)
                        Text("Generating response...")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                }
            }
            .padding()
        }
        .navigationTitle(isNewQuestion ? "New Question" : "Question Detail")
        .navigationBarTitleDisplayMode(.inline)
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
        let text = questionText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        
        // Create and insert question
        let newQuestion = Question(questionText: text)
        modelContext.insert(newQuestion)
        chat.questions?.append(newQuestion)
        
        // Update state to show the new question
        question = newQuestion
        
        // Generate response
        Task {
            await generateResponse(for: newQuestion)
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

#Preview("Existing Question") {
    @Previewable @State var sampleChat: Chat = {
        let chat = Chat(title: "Sample Chat")
        let question = Question(questionText: "What is Swift?")
        question.answerText = "Swift is a powerful and intuitive programming language for iOS, macOS, watchOS, and tvOS."
        chat.questions?.append(question)
        return chat
    }()
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chat.self, configurations: config)
    
    NavigationStack {
        QuestionDetailView(chat: sampleChat, question: sampleChat.questions?.first)
    }
    .modelContainer(container)
}

#Preview("New Question") {
    @Previewable @State var sampleChat = Chat(title: "Sample Chat")
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chat.self, configurations: config)
    
    NavigationStack {
        QuestionDetailView(chat: sampleChat, question: nil)
    }
    .modelContainer(container)
}
