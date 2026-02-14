//
//  ServerSettingsView.swift
//  FMChats
//
//  Created by Robert Goedman on 2/10/26.
//

import SwiftUI

/// View for configuring the server address
struct ServerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("serverAddress") private var serverAddress = "http://Rob-Travel-M5.local:8082"
    @State private var editedAddress: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Server Address", text: $editedAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #if os(iOS)
                        .keyboardType(.URL)
                        #endif
                } header: {
                    Text("Server Configuration")
                } footer: {
                    Text("Enter the base URL of your sync server (e.g., http://localhost:8082)")
                        .font(.caption)
                }
                
                Section {
                    Text("Current: \(serverAddress)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Server Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveServerAddress()
                    }
                    .disabled(editedAddress.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                editedAddress = serverAddress
            }
            .alert("Server Address Updated", isPresented: $showingAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func saveServerAddress() {
        let trimmedAddress = editedAddress.trimmingCharacters(in: .whitespaces)
        
        // Basic validation
        guard !trimmedAddress.isEmpty else { return }
        
        // Remove trailing slash if present
        let cleanAddress = trimmedAddress.hasSuffix("/") ? String(trimmedAddress.dropLast()) : trimmedAddress
        
        serverAddress = cleanAddress
        ChatAPIClient.shared.updateBaseURL(cleanAddress)
        
        alertMessage = "Server address updated to: \(cleanAddress)"
        showingAlert = true
    }
}

#Preview {
    ServerSettingsView()
}
