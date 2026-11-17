
import Foundation

struct WeatherCacheService {

    // Cache File Location

    private var cacheFileURL: URL {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        .appendingPathComponent("weather-cache.json")
    }

    // Save Weather Data

    func save(_ weather: WeatherResponse) throws {

        let encoder = JSONEncoder()

        let data = try encoder.encode(weather)

        try data.write(
            to: cacheFileURL,
            options: [.atomic]
        )

        print("Weather data successfully cached.")
    }

    // Load Cached Weather

    func load() throws -> WeatherResponse? {

        guard FileManager.default.fileExists(
            atPath: cacheFileURL.path
        ) else {
            print("No cached weather data found.")
            return nil
        }

        let data = try Data(contentsOf: cacheFileURL)

        let decoder = JSONDecoder()

        let weather = try decoder.decode(
            WeatherResponse.self,
            from: data
        )

        print("Cached weather data successfully loaded.")

        return weather
    }
}
