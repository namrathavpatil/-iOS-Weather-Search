import SwiftUI
import UIKit
import WebKit

struct HighchartsWebView: UIViewRepresentable {
    let htmlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.scrollView.isScrollEnabled = false
        webView.backgroundColor = .clear
        webView.isOpaque = false
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlString, baseURL: nil)
    }
}
//struct HighchartsTemperatureChartView: UIViewRepresentable {
//    let intervals: [WeatherInterval]
//
//    func makeUIView(context: Context) -> HIChartView {
//        return HIChartView()
//    }
//
//    func updateUIView(_ uiView: HIChartView, context: Context) {
//        uiView.chart = createTemperatureChart()
//    }
//
//    func createTemperatureChart() -> HIChart {
//        let chart = HIChart()
//        chart.type = "arearange" // Set the chart type to 'arearange'
//        
//        let title = HITitle()
//        title.text = "Temperature Range Over Time"
//        chart.title = title
//        
//        // Create the X-axis (e.g., dates)
//        let xAxis = HIXAxis()
//        xAxis.categories = intervals.map { formatDate($0.startTime) }
//        chart.xAxis = xAxis
//        
//        // Create the Y-axis
//        let yAxis = HIYAxis()
//        yAxis.title = HITitle()
//        yAxis.title?.text = "Temperature (°F)"
//        chart.yAxis = yAxis
//        
//        // Create the area range series with min and max temperatures
//        let series = HISeries()
//        series.name = "Temperature Range"
//        series.type = "arearange"
//        
//        // Data in the format: [[minValue, maxValue], ...]
//        let data: [[Any]] = intervals.map {
//            [ $0.temperatureMin, $0.temperatureMax ]
//        }
//        
//        series.data = data
//        chart.series = [series]
//        
//        return chart
//    }
////    
//    func formatDate(_ dateString: String) -> String {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
//        if let date = formatter.date(from: dateString) {
//            formatter.dateFormat = "MMM dd"
//            return formatter.string(from: date)
//        }
//        return ""
//    }
//}


struct WeatherDetailsView: View {
    let weatherIntervals: [WeatherInterval]
    let locationData: LocationData
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    
    var body: some View {
     
        VStack(spacing: 0) {
            // Navigation Bar
            HStack {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "chevron.left")
                              Text("Weather")
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
                Text(locationData.city)
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
            
            // Tab View
            TabView(selection: $selectedTab) {
                TodayTabView(interval: weatherIntervals[0])
                    .tabItem {
                        Image("Today_Tab")
                        Text("TODAY")
                    }
                    .tag(0)
                
                WeeklyTabView(intervals: weatherIntervals)
                    .tabItem {
                        Image("Weekly_Tab")
                        Text("WEEKLY")
                    }
                    .tag(1)
                
                WeatherDataTabView(interval: weatherIntervals[1])
                    .tabItem {
                        Image("Weather_Data_Tab")
                        Text("WEATHER DATA")
                    }
                    .tag(2)
            }
        }
     
    }
    
    private func shareToTwitter() {
        let text = "The current temperature at  \(locationData.city) is \(Int(weatherIntervals[0].temperatureMax))°F,The weather conditions are \(weatherIntervals[0].status) #CSC1571WeatherSearch"
//        let text = "The current temperature at \(city) is \(Int(interval.temperatureMax))°F,The weather conditions are \(interval.status) #CSC1571WeatherSearch"
        let encodedText = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            UIApplication.shared.open(url)
        }
    }
}

struct TodayTabView: View {
    let interval: WeatherInterval
    
    var body: some View {
        ZStack {
            Image("App_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            ScrollView {
                VStack(spacing: 20) {
                    // Display weather data cards
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                        WeatherDataCard(icon: "wind", value: String(format: "%.2f", interval.windSpeed), unit: "mph", title: "Wind Speed")
                        WeatherDataCard(icon: "gauge", value: String(format: "%.2f", interval.pressureSeaLevel), unit: "inHG", title: "Pressure")
                        WeatherDataCard(icon: "cloud.rain", value: "\(Int(interval.precipitationProbability))", unit: "%", title: "Precipitation")
                        WeatherDataCard(icon: "thermometer", value: "\(Int(interval.temperatureMax))", unit: "°F", title: "Temperature")
                        WeatherDataCard(icon: "cloud", value: interval.status, unit: "", title: "Condition")
                        WeatherDataCard(icon: "drop.fill", value: "\(Int(interval.humidity))", unit: "%", title: "Humidity")
                        WeatherDataCard(icon: "eye", value: String(format: "%.2f", interval.visibility), unit: "mi", title: "Visibility")
                        WeatherDataCard(icon: "cloud.fill", value: "\(Int(interval.cloudCover))", unit: "%", title: "Cloud Cover")
                        WeatherDataCard(icon: "sun.max", value: "2", unit: "", title: "UV Index")
                        
                    }
                    .padding()
                    
                    
                    // HighCharts Temperature Range Chart
                    //                HighchartsTemperatureChartView(intervals: [interval])
                    //                    .frame(height: 300)
                    //                    .padding()
                    //                    .cornerRadius(15)
                    //                    .background(Color.white.opacity(0.1))
                }
                //            .padding()
             
                .padding(.horizontal, 15)  // Add horizontal padding
                              .padding(.vertical, 30)
            }
        }
    }
}

struct WeeklyTabView: View {
    let intervals: [WeatherInterval]
    
    var body: some View {
        ZStack {
            Image("App_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Current Weather Summary
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 60))
                        VStack(alignment: .leading) {
                            Text("\(Int(intervals[0].temperatureMax))°F")
                                .font(.system(size: 40))
                            Text(intervals[0].status)
                                .font(.title2)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.ultraThinMaterial)
                //            .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Highcharts Temperature Chart
                HighchartsWebView(htmlString: generateHighchartsHTML())
                    .frame(height: 350)
                    .padding()
                    .background(.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
            }
            
            .background(Color.blue.opacity(0.1))
        }
    }
    private func generateHighchartsHTML() -> String {
        let chartData = intervals.prefix(7).map { interval -> String in
            """
            {
                low: \(interval.temperatureMin),
                high: \(interval.temperatureMax),
                date: '\(formatDate(interval.startTime))'
            }
            """
        }.joined(separator: ",")
        
        return """
        <html>
        <head>
            <script src="https://code.highcharts.com/highcharts.js"></script>
            <script src="https://code.highcharts.com/highcharts-more.js"></script>
            <style>
                body { margin: 0; background: transparent; }
                #container { width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <div id="container"></div>
            <script>
                Highcharts.chart('container', {
                    chart: {
                        type: 'arearange',
                        backgroundColor: 'transparent'
                    },
                    title: {
                        text: 'Temperature Variation'
                    },
                    xAxis: {
                        type: 'category',
                        labels: { style: { color: '#000' } }
                    },
                    yAxis: {
                        title: { text: 'Temperature (°F)' }
                    },
                    tooltip: {
                        crosshairs: true,
                        shared: true,
                        valueSuffix: '°F'
                    },
                    legend: { enabled: false },
                    series: [{
                        name: 'Temperature',
                        data: [\(chartData)],
                        color: '#FF9933',
                        fillColor: {
                            linearGradient: { x1: 0, x2: 0, y1: 0, y2: 1 },
                            stops: [
                                [0, 'rgba(255,153,51,0.5)'],
                                [1, 'rgba(102,204,255,0.5)']
                            ]
                        }
                    }]
                });
            </script>
        </body>
        </html>
        """
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        guard let date = formatter.date(from: dateString) else { return dateString }
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }
}



struct WeatherDataCard: View {
    let icon: String
    let value: String
    let unit: String
    let title: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(.black)
            Text("\(value)\(unit)")
                .font(.system(size: 16, weight: .medium))
            Text(title)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}
struct WeatherDataTabView: View {
    let interval: WeatherInterval
    
    var body: some View {
        ZStack {
            Image("App_background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Key Data Summary
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "cloud.rain.fill")
                            .font(.system(size: 24))
                        Text("Precipitation: \(Int(interval.precipitationProbability))%")
                            .font(.title3)
                    }
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 24))
                        Text("Humidity: \(Int(interval.humidity))%")
                            .font(.title3)
                    }
                    
                    HStack {
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 24))
                        Text("Cloud Cover: \(Int(interval.cloudCover))%")
                            .font(.title3)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(15)
                .padding(.horizontal)
                
                // Activity Gauge Chart
                HighchartsWebView(htmlString: generateGaugeChartHTML())
                    .frame(height: 300)
                    .padding()
                    .background(.white)
                    .cornerRadius(15)
                    .padding(.horizontal)
            }
//            .background(Color.blue.opacity(0.1))
        }
    }
    private func generateGaugeChartHTML() -> String {
        """
        <html>
        <head>
            <script src="https://code.highcharts.com/highcharts.js"></script>
            <script src="https://code.highcharts.com/highcharts-more.js"></script>
            <script src="https://code.highcharts.com/modules/solid-gauge.js"></script>
            <style>
                body { margin: 0; background: transparent; }
                #container { width: 100%; height: 110%; }
            </style>
        </head>
        <body>
            <div id="container"></div>
            <script>
                Highcharts.chart('container', {
                    chart: {
                        type: 'solidgauge',
                        height: '110%',
                        backgroundColor: 'transparent'
                    },
                    title: {
                        text: 'Weather Data',
                        style: { fontSize: '24px' }
                    },
                    tooltip: {
                        borderWidth: 0,
                        backgroundColor: 'none',
                        shadow: false,
                        style: { fontSize: '16px' },
                        valueSuffix: '%',
                        pointFormat: '{series.name}<br><span style="font-size:2em; color: {point.color}; font-weight: bold">{point.y}</span>',
                        positioner: function (labelWidth) {
                            return {
                                x: (this.chart.chartWidth - labelWidth) / 2,
                                y: (this.chart.plotHeight / 2) + 15
                            };
                        }
                    },
                    pane: {
                        startAngle: 0,
                        endAngle: 360,
                        background: [{
                            outerRadius: '112%',
                            innerRadius: '88%',
                            backgroundColor: 'rgba(124, 181, 236, 0.3)',
                            borderWidth: 0
                        }, {
                            outerRadius: '87%',
                            innerRadius: '63%',
                            backgroundColor: 'rgba(67, 67, 72, 0.3)',
                            borderWidth: 0
                        }, {
                            outerRadius: '62%',
                            innerRadius: '38%',
                            backgroundColor: 'rgba(144, 237, 125, 0.3)',
                            borderWidth: 0
                        }]
                    },
                    yAxis: {
                        min: 0,
                        max: 100,
                        lineWidth: 0,
                        tickPositions: []
                    },
                    plotOptions: {
                        solidgauge: {
                            dataLabels: {
                                enabled: false
                            },
                            linecap: 'round',
                            stickyTracking: false,
                            rounded: true
                        }
                    },
                    series: [{
                        name: 'Cloud Cover',
                        data: [{
                            color: '#89ce3e',
                            radius: '112%',
                            innerRadius: '88%',
                            y: \(interval.cloudCover)
                        }]
                    }, {
                        name: 'Humidity',
                        data: [{
                            color: '#7db3f9',
                            radius: '87%',
                            innerRadius: '63%',
                            y: \(interval.humidity)
                        }]
                    }, {
                        name: 'Precipitation',
                        data: [{
                            color: '#ef7976',
                            radius: '62%',
                            innerRadius: '38%',
                            y: \(interval.precipitationProbability)
                        }]
                    }]
                });
            </script>
        </body>
        </html>
        """
    }
}



struct DataSummaryItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 30))
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
        }
    }
}
