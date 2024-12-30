import Foundation
import Combine
import CoreLocation

class WeatherService: ObservableObject {
    @Published var weatherIntervals: [WeatherInterval] = [] // Use @Published for UI binding

    func getCoordinates(for address: String) -> AnyPublisher<CLLocationCoordinate2D, Error> {
        let address = address.isEmpty ? "Los Angeles" : address
        let encodedAddress = address.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = "\(Constants.googleGeocodingURL)?address=\(encodedAddress)&key=\(Constants.googleAPIKey)"

        return URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
            .map(\.data)
            .decode(type: GeocodingResponse.self, decoder: JSONDecoder())
            .compactMap { response in
                if let location = response.results.first?.geometry.location {
                    return CLLocationCoordinate2D(latitude: location.lat, longitude: location.lng)
                }
                return nil
            }
            .eraseToAnyPublisher()
    }

    func getWeather(for coordinates: CLLocationCoordinate2D) -> AnyPublisher<[WeatherInterval], Error> {
        let url = "\(Constants.weatherBackendURL)?lat=\(coordinates.latitude)&lng=\(coordinates.longitude)"
        print(url)

        return URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
            .map(\.data)
            .decode(type: WeatherResponse.self, decoder: JSONDecoder())
            .map { response in
                response.data.timelines[0].intervals.map { interval in
                    WeatherInterval(
                        startTime: WeatherService.formatTiming(interval.startTime, format: "MM/dd/yyyy"),
                        status: WeatherService.weatherDescription[interval.values.weatherCode] ?? "Unknown",
                        image: WeatherService.codeToImage[interval.values.weatherCode] ?? "",
                        temperature: interval.values.temperature,
                        temperatureMax: interval.values.temperatureMax,
                        temperatureMin: interval.values.temperatureMin,
                        temperatureApparent: interval.values.temperatureApparent,
                        windSpeed: interval.values.windSpeed,
                        windDirection: interval.values.windDirection,
                        humidity: interval.values.humidity,
                        visibility: interval.values.visibility,
                        cloudCover: interval.values.cloudCover,
                        precipitationProbability: interval.values.precipitationProbability,
                        precipitationType: interval.values.precipitationType,
                        pressureSeaLevel: interval.values.pressureSeaLevel,
                        moonPhase: interval.values.moonPhase,
                        uvIndex: interval.values.uvIndex,
                        sunriseTime: WeatherService.formatTiming(interval.values.sunriseTime, format: "h:mm a"),
                        sunsetTime: WeatherService.formatTiming(interval.values.sunsetTime, format: "h:mm a"),
                        lat: coordinates.latitude,
                        lng: coordinates.longitude
                    )
                }
            }
            .eraseToAnyPublisher()
    }

//    static func formatTiming(_ timing: String, format: String) -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
//        dateFormatter.timeZone = TimeZone(identifier: "UTC")
//        
//        guard let date = dateFormatter.date(from: timing) else {
//            return timing
//        }
//        
//        dateFormatter.dateFormat = format
//        dateFormatter.timeZone = TimeZone.current
//        return dateFormatter.string(from: date)
//    }
    static func formatTiming(_ timing: String, format: String) -> String {
        let dateFormatter = DateFormatter()
        // Assuming input format contains time portion that we want to ignore
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(identifier: "UTC")  // Assuming the input is in UTC
        
        // Parse the input timing string
        guard let date = dateFormatter.date(from: timing) else {
            return timing  // Return original if parsing fails
        }
        
        // Now format it to the desired format (e.g., only date)
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = TimeZone.current  // Use the current time zone for output
        
        return dateFormatter.string(from: date)
    }



    static let weatherDescription: [Int: String] = [
        4201: "Heavy Rain",
        4001: "Rain",
        4200: "Light Rain",
        6201: "Heavy Freezing Rain",
        6001: "Freezing Rain",
        6200: "Light Freezing Rain",
        6000: "Freezing Drizzle",
        4000: "Drizzle",
        7101: "Heavy Ice Pellets",
        7000: "Ice Pellets",
        7102: "Light Ice Pellets",
        5101: "Heavy Snow",
        5000: "Snow",
        5100: "Light Snow",
        5001: "Flurries",
        8000: "Thunderstorm",
        2100: "Light Fog",
        2000: "Fog",
        1001: "Cloudy",
        1102: "Mostly Cloudy",
        1101: "Partly Cloudy",
        1100: "Mostly Clear",
        1000: "Clear"
    ]

    static let codeToImage: [Int: String] = [
        1000: "sun.max.fill",
        1001: "cloud.fill",
        1100: "cloud.sun.fill",
        1101: "cloud.sun.fill",
        1102: "cloud.fill",
        2000: "cloud.fog.fill",
        2100: "cloud.fog.fill",
        4000: "cloud.drizzle.fill",
        4001: "cloud.rain.fill",
        4200: "cloud.rain.fill",
        4201: "cloud.heavyrain.fill",
        5000: "cloud.snow.fill",
        5001: "cloud.snow.fill",
        5100: "cloud.snow.fill",
        5101: "cloud.snow.fill",
        6000: "cloud.sleet.fill",
        6001: "cloud.sleet.fill",
        6200: "cloud.sleet.fill",
        6201: "cloud.sleet.fill",
        7000: "cloud.hail.fill",
        7101: "cloud.hail.fill",
        7102: "cloud.hail.fill",
        8000: "cloud.bolt.rain.fill"
    ]

}
