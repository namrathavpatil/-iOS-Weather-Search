import Foundation

struct LocationData: Identifiable {
    var id = UUID()
    var city: String
    var state: String
    var lat: Double
    var lng: Double
}

