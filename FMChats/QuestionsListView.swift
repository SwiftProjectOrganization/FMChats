//
//  QuestionsListView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/14/26.
//

import SwiftUI
import SwiftData

struct QuestionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var chat: Chat
    
    private var sortedQuestions: [Question] {
        (chat.questions ?? []).sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    var body: some View {
        List {
            ForEach(sortedQuestions) { question in
                NavigationLink {
                    QuestionDetailView(chat: chat, question: question)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(question.questionText)
                            .font(.body)
                            .lineLimit(2)
                        
                        HStack {
                            Text(question.timestamp, format: Date.FormatStyle(date: .numeric, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                            
                            if question.answerText != nil {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                            } else {
                                Image(systemName: "ellipsis.circle")
                                    .foregroundStyle(.gray)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .onDelete(perform: deleteQuestions)
        }
        .navigationTitle(chat.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    QuestionDetailView(chat: chat, question: nil)
                } label: {
                    Label("Add Question", systemImage: "plus")
                }
            }
        }
    }
    
    private func deleteQuestions(at offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let question = sortedQuestions[index]
                chat.questions?.removeAll { $0.id == question.id }
                modelContext.delete(question)
            }
        }
    }
}

#Preview {
    @Previewable @State var sampleChat: Chat = {
        let chat = Chat(title: "Sample Chat")
        let question1 = Question(questionText: "What is Swift?")
        question1.answerText = "Swift is a powerful and intuitive programming language for iOS, macOS, watchOS, and tvOS."
        let question2 = Question(questionText: "What is SwiftUI?")
        question2.answerText = "SwiftUI is Apple's declarative framework for building user interfaces across all Apple platforms."
        let question3 = Question(questionText: "What is SwiftData?")
        chat.questions?.append(contentsOf: [question1, question2, question3])
        return chat
    }()
    
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Chat.self, configurations: config)
    
    NavigationStack {
        QuestionsListView(chat: sampleChat)
    }
    .modelContainer(container)
}
