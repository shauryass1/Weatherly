
import SwiftUI
import SwiftData

@main
struct WeatherlyApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FavoriteLocation.self)
    }
}
