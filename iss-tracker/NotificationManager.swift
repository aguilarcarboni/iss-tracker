import Foundation
import UserNotifications
import CoreLocation
import ActivityKit

class NotificationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = NotificationManager()
    private let locationManager = CLLocationManager()
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @Published var isAuthorized = false
    private var liveActivity: Activity<ISSLiveActivityAttributes>?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermissions() {
        // Request notification permissions
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
        
        // Request location permissions
        locationManager.requestWhenInUseAuthorization()
    }
    
    func scheduleISSOverheadNotification() {
        let content = UNMutableNotificationContent()
        content.title = "ISS Overhead!"
        content.body = "The International Space Station is currently passing over your location!"
        content.sound = .default
        
        // Create a trigger that will check every 15 minutes
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 900, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "ISSOverhead",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func checkISSOverhead() {
        guard let userLocation = locationManager.location else { return }
        
        // Fetch ISS position and check if it's overhead
        Task {
            do {
                guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { return }
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(ISSResponse.self, from: data)
                
                let issLocation = CLLocation(
                    latitude: response.issPosition.latitudeDouble,
                    longitude: response.issPosition.longitudeDouble
                )
                
                let distance = userLocation.distance(from: issLocation)
                
                // Update Live Activity if enabled
                if UserDefaults.standard.bool(forKey: "isLiveActivityEnabled") {
                    await updateLiveActivity(distance: distance, latitude: response.issPosition.latitudeDouble, longitude: response.issPosition.longitudeDouble)
                }
                
                // If ISS is within 100km of user's location
                if distance < 100000 {
                    let content = UNMutableNotificationContent()
                    content.title = "ISS Overhead!"
                    content.body = "The International Space Station is currently passing over your location!"
                    content.sound = .default
                    
                    let request = UNNotificationRequest(
                        identifier: UUID().uuidString,
                        content: content,
                        trigger: nil
                    )
                    
                    try await notificationCenter.add(request)
                }
            } catch {
                print("Error checking ISS position: \(error)")
            }
        }
    }
    
    private func updateLiveActivity(distance: Double, latitude: Double, longitude: Double) async {
        let attributes = ISSLiveActivityAttributes()
        let contentState = ISSLiveActivityAttributes.ContentState(
            distance: distance,
            latitude: latitude,
            longitude: longitude
        )
        
        if let existingActivity = liveActivity {
            await existingActivity.update(using: contentState)
        } else {
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    contentState: contentState,
                    pushType: nil
                )
                liveActivity = activity
            } catch {
                print("Error starting Live Activity: \(error)")
            }
        }
    }
    
    func endLiveActivity() {
        Task {
            if let activity = liveActivity {
                await activity.end(dismissalPolicy: .immediate)
                liveActivity = nil
            }
        }
    }
} 