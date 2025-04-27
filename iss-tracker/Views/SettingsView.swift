import SwiftUI
import ActivityKit

struct SettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var showingTestAlert = false
    
    var body: some View {
        List {
            Section(header: Text("Notifications")) {
                Toggle("Enable Notifications", isOn: $notificationManager.isAuthorized)
                    .onChange(of: notificationManager.isAuthorized) { newValue in
                        if newValue {
                            notificationManager.requestPermissions()
                        }
                    }
            }
        }
        .navigationTitle("Settings")
        .alert("Test Notification", isPresented: $showingTestAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A test notification has been sent. Please check your notification center.")
        }
    }
} 
