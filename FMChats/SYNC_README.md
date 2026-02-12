# FMChats Sync Feature

This document describes the chat synchronization feature that enables uploading and downloading chats to/from a backend server.

## Architecture Overview

The sync feature consists of several components:

### Client-Side Components

1. **ChatDTO.swift** - Data Transfer Objects
   - `ChatDTO`: Codable representation of Chat for JSON serialization
   - `QuestionDTO`: Codable representation of Question for JSON serialization
   - Includes conversion methods between SwiftData models and DTOs

2. **ChatStorageService.swift** - Local File Storage
   - Manages JSON files in `Documents/FMChats/` directory
   - Saves chats as individual JSON files named by UUID
   - Provides methods to save, load, and delete chats
   - Uses ISO8601 date encoding for cross-platform compatibility

3. **ChatAPIClient.swift** - HTTP API Client
   - URLSession-based client following the OpenAPI specification
   - Endpoints:
     - `POST /chats` - Upload a chat
     - `GET /chats` - Get all chats
     - `GET /chats/{id}` - Get specific chat
   - Configurable base URL (defaults to http://localhost:8080)

4. **SyncViewModel.swift** - Sync Logic
   - Observable ViewModel managing upload/download operations
   - Handles chat selection state
   - Provides progress tracking
   - Error and success message handling

5. **UploadSyncView.swift** - Upload UI
   - Select local chats to upload to server
   - Displays upload progress
   - Shows success/error messages
   - Automatically saves uploaded chats to local JSON storage

6. **DownloadSyncView.swift** - Download UI
   - Browse and select chats from server
   - Displays download progress
   - Imports downloaded chats into SwiftData
   - Saves chats to local JSON storage

7. **ContentView.swift** - Main UI Integration
   - Added Sync menu in toolbar with:
     - Upload to Server
     - Download from Server

### Server-Side Components

8. **openapi.yaml** - OpenAPI Specification
   - Defines the REST API contract
   - Can be used to generate server or client code with SwiftOpenAPI

9. **VaporServerExample.swift** - Vapor Server Implementation
   - Complete example Vapor server code
   - Includes setup instructions
   - In-memory storage for demonstration
   - Production deployment guidance

## How to Use

### Upload Chats

1. Tap the Sync button in the toolbar
2. Select "Upload to Server"
3. Select the chats you want to upload
4. Tap "Upload"
5. Chats are uploaded to the server AND saved to `Documents/FMChats/` as JSON files

### Download Chats

1. Tap the Sync button in the toolbar
2. Select "Download from Server"
3. Browse available chats on the server
4. Select the chats you want to download
5. Tap "Download"
6. Chats are downloaded, saved to `Documents/FMChats/`, and imported into SwiftData

## File Storage

All uploaded chats are automatically stored as JSON files in:
```
~/Documents/FMChats/{chat-id}.json
```

Each file contains:
- Chat metadata (id, title, timestamp)
- All questions and answers
- ISO8601 formatted dates for compatibility

## Server Setup

### Quick Start (Development)

1. Create a new Vapor project:
```bash
vapor new FMChatsServer
cd FMChatsServer
```

2. Copy the code from `VaporServerExample.swift` into the appropriate files in your Vapor project

3. Run the server:
```bash
swift run
```

The server will start on http://localhost:8080

### Testing the Server

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
```

## SwiftOpenAPI Integration

The current implementation uses a simple URLSession-based client. To use SwiftOpenAPI:

1. Add SwiftOpenAPI dependencies to your project
2. Generate client code from `openapi.yaml`
3. Replace `ChatAPIClient` with the generated client

Benefits of SwiftOpenAPI:
- Type-safe API calls
- Automatic request/response handling
- Built-in validation
- Better error handling

## Production Considerations

### Security
- Add authentication (JWT or session-based)
- Use HTTPS in production
- Implement rate limiting
- Validate all inputs

### Database
- Replace in-memory storage with a database
- Use Fluent ORM with PostgreSQL, MySQL, or MongoDB
- Add migration support

### Scalability
- Deploy to cloud provider (AWS, Heroku, Vapor Cloud)
- Set up load balancing
- Implement caching
- Add CDN for static content

### Monitoring
- Add logging and analytics
- Set up error tracking (Sentry, etc.)
- Monitor API performance
- Track usage metrics

## Troubleshooting

### Cannot Connect to Server
- Ensure the Vapor server is running
- Check that the base URL is correct (http://localhost:8080)
- Verify network connectivity
- Check firewall settings

### Upload/Download Fails
- Check server logs for errors
- Verify JSON format is correct
- Ensure date formats are ISO8601
- Check file permissions for Documents directory

### JSON Files Not Created
- Verify app has permission to write to Documents directory
- Check disk space availability
- Review ChatStorageService error messages

## Future Enhancements

- Conflict resolution for duplicate chats
- Incremental sync (only changed chats)
- Offline queue for failed uploads
- Automatic background sync
- Real-time sync with WebSockets
- Multi-device sync with conflict detection
- Chat sharing between users
- Cloud backup and restore
