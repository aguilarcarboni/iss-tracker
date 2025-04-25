import SwiftUI
import ActivityKit

class SettingsManager: ObservableObject {
    @Published var isLiveActivityEnabled: Bool {
        didSet {
            print("🔔 Live Activity toggle changed to: \(isLiveActivityEnabled)")
            UserDefaults.standard.set(isLiveActivityEnabled, forKey: "isLiveActivityEnabled")
            if !isLiveActivityEnabled {
                // End any active Live Activities
                for activity in Activity<ISSLiveActivityAttributes>.activities {
                    print("🔔 Ending Live Activity: \(activity.id)")
                    Task {
                        await activity.end(dismissalPolicy: .immediate)
                    }
                }
            }
        }
    }
    
    @Published var areActivitiesEnabled: Bool = false {
        didSet {
            print("🔔 System Live Activities permission changed to: \(areActivitiesEnabled)")
        }
    }
    private var activityEnablementTask: Task<Void, Never>?
    
    init() {
        self.isLiveActivityEnabled = UserDefaults.standard.bool(forKey: "isLiveActivityEnabled")
        self.areActivitiesEnabled = ActivityAuthorizationInfo().areActivitiesEnabled
        print("🔔 Initial Live Activity state - Enabled: \(isLiveActivityEnabled), System Permission: \(areActivitiesEnabled)")
        
        // Start observing activity enablement changes
        activityEnablementTask = Task {
            for await enabled in ActivityAuthorizationInfo().activityEnablementUpdates {
                await MainActor.run {
                    self.areActivitiesEnabled = enabled
                    if !enabled {
                        self.isLiveActivityEnabled = false
                    }
                }
            }
        }
    }
    
    deinit {
        activityEnablementTask?.cancel()
    }
}

struct SettingsView: View {
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some View {
        Form {
            Section(header: Text("Live Activities")) {
                Toggle("Show ISS Distance", isOn: $settingsManager.isLiveActivityEnabled)
                    .disabled(!settingsManager.areActivitiesEnabled)
                    .onChange(of: settingsManager.isLiveActivityEnabled) { newValue in
                        print("🔔 Toggle changed to: \(newValue)")
                    }
                
                if settingsManager.isLiveActivityEnabled {
                    Button(action: {
                        print("🔔 Starting Live Activity manually")
                        NotificationManager.shared.checkISSOverhead()
                    }) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Start Live Activity")
                        }
                    }
                }
                
                if !settingsManager.areActivitiesEnabled {
                    Text("Live Activities are disabled in Settings")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("About")) {
                Text("ISS Tracker")
                    .font(.headline)
                Text("Version 1.0")
                    .font(.subheadline)
            }
        }
        .navigationTitle("Settings")
    }
} 