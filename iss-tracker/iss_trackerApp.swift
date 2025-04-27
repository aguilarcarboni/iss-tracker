//
//  iss_trackerApp.swift
//  iss-tracker
//
//  Created by Andrés on 19/4/2025.
//

import SwiftUI
import BackgroundTasks

@main
struct iss_trackerApp: App {
    init() {
        registerBackgroundTasks()
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.iss-tracker.fetch", using: nil) { task in
            handleBackgroundFetch(task: task as! BGAppRefreshTask)
        }
    }
    
    private func handleBackgroundFetch(task: BGAppRefreshTask) {
        // Schedule the next background fetch
        scheduleBackgroundFetch()
        
        // Create a task to fetch ISS position
        let fetchTask = Task {
            do {
                let issDataManager = ISSDataManager()
                await issDataManager.fetchISSPosition()
                
                // If we have a position, check if we should send a notification
                if let position = issDataManager.currentPosition {
                    await NotificationManager.shared.sendISSPositionNotification(
                        latitude: position.latitudeDouble,
                        longitude: position.longitudeDouble
                    )
                }
            } catch {
                print("Background fetch failed: \(error)")
            }
        }
        
        // Set up a task expiration handler
        task.expirationHandler = {
            fetchTask.cancel()
        }
        
        // Set up a completion handler
        Task {
            await fetchTask.value
            task.setTaskCompleted(success: true)
        }
    }
    
    private func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "com.iss-tracker.fetch")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background fetch: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
