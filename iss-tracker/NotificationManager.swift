import Foundation
import UserNotifications
import CoreLocation
import ActivityKit
import os.log

class NotificationManager: NSObject, ObservableObject, CLLocationManagerDelegate, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.iss-tracker", category: "Notifications")
    
    @Published var isAuthorized = false
    @Published var lastCheckTime: Date?
    @Published var lastISSLocation: CLLocation?
    @Published var userLocation: CLLocation?
    
    // Maximum distance in kilometers to consider ISS as "overhead"
    private let maxOverheadDistance: CLLocationDistance = 1000 // 1000 km

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000 // Update location every 1km
        notificationCenter.delegate = self
    }
    
    func requestPermissions() {
        // Request notification permissions
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
                if let error = error {
                    self.logger.error("Failed to request notification permissions: \(error.localizedDescription)")
                } else {
                    self.logger.info("Notification permissions granted: \(granted)")
                }
            }
        }
        
        // Request location permissions with always authorization
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func isISSOverhead(issLocation: CLLocation) -> Bool {
        guard let userLocation = userLocation else { return false }
        
        let distance = userLocation.distance(from: issLocation)
        print("Distance: \(distance)")
        return distance <= maxOverheadDistance
    }
    
    func sendISSPositionNotification(latitude: Double, longitude: Double) async {
        let issLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        // Only send notification if ISS is overhead
        guard isISSOverhead(issLocation: issLocation) else {
            logger.info("ISS is not overhead, skipping notification")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = "ISS Overhead!"
        content.body = String(format: "The International Space Station is currently flying overhead at %.4f°N, %.4f°E", latitude, longitude)
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await notificationCenter.add(request)
            logger.info("ISS overhead notification sent successfully")
            
            DispatchQueue.main.async {
                self.lastCheckTime = Date()
                self.lastISSLocation = issLocation
            }
        } catch {
            logger.error("Failed to send ISS overhead notification: \(error.localizedDescription)")
        }
    }
    
    func sendTestNotification() {
        Task {
            let content = UNMutableNotificationContent()
            content.title = "Test Notification"
            content.body = "This is a test notification to verify the system is working."
            content.sound = .default
            
            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )
            
            do {
                try await notificationCenter.add(request)
                logger.info("Test notification sent successfully")
            } catch {
                logger.error("Failed to send test notification: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Notification Management
    func getNotifications() async throws -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    func removeNotifications() async throws {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.userLocation = location
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        logger.error("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
        case .denied, .restricted:
            logger.error("Location access denied")
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        completionHandler()
    }
} 
