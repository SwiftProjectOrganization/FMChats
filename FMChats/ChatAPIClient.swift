//
//  ChatAPIClient.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import Foundation

/// API client for communicating with the chat sync server
/// This is a simple URLSession-based implementation that follows the OpenAPI spec
/// For production use, you can replace this with SwiftOpenAPI-generated client
class ChatAPIClient {
    static let shared = ChatAPIClient()
    
    private var baseURL: URL
    private let session: URLSession
    
    private init(baseURL: String = "http://Rob-Travel-M5.local:8082") {
        // Load saved server address from UserDefaults if available
        let savedAddress = UserDefaults.standard.string(forKey: "serverAddress") ?? baseURL
        self.baseURL = URL(string: savedAddress)!
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    /// Update the base URL for the API
    func updateBaseURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        self.baseURL = url
    }
    
    /// Get the current base URL
    var currentBaseURL: String {
        return baseURL.absoluteString
    }
    
    // MARK: - API Methods
    
    /// Upload a chat to the server
    func uploadChat(_ chat: ChatDTO) async throws -> ChatDTO {
        let url = baseURL.appendingPathComponent("chats")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(chat)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ChatDTO.self, from: data)
    }
    
    /// Get all chats from the server
    func getAllChats() async throws -> [ChatDTO] {
        let url = baseURL.appendingPathComponent("chats")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([ChatDTO].self, from: data)
    }
    
    /// Get a specific chat from the server
    func getChat(id: UUID) async throws -> ChatDTO {
        let url = baseURL.appendingPathComponent("chats/\(id.uuidString)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw APIError.serverError(errorResponse.error)
            }
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ChatDTO.self, from: data)
    }
}

// MARK: - Supporting Types

enum APIError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case serverError(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

struct ErrorResponse: Codable {
    let error: String
}
