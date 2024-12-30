    //
//  FavoriteCity.swift
//  WeatherSearchApp
//
//  Created by Namratha V Patil on 12/10/24.
//

import Foundation

struct FavoriteCity: Codable, Identifiable {
    var id: UUID = UUID() // Automatically generated unique ID
    var city: String
    var state: String
    var lat: Double
    var lng: Double
    
    enum CodingKeys: String, CodingKey {
        case city
        case state
        case lat
        case lng
    }
}
