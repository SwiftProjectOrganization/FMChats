//
//  ChatDTO.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import Foundation

/// Data transfer object for Chat entity that can be serialized to/from JSON
struct ChatDTO: Codable, Identifiable {
    let id: UUID
    let title: String
    let timestamp: Date
    let questions: [QuestionDTO]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case timestamp
        case questions
    }
    
    init(id: UUID, title: String, timestamp: Date, questions: [QuestionDTO]? = nil) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.questions = questions
    }
    
    /// Convert from SwiftData Chat model to ChatDTO
    init(from chat: Chat) {
        // Generate a stable UUID from the Chat's title and timestamp
        let combined = "\(chat.title)-\(chat.timestamp.timeIntervalSince1970)"
        let hash = combined.hash
        var bytes = withUnsafeBytes(of: hash) { Data($0) }
        // Pad or truncate to 16 bytes for UUID
        if bytes.count < 16 {
            bytes.append(Data(repeating: 0, count: 16 - bytes.count))
        } else if bytes.count > 16 {
            bytes = bytes.prefix(16)
        }
        self.id = bytes.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
        self.title = chat.title
        self.timestamp = chat.timestamp
        self.questions = chat.questions?.map { QuestionDTO(from: $0) }
    }
    
    /// Convert ChatDTO to Chat model
    func toChat() -> Chat {
        let chat = Chat(title: title, timestamp: timestamp)
        chat.questions = questions?.map { $0.toQuestion() }
        return chat
    }
}

/// Data transfer object for Question entity that can be serialized to/from JSON
struct QuestionDTO: Codable, Identifiable {
    let id: UUID
    let questionText: String
    let answerText: String?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionText
        case answerText
        case timestamp
    }
    
    init(id: UUID, questionText: String, answerText: String? = nil, timestamp: Date) {
        self.id = id
        self.questionText = questionText
        self.answerText = answerText
        self.timestamp = timestamp
    }
    
    /// Convert from SwiftData Question model to QuestionDTO
    init(from question: Question) {
        // Generate a stable UUID from the Question's text and timestamp
        let combined = "\(question.questionText)-\(question.timestamp.timeIntervalSince1970)"
        let hash = combined.hash
        var bytes = withUnsafeBytes(of: hash) { Data($0) }
        // Pad or truncate to 16 bytes for UUID
        if bytes.count < 16 {
            bytes.append(Data(repeating: 0, count: 16 - bytes.count))
        } else if bytes.count > 16 {
            bytes = bytes.prefix(16)
        }
        self.id = bytes.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
        self.questionText = question.questionText
        self.answerText = question.answerText
        self.timestamp = question.timestamp
    }
    
    /// Convert QuestionDTO to Question model
    func toQuestion() -> Question {
        let question = Question(questionText: questionText, timestamp: timestamp)
        question.answerText = answerText
        return question
    }
}
