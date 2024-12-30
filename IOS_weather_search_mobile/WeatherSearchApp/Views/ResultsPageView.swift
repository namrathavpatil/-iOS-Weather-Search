    import SwiftUI
    import Combine
    import CoreLocation

    struct StarStatusResponse: Codable {
        let isStarFilled: Bool
    }
    struct Coordinates {
        let latitude: Double
        let longitude: Double
    }

    struct ResultsPageView: View {
        @Binding var weatherIntervals: [WeatherInterval]
        @Binding var locationData: LocationData?
        @Environment(\.dismiss) private var dismiss
        @State private var showWeatherDetails = false
        @State private var isFavorite = false
        @State private var showToast = false
        @State private var toastMessage = ""
        @State private var favoriteCities: [FavoriteCity] = []
        @State private var currentPage = 0
        @State private var cancellables = Set<AnyCancellable>()
        @StateObject private var weatherService = WeatherService()
        var body: some View {
            ZStack {
                Image("App_background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    // Navigation bar
                    HStack {
                        Button(action: { dismiss() }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Weather")
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Spacer()
                        
                        Text(currentPage == 0 ?
                            (locationData?.city ?? "") :
                            favoriteCities[currentPage - 1].city)
                            .font(.headline)
                        
                        Spacer()
                        HStack(spacing: 25) {
                             Button(action: shareToTwitter) {
                                 Image("twitter")
                                     .resizable()
                                     .frame(width: 30, height: 30)  // Adjust the size of the Twitter icon
                                     .foregroundColor(.blue)
                             }
                         }
                    }
                    .padding()
                    .background(.white)
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
                    // Show current weather first
                    TabView(selection: $currentPage) {
                        // First Tab - Current Weather
                        if !weatherIntervals.isEmpty {
                            VStack {
                                CurrentWeatherView(
                                    interval: weatherIntervals[0],
                                    location: locationData ?? LocationData(city: "City", state: "State", lat: 0, lng: 0)
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
                            .tag(0) // Tagging the first tab
                        }

                        // Favorite Cities Tabs
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


                        }
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
            
            .navigationBarHidden(true)

            .overlay(
                Group {
                    if showToast {
                        VStack {
                            Spacer()
                            Text(toastMessage)
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(10)
                                .padding(.bottom)
                        }
                    }
                }
            )
            .onAppear {
                if let city = locationData?.city {
                    getStarStatus(for: city)
                }
            }
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
        
        private func shareToTwitter() {
            guard let interval = weatherIntervals.first,
                  let city = locationData?.city else { return }
            
            let text = "The current temperature at \(city) is \(Int(interval.temperatureMax))°F,The weather conditions are \(interval.status) #CSC1571WeatherSearch"
            let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            
            if let url = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
                UIApplication.shared.open(url)
            }
        }
    }
