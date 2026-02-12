//
//  SyncViewModel.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import Foundation
import SwiftData
import Observation

/// ViewModel for managing chat synchronization between local storage and server
@Observable
class SyncViewModel {
    var localChats: [ChatDTO] = []
    var serverChats: [ChatDTO] = []
    var selectedLocalChats: Set<UUID> = []
    var selectedServerChats: Set<UUID> = []
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    var uploadProgress: Double = 0.0
    var downloadProgress: Double = 0.0
    
    private let apiClient = ChatAPIClient.shared
    private let storageService = ChatStorageService.shared
    
    init() {}
    
    // MARK: - Upload Operations
    
    /// Load local chats from SwiftData for upload selection
    func loadLocalChats(from modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
            let chats = try modelContext.fetch(descriptor)
            localChats = chats.map { ChatDTO(from: $0) }
        } catch {
            errorMessage = "Failed to load local chats: \(error.localizedDescription)"
        }
    }
    
    /// Upload selected chats to the server and save to local storage
    func uploadSelectedChats() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            uploadProgress = 0.0
        }
        
        let chatsToUpload = localChats.filter { selectedLocalChats.contains($0.id) }
        var uploadedCount = 0
        var failedCount = 0
        
        for (index, chat) in chatsToUpload.enumerated() {
            do {
                // Upload to server
                _ = try await apiClient.uploadChat(chat)
                
                // Save to local JSON storage
                try storageService.saveChat(chat)
                
                uploadedCount += 1
            } catch {
                print("Failed to upload chat '\(chat.title)': \(error)")
                failedCount += 1
            }
            
            await MainActor.run {
                uploadProgress = Double(index + 1) / Double(chatsToUpload.count)
            }
        }
        
        await MainActor.run {
            isLoading = false
            selectedLocalChats.removeAll()
            
            if failedCount == 0 {
                successMessage = "Successfully uploaded \(uploadedCount) chat\(uploadedCount == 1 ? "" : "s")"
            } else {
                errorMessage = "Uploaded \(uploadedCount) chat\(uploadedCount == 1 ? "" : "s"), failed \(failedCount)"
            }
        }
    }
    
    // MARK: - Download Operations
    
    /// Load chats from the server for download selection
    func loadServerChats() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let chats = try await apiClient.getAllChats()
            await MainActor.run {
                serverChats = chats.sorted { $0.timestamp > $1.timestamp }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load server chats: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }
    
    /// Download selected chats from server and import into SwiftData
    func downloadSelectedChats(to modelContext: ModelContext) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
            successMessage = nil
            downloadProgress = 0.0
        }
        
        let chatsToDownload = serverChats.filter { selectedServerChats.contains($0.id) }
        var downloadedCount = 0
        var failedCount = 0
        
        for (index, chatDTO) in chatsToDownload.enumerated() {
            do {
                // Save to local JSON storage
                try storageService.saveChat(chatDTO)
                
                // Import into SwiftData
                await MainActor.run {
                    let chat = chatDTO.toChat()
                    modelContext.insert(chat)
                    if let questions = chat.questions {
                        for question in questions {
                            modelContext.insert(question)
                        }
                    }
                    try? modelContext.save()
                }
                
                downloadedCount += 1
            } catch {
                print("Failed to download chat '\(chatDTO.title)': \(error)")
                failedCount += 1
            }
            
            await MainActor.run {
                downloadProgress = Double(index + 1) / Double(chatsToDownload.count)
            }
        }
        
        await MainActor.run {
            isLoading = false
            selectedServerChats.removeAll()
            
            if failedCount == 0 {
                successMessage = "Successfully downloaded \(downloadedCount) chat\(downloadedCount == 1 ? "" : "s")"
            } else {
                errorMessage = "Downloaded \(downloadedCount) chat\(downloadedCount == 1 ? "" : "s"), failed \(failedCount)"
            }
        }
    }
    
    // MARK: - Selection Helpers
    
    func toggleLocalChatSelection(_ id: UUID) {
        if selectedLocalChats.contains(id) {
            selectedLocalChats.remove(id)
        } else {
            selectedLocalChats.insert(id)
        }
    }
    
    func selectAllLocalChats() {
        selectedLocalChats = Set(localChats.map { $0.id })
    }
    
    func deselectAllLocalChats() {
        selectedLocalChats.removeAll()
    }
    
    func toggleServerChatSelection(_ id: UUID) {
        if selectedServerChats.contains(id) {
            selectedServerChats.remove(id)
        } else {
            selectedServerChats.insert(id)
        }
    }
    
    func selectAllServerChats() {
        selectedServerChats = Set(serverChats.map { $0.id })
    }
    
    func deselectAllServerChats() {
        selectedServerChats.removeAll()
    }
}
