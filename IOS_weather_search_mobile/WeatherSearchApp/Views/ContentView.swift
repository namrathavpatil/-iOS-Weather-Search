import SwiftUI
import Combine
import CoreLocation




struct ContentView: View {
    @StateObject private var weatherService = WeatherService()
    @State private var searchText = ""  // Default city is Los Angeles
    @State private var weatherIntervals: [WeatherInterval] = []
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showLaunchScreen = true
    @State private var locationData: LocationData?
    @State private var suggestions: [Suggestion] = []
    @State private var showSuggestion = true
    @State private var isLoading = false  // To track loading state
    @State private var showResultsPage = false // Added this to control navigation
    @State private var isBackButtonPressed = false // Track if back is pressed
    @State private var favoriteCities: [FavoriteCity] = []
    @State private var currentPage = 0
    @State private var isFavorite = false
    @State private var toastMessage = ""
    @State private var showToast = false
    @State private var showWeatherDetails = false


    var body: some View {
        NavigationStack {
            ZStack {
                // Background Image
                Image("App_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)

                if showLaunchScreen {
                    LaunchScreen()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    showLaunchScreen = false
                                }
                                print("fgndkgf")
                                fetchWeather()
                                print("dfd")
                                isLoading = true
                                
                                
                            }
                        }
                } else {
                    // Main Content
                    VStack(spacing: 20) {
                        // Search Bar
                        searchBar
                        
                        if showSuggestion && !suggestions.isEmpty {
                            suggestionsDropdown
                        }
                        HStack {
                            Spacer()  // Push the button to the right
                            Button(action: toggleFavorite) {
                                Image(isFavorite ?  "close-circle": "plus-circle")
                                    .resizable()
                                    .frame(width: 40, height: 40)  // Adjust the size of the icon
                                    .foregroundColor(.white)
                                    .padding(10)
                                    .background(Color.clear)
                                    .cornerRadius(20)
                            }
                        }
                       

                        TabView(selection: $currentPage) {
                                       // Current Weather Tab
                            // Weather Information (Only show if data is available)
                            VStack {
                                   if !weatherIntervals.isEmpty {
                                       currentWeatherView
                                       weatherMetricsView
                                       forecastListView
                                   }
                               }
                               .tag(0)
                               .onTapGesture {
                                   showWeatherDetails = true
                               }
                               

                            ForEach(favoriteCities.indices, id: \.self) { index in
                                VStack {
                                    if !weatherIntervals.isEmpty {
                                        CurrentWeatherView(
                                            interval: weatherIntervals[0],
                                            location: LocationData(
                                                city: favoriteCities[index].city,
                                                state: favoriteCities[index].state,
                                                lat: favoriteCities[index].lat,
                                                lng: favoriteCities[index].lng
                                            )
                                        )
                                        .background(.ultraThinMaterial)
                                        .cornerRadius(15)
                                        .padding(.horizontal)
                                        .onTapGesture {
                                            showWeatherDetails = true
                                        }
                                        
                                        WeatherMetricsView(interval: weatherIntervals[0])
                                        ForecastListView(intervals: weatherIntervals)
                                    }
                                }
                                .tag(index + 1) // Tagging each favorite city tab
                            }
                                   }
                                   .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                        
                        
                        Spacer()
                    }
                    .onAppear(perform: loadFavorites)
                    .onChange(of: currentPage) { newPage in
                        // Ensure newPage is within the valid range of favoriteCities indices
                        if !favoriteCities.isEmpty && newPage >= 0 && newPage < favoriteCities.count {
                            fetchWeatherForCity(favoriteCities[newPage])
                        } else {
                            // Optionally, handle out-of-bounds case (e.g., show an error or fetch default weather)
                            print("Invalid page index: \(newPage)")
                        }
                        if newPage == 0 {
                               if let city = locationData?.city {
                                   getStarStatus(for: city)
                               }
                           } else if newPage <= favoriteCities.count {
                               getStarStatus(for: favoriteCities[newPage - 1].city)
                           }
                    }
                    .fullScreenCover(isPresented: $showWeatherDetails) {
                               if currentPage > 0 && !favoriteCities.isEmpty && currentPage <= favoriteCities.count {
                                   WeatherDetailsView(
                                       weatherIntervals: weatherIntervals,
                                       locationData: LocationData(
                                           city: favoriteCities[currentPage - 1].city,
                                           state: favoriteCities[currentPage - 1].state,
                                           lat: favoriteCities[currentPage - 1].lat,
                                           lng: favoriteCities[currentPage - 1].lng
                                       )
                                   )
                               } else if let location = locationData {
                                   WeatherDetailsView(
                                       weatherIntervals: weatherIntervals,
                                       locationData: location
                                   )
                               }
                           }
                }
                  
                if isLoading {
                    ZStack {
                        Color.black.opacity(0.5)
                            .ignoresSafeArea() // Makes the background cover the entire screen
                        
                        LoadingScreen(cityName: searchText)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                NavigationLink(
                    destination: ResultsPageView(
                        weatherIntervals: $weatherIntervals,
                        locationData: $locationData
                    ),
                    isActive: $showResultsPage,
                    label: { EmptyView() }
                )
                .onAppear {
                    if isBackButtonPressed {
                        searchText = "Los Angeles"
                        locationData = LocationData(city: "Los Angeles", state: "CA", lat: 34.0522, lng: -118.2437)
                        showResultsPage = false
                        isLoading = true
                        fetchWeather()
                    }
                    if isBackButtonPressed {
                        isBackButtonPressed = false
                        fetchLosAngelesWeather()
                    }
                }

                
        

               
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Views
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Enter City Name", text: $searchText)
                .onChange(of: searchText) { newValue in
                    if newValue.count > 2 {
                        showSuggestion = true
                        fetchSuggestions()
                    } else {
                        suggestions = []
                        showSuggestion = false
                    }
                }
                .onSubmit {
                    showSuggestion = false
                    suggestions = []
                    fetchWeather()
                }
        }
        .padding()
        .background(.white)
        .cornerRadius(10)
        .padding(.horizontal)
    }
    private func loadFavorites() {
           guard let url = URL(string: "https://ass-3-back3nd.wl.r.appspot.com/get_entries") else { return }
           
           URLSession.shared.dataTask(with: url) { data, _, error in
               guard let data = data, error == nil else {
                   print("Error fetching favorites: \(error?.localizedDescription ?? "Unknown error")")
                   return
               }
               
               do {
                   let favorites = try JSONDecoder().decode([FavoriteCity].self, from: data)
                   DispatchQueue.main.async {
                       self.favoriteCities = favorites
                       if !favorites.isEmpty {
                           fetchWeatherForCity(favorites[0])
                       }
                   }
               } catch {
                   print("Error decoding favorites: \(error.localizedDescription)")
               }
           }.resume()
       }

    private func fetchWeatherForCity(_ city: FavoriteCity) {
        let coordinates = CLLocationCoordinate2D(latitude: city.lat, longitude: city.lng)
        
        // Assuming weatherService is still a class or struct with its own memory management
        weatherService.getWeather(for: coordinates)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [self] completion in
                    if case .failure(let error) = completion {
                        print("Error fetching weather for \(city.city): \(error)")
                    }
                },
                receiveValue: { [self] intervals in
                    self.weatherIntervals = intervals
                }
            )
            .store(in: &cancellables)
    }
    private func toggleFavorite() {
        guard let city = locationData?.city,
              let state = locationData?.state,
              let lat = locationData?.lat,
              let lng = locationData?.lng else { return }
        
        if isFavorite {
            removeFromFavorites(city: city, state: state)
        } else {
            addToFavorites(city: city, state: state, lat: lat, lng: lng)
        }
    }
    
    private var suggestionsDropdown: some View {
        VStack(spacing: 0) {
            if !suggestions.isEmpty && showSuggestion {
                ForEach(suggestions) { suggestion in
                    Text(suggestion.description)
                        .padding(.vertical, 12)
                        .padding(.horizontal)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onTapGesture {
                           
                            searchText = suggestion.description
                            showSuggestion = false
                            suggestions = []
                            isLoading=true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                       // After fetching data
                                      
                            showResultsPage = true
                            fetchWeather()// Show results page after data is fetched
                            }
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .listStyle(.insetGrouped)
        .background(.white.opacity(0.8))
        
        .cornerRadius(10)
     
        .zIndex(1)
        // Add this line to ensure the dropdown appears above other views
    }

    private var currentWeatherView: some View {
        CurrentWeatherView(
            interval: weatherIntervals[0],
            location: locationData ?? LocationData(city: "Los Angeles", state: "CA", lat: 34.0522, lng: -118.2437)
        )
        .frame(maxWidth: 300)
        .background(.ultraThinMaterial)
        .cornerRadius(15)
      
     
  
    }

//    private var weatherMetricsView: some View {
//        WeatherMetricsView(interval: weatherIntervals[0])
//    }
//    .background(Color.clear)
    private var weatherMetricsView: some View {
        WeatherMetricsView(
            interval: weatherIntervals[0]
        )
        .background(Color.clear) // Explicitly set the background to clear
    }

    private var forecastListView: some View {
        ForecastListView(intervals: weatherIntervals)
            .background(.ultraThinMaterial)
            .cornerRadius(15)
            .padding(.horizontal)
    }

    // MARK: - Functions
    private func cityWeatherView(for city: FavoriteCity?) -> some View {
        VStack {
            if !weatherIntervals.isEmpty {
                CurrentWeatherView(
                    interval: weatherIntervals[0],
                    location: LocationData(
                        city: city?.city ?? locationData?.city ?? "",
                        state: city?.state ?? locationData?.state ?? "",
                        lat: city?.lat ?? locationData?.lat ?? 0,
                        lng: city?.lng ?? locationData?.lng ?? 0
                    )
                )
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding(.horizontal)

                WeatherMetricsView(interval: weatherIntervals[0])
                    .background(Color.clear)

                ForecastListView(intervals: weatherIntervals)
                    .background(.ultraThinMaterial)
                    .cornerRadius(15)
                    .padding(.horizontal)
            }
        }
    }
    
    private func getStarStatus(for city: String) {
        guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://ass-3-back3nd.wl.r.appspot.com/get_star_status?city=\(encodedCity)") else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                print("Error fetching star status: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                let response = try JSONDecoder().decode(StarStatusResponse.self, from: data)
                DispatchQueue.main.async {
                    self.isFavorite = response.isStarFilled
                }
            } catch {
                print("Error decoding star status: \(error.localizedDescription)")
            }
        }.resume()
    }
 
 private func addToFavorites(city: String, state: String, lat: Double, lng: Double) {
     guard let url = URL(string: "https://ass-3-back3nd.wl.r.appspot.com/add_entry") else { return }
     
     var request = URLRequest(url: url)
     request.httpMethod = "POST"
     request.setValue("application/json", forHTTPHeaderField: "Content-Type")
     
     let body: [String: Any] = [
         "city": city,
         "state": state,
         "lat": lat,
         "lng": lng,
         "isStarFilled": true
     ]
     
     request.httpBody = try? JSONSerialization.data(withJSONObject: body)
     
     URLSession.shared.dataTask(with: request) { _, _, error in
         DispatchQueue.main.async {
             if error == nil {
                 self.isFavorite = true
                 self.toastMessage = "\(city) added to favorites"
                 self.showToast = true
                 
                 DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                     self.showToast = false
                 }
             }
         }
     }.resume()
 }
 
 private func removeFromFavorites(city: String, state: String) {
     guard let encodedCity = city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let encodedState = state.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "https://ass-3-back3nd.wl.r.appspot.com/delete_entry?city=\(encodedCity)&state=\(encodedState)") else { return }
     
     var request = URLRequest(url: url)
     request.httpMethod = "DELETE"
     
     URLSession.shared.dataTask(with: request) { _, _, error in
         DispatchQueue.main.async {
             if error == nil {
                 self.isFavorite = false
                 self.toastMessage = "\(city) removed from favorites"
                 self.showToast = true
                 
                 DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                     self.showToast = false
                 }
             }
         }
     }.resume()
 }
    func fetchSuggestions() {
        let encodedQuery = searchText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\(encodedQuery)&types=(cities)&key=\(Constants.googleAPIKey)"
        
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else { return }
            
            do {
                let result = try JSONDecoder().decode(AutocompleteResponse.self, from: data)
                DispatchQueue.main.async {
                    self.suggestions = result.predictions
                }
            } catch {
                print("Error fetching suggestions: \(error)")
            }
        }.resume()
    }
    private func fetchLosAngelesWeather() {
        self.searchText = "Los Angeles"
        locationData = LocationData(city: "Los Angeles", state: "CA", lat: 34.0522, lng: -118.2437)
        isLoading = true
        fetchWeather()
    }



    func fetchWeather() {
        weatherService.getCoordinates(for: searchText)
            .flatMap { coordinates in
                // Create and store LocationData instance
                let city = self.searchText
                let state = "CA" // Dummy state for now
                let lat = coordinates.latitude
                let lng = coordinates.longitude
                self.locationData = LocationData(city: city, state: state, lat: lat, lng: lng)
                
                return self.weatherService.getWeather(for: coordinates)
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Error fetching weather: \(error)")
                    }
                },
                receiveValue: { weatherIntervals = $0 }
            )
            .store(in: &cancellables)

        // After fetching the weather, stop loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
            self.weatherIntervals = weatherIntervals
            showSuggestion = false
            suggestions = []
             // Show the results page after fetching weather
        }
    }
}


struct LaunchScreen: View {
    var body: some View {
        VStack {
            Image(systemName: "cloud.sun")
                .font(.system(size: 100))
                .foregroundColor(.black)
            Spacer()
            Image("Powered_by_Tomorrow-Black")
                        .resizable()
                        .frame(width: 300, height: 50)
        }
        .padding(.top, 200)
        .padding(.bottom, 50)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct CurrentWeatherView: View {
    let interval: WeatherInterval
    let location: LocationData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 60))
                
                VStack(alignment: .leading) {
                    Text("\(interval.temperatureMax, specifier: "%.0f")°F")
                        .font(.title)
                    Text(interval.status)
                    Text(location.city.isEmpty ? "Los Angeles" : location.city)
                        .font(.headline)
                }
            }
            .padding(.horizontal, 20)  // Add horizontal padding
                    .padding(.vertical, 25)
                    
            
        }
    }
}
struct WeatherMetricsView: View {
    let interval: WeatherInterval
    
    var body: some View {
        HStack(spacing: 20) {
            MetricItem(
                icon: "drop.fill",
                value: String(format: "%.0f%%", interval.humidity),
                label: "Humidity"
            )
            
            MetricItem(
                icon: "wind",
                value: String(format: "%.2f mph", interval.windSpeed),
                label: "Wind Speed"
            )
            
            MetricItem(
                icon: "eye.fill",
                value: String(format: "%.2f mi", interval.visibility),
                label: "Visibility"
            )
            
            MetricItem(
                icon: "gauge",
                value: String(format: "%.2f inHg", interval.pressureSeaLevel),
                label: "Pressure"
            )
        }
        .padding()
        .font(.system(size: 32))
        .cornerRadius(15)
//        .padding(.horizontal)
        .padding(.horizontal, 15)  // Add horizontal padding
                .padding(.vertical, 15)    // Add vertical padding
        .onAppear {
            // Log data when the view appears
            print("Humidity: \(interval.humidity)%")
            print("Wind Speed: \(interval.windSpeed) mph")
            print("Visibility: \(interval.visibility) mi")
            print("Pressure: \(interval.pressureSeaLevel) inHg")
        }
    }
}



struct MetricItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundColor(.black)
            Text(value)
                .font(.caption)
            Text(label)
                .font(.caption2)
        }
    }
}


struct ForecastListView: View {
    let intervals: [WeatherInterval]
    
    var body: some View {
        VStack {
            ForEach(intervals.prefix(6)) { interval in
                HStack {
                    // Date
                    Text(getDateFromStartTime(interval.startTime))
                        .frame(width: 100, alignment: .leading)
                        .font(.system(size: 14))
                    // Weather Icon
                    Image(interval.status)
                        .resizable()
                        .frame(width: 24, height: 24)
                    
                    // Sunrise/Sunset Times with Icons
                    HStack(spacing: 15) {
                        Text(interval.sunriseTime)
                            .font(.caption)
                        Image("sun-rise")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.orange)
                        
                        Text(interval.sunsetTime)
                            .font(.caption)
                        Image("sun-set")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .padding(.horizontal)
    }

  
}
private func getDateFromStartTime(_ startTime: String) -> String {
    // Split the string at the "T" and return only the date part
    let components = startTime.split(separator: "T")
    
    // Safely unwrap the first component and convert it to a String
    if let datePart = components.first {
        return String(datePart)  // Convert Substring to String
    } else {
        return startTime  // If there is no "T", return the original string
    }
}


