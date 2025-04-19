Research a little about the MapKit and tell me how you would implement it in a iOS app that is supposed to be very simple. Give me a step by step guide that I will give to cursor to implement this.

```Swift
//
//  ContentView.swift
//  iss-tracker
//
//  Created by Andrés on 19/4/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var issDataManager = ISSDataManager()
    @State private var timer: Timer?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
            Text("ISS Current Location")
                .font(.title)
                .bold()
            
            if let position = issDataManager.currentPosition {
                VStack(spacing: 10) {
                    Text("Latitude: \(position.latitude)°")
                        .font(.headline)
                    Text("Longitude: \(position.longitude)°")
                        .font(.headline)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
            
            if let error = issDataManager.error {
                Text("Error: \(error.localizedDescription)")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .onAppear {
            // Initial fetch
            Task {
                await issDataManager.fetchISSPosition()
            }
            
            // Set up timer for polling every 5 seconds
            timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
                Task {
                    await issDataManager.fetchISSPosition()
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

#Preview {
    ContentView()
}
```