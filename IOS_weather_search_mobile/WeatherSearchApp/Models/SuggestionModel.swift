import Foundation

// Model for a single suggestion returned by the autocomplete API
struct Suggestion: Identifiable, Decodable {
    let id = UUID()  // Make it Identifiable for use in a List
    let description: String  // The suggestion (city name)
}

// Response from the Google Places API with a list of suggestions
struct AutocompleteResponse: Decodable {
    let predictions: [Suggestion]
}
