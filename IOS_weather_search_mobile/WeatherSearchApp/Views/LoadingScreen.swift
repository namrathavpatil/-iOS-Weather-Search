import SwiftUI
import SwiftSpinner

// Create a UIViewRepresentable wrapper for SwiftSpinner
struct SwiftSpinnerView: UIViewRepresentable {
    let message: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        SwiftSpinner.show(message)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates necessary, as the spinner is shown when this view is created
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: ()) {
        SwiftSpinner.hide()
    }
}

struct LoadingScreen: View {
    let cityName: String
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Background with blue gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.7),
                    Color.blue.opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Centered content
            VStack {
                Text("Fetching\nWeather Details\nfor \(cityName.isEmpty ? "Los Angeles" : cityName)...")
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .font(.system(size: 18))

                Spacer()

                if isLoading {
                    // Using SwiftSpinnerView for displaying the loading spinner
                    SwiftSpinnerView(message:"Fetching\nWeather Details\nfor \(cityName.isEmpty ? "Los Angeles" : cityName)...")
                        .frame(width: 100, height: 100) // Set a frame size for the spinner
                }
            }
            .padding(40)
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 200, height: 200)
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            // Simulate an async operation to show loading spinner
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isLoading = false  // Simulate operation completion
            }
        }
    }
}
