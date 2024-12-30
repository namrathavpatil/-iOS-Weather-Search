//
//  APIResponses.swift
//  WeatherSearchApp
//
//  Created by Namratha V Patil on 12/9/24.
//

import Foundation

// MARK: - Geocoding API Response
struct GeocodingResponse: Decodable {
    struct Result: Decodable {
        struct Geometry: Decodable {
            struct Location: Decodable {
                let lat: Double
                let lng: Double
            }
            let location: Location
        }
        let geometry: Geometry
    }
    let results: [Result]
}

// MARK: - Weather Backend API Response
struct WeatherResponse: Decodable {
    struct Timeline: Decodable {
        struct Interval: Decodable {
            struct Values: Decodable {
                let weatherCode: Int
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
            }
            let startTime: String
            let values: Values
        }
        let intervals: [Interval]
    }
    struct Data: Decodable {
        let timelines: [Timeline]
    }
    let data: Data
}

