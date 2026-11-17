
import Foundation
import CoreLocation
import Observation

struct ForecastItem: Identifiable {
    let id = UUID()
    let day: String
    let icon: String
    let high: String
    let low: String
}

@Observable
@MainActor
final class WeatherViewModel {

    //  Services

    private let weatherService: any WeatherProviding
    private let locationManager = LocationManager()
    private let cacheService = WeatherCacheService()

    private var latestWeatherResponse: WeatherResponse?

    init(weatherService: any WeatherProviding = WeatherService()) {
        self.weatherService = weatherService
    }

    // Unit Preferences

    var temperatureUnit = "C"
    var windSpeedUnit = "km/h"

    // MARK: - Weather Properties

    var cityName = "Finding your location..."
    var country = ""

    var temperature = 0
    var condition = "Loading..."
    var weatherIcon = "cloud.sun.fill"

    var highTemperature = 0
    var lowTemperature = 0

    var humidity = 0
    var windSpeed = 0
    var feelsLike = 0
    var uvIndex = 0

    var forecasts: [ForecastItem] = []
    var dateText = ""

    var isLoading = false
    var errorMessage: String?

    // Load Current Location Weather

    func loadWeather() async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let currentLocation = try await locationManager.requestCurrentLocation()

            let latitude = currentLocation.coordinate.latitude
            let longitude = currentLocation.coordinate.longitude

            let coordinates = "\(latitude),\(longitude)"

            print("Requesting weather for coordinates:", coordinates)

            let weather = try await weatherService.fetchWeather(
                for: coordinates,
                days: 3
            )

            updateWeather(with: weather)
            saveWeatherToCache(weather)

        } catch {
            print("Weather loading error:", error.localizedDescription)
            restoreCachedWeather(after: error)
        }
    }

    // Load Weather for Selected City

    func loadWeather(for location: String) async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            print("Requesting weather for saved location:", location)

            let weather = try await weatherService.fetchWeather(
                for: location,
                days: 3
            )

            updateWeather(with: weather)
            saveWeatherToCache(weather)

        } catch {
            print("Weather loading error:", error.localizedDescription)
            restoreCachedWeather(after: error)
        }
    }

    // Save Weather to Cache

    private func saveWeatherToCache(_ weather: WeatherResponse) {

        do {
            try cacheService.save(weather)
            print("Weather successfully saved to local cache.")
        } catch {
            print("Could not save weather cache:", error.localizedDescription)
        }
    }

    // Restore Cached Weather

    private func restoreCachedWeather(after originalError: Error) {

        do {
            if let cachedWeather = try cacheService.load() {
                updateWeather(with: cachedWeather)
                errorMessage = nil
                print("Displaying previously cached weather.")
            } else {
                errorMessage = originalError.localizedDescription
            }
        } catch {
            print("Could not restore weather cache:", error.localizedDescription)
            errorMessage = originalError.localizedDescription
        }
    }

    // Update Unit Preferences

    func updateUnits(
        temperatureUnit: String,
        windSpeedUnit: String
    ) {

        self.temperatureUnit = temperatureUnit
        self.windSpeedUnit = windSpeedUnit

        if let weather = latestWeatherResponse {
            updateWeather(with: weather)
        }
    }

    // Update Weather Display

    private func updateWeather(with weather: WeatherResponse) {

        latestWeatherResponse = weather

        cityName = weather.location.name
        country = weather.location.country

        if temperatureUnit == "F" {
            temperature = Int(weather.current.tempF.rounded())
            feelsLike = Int(weather.current.feelsLikeF.rounded())
        } else {
            temperature = Int(weather.current.tempC.rounded())
            feelsLike = Int(weather.current.feelsLikeC.rounded())
        }

        condition = weather.current.condition.text
        humidity = weather.current.humidity

        if windSpeedUnit == "mph" {
            windSpeed = Int(weather.current.windMph.rounded())
        } else {
            windSpeed = Int(weather.current.windKph.rounded())
        }

        uvIndex = Int(weather.current.uv.rounded())

        if let today = weather.forecast.forecastday.first {

            if temperatureUnit == "F" {
                highTemperature = Int(today.day.maxtempF.rounded())
                lowTemperature = Int(today.day.mintempF.rounded())
            } else {
                highTemperature = Int(today.day.maxtempC.rounded())
                lowTemperature = Int(today.day.mintempC.rounded())
            }
        }

        dateText = formatDate(weather.location.localtime)

        weatherIcon = systemIcon(
            for: weather.current.condition.text
        )

        forecasts = weather.forecast.forecastday.map { day in

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            let date = formatter.date(from: day.date)

            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEE"

            let high: Int
            let low: Int

            if temperatureUnit == "F" {
                high = Int(day.day.maxtempF.rounded())
                low = Int(day.day.mintempF.rounded())
            } else {
                high = Int(day.day.maxtempC.rounded())
                low = Int(day.day.mintempC.rounded())
            }

            return ForecastItem(
                day: date.map {
                    dayFormatter.string(from: $0).uppercased()
                } ?? day.date,
                icon: systemIcon(for: day.day.condition.text),
                high: "\(high)°",
                low: "\(low)°"
            )
        }

        print("Weather successfully loaded for \(cityName)")
    }

    // Format Date

    private func formatDate(_ value: String) -> String {

        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd HH:mm"

        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .full

        guard let date = inputFormatter.date(from: value) else {
            return value
        }

        return outputFormatter.string(from: date)
    }

    // Weather Condition Icons

    private func systemIcon(for condition: String) -> String {

        let value = condition.lowercased()

        if value.contains("thunder") {
            return "cloud.bolt.rain.fill"
        }

        if value.contains("rain") || value.contains("drizzle") {
            return "cloud.rain.fill"
        }

        if value.contains("snow") || value.contains("sleet") {
            return "cloud.snow.fill"
        }

        if value.contains("mist") || value.contains("fog") {
            return "cloud.fog.fill"
        }

        if value.contains("cloudy") {
            return "cloud.fill"
        }

        if value.contains("overcast") {
            return "smoke.fill"
        }

        if value.contains("sun") || value.contains("clear") {
            return "sun.max.fill"
        }

        return "cloud.sun.fill"
    }
}
