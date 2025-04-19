import Foundation

struct ISSResponse: Codable {
    let message: String
    let timestamp: TimeInterval
    let issPosition: ISSPosition
    
    enum CodingKeys: String, CodingKey {
        case message
        case timestamp
        case issPosition = "iss_position"
    }
}

struct ISSPosition: Codable, Equatable {
    let latitude: String
    let longitude: String
    
    var latitudeDouble: Double {
        Double(latitude) ?? 0.0
    }
    
    var longitudeDouble: Double {
        Double(longitude) ?? 0.0
    }
}

class ISSDataManager: ObservableObject {
    @Published var currentPosition: ISSPosition?
    @Published var error: Error?
    
    func fetchISSPosition() async {
        do {
            guard let url = URL(string: "http://api.open-notify.org/iss-now.json") else { return }
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ISSResponse.self, from: data)
            
            DispatchQueue.main.async {
                self.currentPosition = response.issPosition
                self.error = nil
            }
        } catch {
            DispatchQueue.main.async {
                self.error = error
            }
        }
    }
} 
