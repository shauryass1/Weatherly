
import Foundation

protocol WeatherProviding {

    func fetchWeather(
        for location: String,
        days: Int
    ) async throws -> WeatherResponse

    func searchCities(
        query: String
    ) async throws -> [CitySearchResult]
}

// WeatherService adopts the protocol.
extension WeatherService: WeatherProviding {
}
