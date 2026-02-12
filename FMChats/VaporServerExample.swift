//
//  VaporServerExample.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//
//  This file contains example Vapor server implementation code.
//  To use this, create a separate Vapor project and copy the relevant code.
//

import Foundation

/*
 
 VAPOR SERVER SETUP INSTRUCTIONS
 ================================
 
 This document provides complete example code for setting up a Vapor server
 that works with the FMChats sync feature.
 
 1. Create a new Vapor project:
    ```bash
    mkdir FMChatsServer
    cd FMChatsServer
    swift package init --type executable
    ```
 
 2. Update Package.swift to include:
    ```swift
    // swift-tools-version:6.0
    import PackageDescription

    let package = Package(
        name: "FMChatsServer",
        platforms: [
            .macOS(.v14)
        ],
        dependencies: [
            .package(url: "https://github.com/vapor/vapor.git", from: "4.99.0"),
        ],
        targets: [
            .executableTarget(
                name: "App",
                dependencies: [
                    .product(name: "Vapor", package: "vapor")
                ]
            )
        ]
    )
    ```
 
 3. Create the following files in Sources/App:
 
 ================================
 Models/ChatDTO.swift
 ================================
 
    import Foundation
    import Vapor

    struct ChatDTO: Content {
        let id: UUID
        let title: String
        let timestamp: Date
        let questions: [QuestionDTO]?
    }

    struct QuestionDTO: Content {
        let id: UUID
        let questionText: String
        let answerText: String?
        let timestamp: Date
    }

 
 ================================
 Controllers/ChatController.swift
 ================================
 
    import Vapor

    struct ChatController: RouteCollection {
        // In-memory storage for demonstration
        // In production, use a database like PostgreSQL or MongoDB
        private static var chats: [UUID: ChatDTO] = [:]
        
        func boot(routes: RoutesBuilder) throws {
            let chatsRoute = routes.grouped("chats")
            
            // GET /chats - Get all chats
            chatsRoute.get(use: getAllChats)
            
            // POST /chats - Upload a new chat
            chatsRoute.post(use: uploadChat)
            
            // GET /chats/:chatId - Get a specific chat
            chatsRoute.get(":chatId", use: getChat)
        }
        
        func getAllChats(req: Request) async throws -> [ChatDTO] {
            return Array(ChatController.chats.values)
                .sorted { $0.timestamp > $1.timestamp }
        }
        
        func uploadChat(req: Request) async throws -> ChatDTO {
            let chat = try req.content.decode(ChatDTO.self)
            ChatController.chats[chat.id] = chat
            return chat
        }
        
        func getChat(req: Request) async throws -> ChatDTO {
            guard let chatIdString = req.parameters.get("chatId"),
                  let chatId = UUID(uuidString: chatIdString),
                  let chat = ChatController.chats[chatId] else {
                throw Abort(.notFound, reason: "Chat not found")
            }
            return chat
        }
    }

 
 ================================
 configure.swift
 ================================
 
    import Vapor

    public func configure(_ app: Application) async throws {
        // Configure JSON encoding/decoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        ContentConfiguration.global.use(encoder: encoder, for: .json)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        ContentConfiguration.global.use(decoder: decoder, for: .json)
        
        // Register routes
        try routes(app)
    }

    func routes(_ app: Application) throws {
        // Health check endpoint
        app.get("health") { req async in
            return ["status": "ok"]
        }
        
        // Register chat routes
        try app.register(collection: ChatController())
    }

 
 ================================
 main.swift (or App.swift)
 ================================
 
    import Vapor

    @main
    struct Entrypoint {
        static func main() async throws {
            var env = try Environment.detect()
            try LoggingSystem.bootstrap(from: &env)
            
            let app = Application(env)
            defer { app.shutdown() }
            
            do {
                try await configure(app)
            } catch {
                app.logger.report(error: error)
                throw error
            }
            
            try await app.execute()
        }
    }

 
 ================================
 RUNNING THE SERVER
 ================================
 
 1. Build and run the server:
    ```bash
    swift run
    ```
 
 2. The server will start on http://localhost:8080
 
 3. Test the endpoints:
    ```bash
    # Health check
    curl http://localhost:8080/health
    
    # Upload a chat
    curl -X POST http://localhost:8080/chats \
      -H "Content-Type: application/json" \
      -d '{
        "id": "550e8400-e29b-41d4-a716-446655440000",
        "title": "Test Chat",
        "timestamp": "2024-02-10T12:00:00Z",
        "questions": []
      }'
    
    # Get all chats
    curl http://localhost:8080/chats
    
    # Get specific chat
    curl http://localhost:8080/chats/550e8400-e29b-41d4-a716-446655440000
    ```
 
 ================================
 PRODUCTION CONSIDERATIONS
 ================================
 
 For production use, consider:
 
 1. Database Integration:
    - Add Fluent ORM for database support
    - Use PostgreSQL, MySQL, or MongoDB
 
 2. Authentication:
    - Add JWT or session-based authentication
    - Protect endpoints with authentication middleware
 
 3. Validation:
    - Add input validation for all endpoints
    - Implement rate limiting
 
 4. Error Handling:
    - Add comprehensive error handling
    - Return appropriate HTTP status codes
 
 5. CORS:
    - Configure CORS for web client support
    
 6. Deployment:
    - Deploy to a cloud provider (Vapor Cloud, Heroku, AWS, etc.)
    - Set up SSL/TLS certificates
    - Configure environment variables for production
 
 */

// This file contains only documentation in comments.
// The actual Vapor server code should be created in a separate project.
enum VaporServerDocumentation {
    // This enum exists only to make the file valid Swift code
    // All server implementation details are in the comments above
}
