import Foundation
@testable import Weatherly
final class MockWeatherService: WeatherProviding {

    var shouldFail = false

    func fetchWeather(
        for location: String,
        days: Int
    ) async throws -> WeatherResponse {

        if shouldFail {
            throw MockWeatherError.simulatedFailure
        }

        let condition = WeatherCondition(
            text: "Sunny",
            icon: "//cdn.weatherapi.com/weather/64x64/day/113.png",
            code: 1000
        )

        let current = CurrentWeather(
            tempC: 22,
            tempF: 71.6,
            condition: condition,
            windKph: 12,
            windMph: 7.5,
            humidity: 45,
            feelsLikeC: 23,
            feelsLikeF: 73.4,
            uv: 5
        )

        let forecastDetails = ForecastDayDetails(
            maxtempC: 25,
            mintempC: 15,
            maxtempF: 77,
            mintempF: 59,
            condition: condition
        )

        let forecastDays = (0..<days).map { offset in

            let date = Calendar.current.date(
                byAdding: .day,
                value: offset,
                to: Date()
            )!

            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"

            return ForecastDay(
                date: formatter.string(from: date),
                day: forecastDetails
            )
        }

        return WeatherResponse(
            location: WeatherLocation(
                name: location,
                country: "Test Country",
                localtime: DateFormatter.localizedString(
                    from: Date(),
                    dateStyle: .short,
                    timeStyle: .short
                )
            ),
            current: current,
            forecast: ForecastData(
                forecastday: forecastDays
            )
        )
    }

    func searchCities(
        query: String
    ) async throws -> [CitySearchResult] {
        return []
    }
}

enum MockWeatherError: Error {
    case simulatedFailure
}
