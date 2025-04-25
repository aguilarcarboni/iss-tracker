import ActivityKit
import WidgetKit
import SwiftUI

struct ISSLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var distance: Double
        var latitude: Double
        var longitude: Double
    }
}

struct ISSLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ISSLiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("ISS Distance")
                    .font(.headline)
                Text("\(Int(context.state.distance / 1000)) km")
                    .font(.title)
                    .bold()
                Text("Lat: \(String(format: "%.2f", context.state.latitude))°")
                    .font(.caption)
                Text("Long: \(String(format: "%.2f", context.state.longitude))°")
                    .font(.caption)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here
                DynamicIslandExpandedRegion(.leading) {
                    Text("ISS Distance")
                        .font(.headline)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(Int(context.state.distance / 1000)) km")
                        .font(.title2)
                        .bold()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text("Lat: \(String(format: "%.2f", context.state.latitude))°")
                        Text("Long: \(String(format: "%.2f", context.state.longitude))°")
                    }
                    .font(.caption)
                }
            } compactLeading: {
                Text("ISS")
            } compactTrailing: {
                Text("\(Int(context.state.distance / 1000))km")
            } minimal: {
                Text("ISS")
            }
        }
    }
} 
