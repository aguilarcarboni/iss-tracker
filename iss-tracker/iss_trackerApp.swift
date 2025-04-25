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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register background fetch
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.iss-tracker.fetch", using: nil) { task in
            self.handleBackgroundFetch(task: task as! BGAppRefreshTask)
        }
        
        // Request notification permissions
        NotificationManager.shared.requestPermissions()
        
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationManager.shared.checkISSOverhead()
        completionHandler(.newData)
    }
    
    func handleBackgroundFetch(task: BGAppRefreshTask) {
        // Schedule the next background fetch
        scheduleBackgroundFetch()
        
        // Create a task expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Check ISS position
        NotificationManager.shared.checkISSOverhead()
        
        // Mark the task as completed
        task.setTaskCompleted(success: true)
    }
    
    func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: "com.iss-tracker.fetch")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background fetch: \(error)")
        }
    }
}
