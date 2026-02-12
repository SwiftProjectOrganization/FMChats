//
//  ChatStorageService.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import Foundation

/// Service for storing and loading chats as JSON files in the user's Documents directory
class ChatStorageService {
    static let shared = ChatStorageService()
    
    private let fileManager = FileManager.default
    private let directoryName = "FMChats"
    
    private init() {}
    
    /// Get the FMChats directory URL in the user's Documents directory
    var chatsDirectoryURL: URL {
        get throws {
            let documentsURL = try fileManager.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let chatsURL = documentsURL.appendingPathComponent(directoryName, isDirectory: true)
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: chatsURL.path) {
                try fileManager.createDirectory(at: chatsURL, withIntermediateDirectories: true)
            }
            
            return chatsURL
        }
    }
    
    /// Save a chat to a JSON file
    func saveChat(_ chatDTO: ChatDTO) throws {
        let directoryURL = try chatsDirectoryURL
        let fileName = "\(chatDTO.id.uuidString).json"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let data = try encoder.encode(chatDTO)
        try data.write(to: fileURL, options: .atomic)
    }
    
    /// Load a chat from a JSON file by ID
    func loadChat(id: UUID) throws -> ChatDTO {
        let directoryURL = try chatsDirectoryURL
        let fileName = "\(id.uuidString).json"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        let data = try Data(contentsOf: fileURL)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode(ChatDTO.self, from: data)
    }
    
    /// Load all chats from the FMChats directory
    func loadAllChats() throws -> [ChatDTO] {
        let directoryURL = try chatsDirectoryURL
        
        let fileURLs = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "json" }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        var chats: [ChatDTO] = []
        for fileURL in fileURLs {
            do {
                let data = try Data(contentsOf: fileURL)
                let chat = try decoder.decode(ChatDTO.self, from: data)
                chats.append(chat)
            } catch {
                print("Error loading chat from \(fileURL.lastPathComponent): \(error)")
                // Continue loading other chats even if one fails
            }
        }
        
        return chats.sorted { $0.timestamp > $1.timestamp }
    }
    
    /// Delete a chat JSON file by ID
    func deleteChat(id: UUID) throws {
        let directoryURL = try chatsDirectoryURL
        let fileName = "\(id.uuidString).json"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
        }
    }
    
    /// Check if a chat exists in storage
    func chatExists(id: UUID) -> Bool {
        do {
            let directoryURL = try chatsDirectoryURL
            let fileName = "\(id.uuidString).json"
            let fileURL = directoryURL.appendingPathComponent(fileName)
            return fileManager.fileExists(atPath: fileURL.path)
        } catch {
            return false
        }
    }
    
    /// Get the count of stored chats
    func getStoredChatsCount() throws -> Int {
        let directoryURL = try chatsDirectoryURL
        let fileURLs = try fileManager.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ).filter { $0.pathExtension == "json" }
        
        return fileURLs.count
    }
}
