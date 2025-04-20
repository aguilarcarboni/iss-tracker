//
//  ContentView.swift
//  iss-tracker
//
//  Created by Andrés on 19/4/2025.
//

import SwiftUI
import MapKit

class ISSAnnotation: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

struct MapView: View {
    @Binding var mapRegion: MKCoordinateRegion
    let annotation: ISSAnnotation
    var isFullScreen: Bool
    
    var body: some View {
        Map(coordinateRegion: $mapRegion, annotationItems: [annotation]) { item in
            MapAnnotation(coordinate: item.coordinate) {
                VStack {
                    Image(systemName: "airplane")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .foregroundStyle(.primary)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: isFullScreen ? 0 : 20))
    }
}

struct ContentView: View {
    
    @StateObject private var issDataManager = ISSDataManager()
    @State private var mapRegion = MKCoordinateRegion()
    @State private var issAnnotation: ISSAnnotation?
    @State private var timer: Timer?
    @State private var showingFullScreenMap = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if let annotation = issAnnotation {
                        // Map Container
                        ZStack(alignment: .topTrailing) {
                            MapView(mapRegion: $mapRegion, annotation: annotation, isFullScreen: false)
                                .frame(height: 300)
                                .shadow(radius: 5)
                            
                            Button {
                                showingFullScreenMap = true
                            } label: {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.title3)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        
                        // ISS Information Card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 8) {
                                    Label {
                                        Text("Latitude")
                                            .foregroundStyle(.secondary)
                                    } icon: {
                                        Image(systemName: "location.north.fill")
                                            .foregroundStyle(.blue)
                                    }
                                    Text("\(annotation.coordinate.latitude, specifier: "%.4f")°")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Label {
                                        Text("Longitude")
                                            .foregroundStyle(.secondary)
                                    } icon: {
                                        Image(systemName: "location.fill")
                                            .foregroundStyle(.blue)
                                    }
                                    Text("\(annotation.coordinate.longitude, specifier: "%.4f")°")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.horizontal)
                        
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                    
                    if let error = issDataManager.error {
                        Text("Error: \(error.localizedDescription)")
                            .foregroundColor(.red)
                            .padding()
                    }
                }
            }
            .navigationTitle("ISS Tracker")
            .sheet(isPresented: $showingFullScreenMap) {
                if let annotation = issAnnotation {
                    NavigationStack {
                        MapView(mapRegion: $mapRegion, annotation: annotation, isFullScreen: true)
                            .ignoresSafeArea()
                            .navigationTitle("ISS Location")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Button("Done") {
                                        showingFullScreenMap = false
                                    }
                                }
                            }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await issDataManager.fetchISSPosition()
            }
            
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
        .onChange(of: issDataManager.currentPosition) { _, position in
            if let pos = position {
                let coord = CLLocationCoordinate2D(
                    latitude: pos.latitudeDouble,
                    longitude: pos.longitudeDouble
                )
                if issAnnotation == nil {
                    issAnnotation = ISSAnnotation(coordinate: coord)
                } else {
                    issAnnotation?.coordinate = coord
                }
                mapRegion = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 45, longitudeDelta: 45)
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
