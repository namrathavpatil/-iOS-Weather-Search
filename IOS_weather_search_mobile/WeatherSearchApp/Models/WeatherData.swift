import Foundation

struct WeatherInterval: Identifiable {
    let id = UUID()
    let startTime: String
    let status: String
    let image: String
    let temperature: Double
    let temperatureMax: Double
    let temperatureMin: Double
    let temperatureApparent: Double
    let windSpeed: Double
    let windDirection: Double
    let humidity: Double
    let visibility: Double
    let cloudCover: Double
    let precipitationProbability: Double
    let precipitationType: Int
    let pressureSeaLevel: Double
    let moonPhase: Int
    let uvIndex: Int?
    let sunriseTime: String
    let sunsetTime: String
    let lat: Double
    let lng: Double
}
