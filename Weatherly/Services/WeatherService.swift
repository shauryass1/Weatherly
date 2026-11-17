
import Foundation

// Weather Service

struct WeatherService {

    // Fetch Weather

    func fetchWeather(
        for location: String,
        days: Int = 3
    ) async throws -> WeatherResponse {

        var components = URLComponents(
            string: "\(APIConfig.baseURL)/forecast.json"
        )!

        components.queryItems = [
            URLQueryItem(name: "key", value: APIConfig.weatherAPIKey),
            URLQueryItem(name: "q", value: location),
            URLQueryItem(name: "days", value: String(days)),
            URLQueryItem(name: "aqi", value: "no"),
            URLQueryItem(name: "alerts", value: "no")
        ]

        guard let url = components.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {

            let apiError = try? JSONDecoder().decode(
                WeatherAPIErrorResponse.self,
                from: data
            )

            throw WeatherServiceError.apiError(
                apiError?.error.message ??
                "Weather API request failed: \(httpResponse.statusCode)"
            )
        }

        do {
            return try JSONDecoder().decode(
                WeatherResponse.self,
                from: data
            )
        } catch {
            throw WeatherServiceError.decodingError
        }
    }

    // Search Cities

    func searchCities(
        query: String
    ) async throws -> [CitySearchResult] {

        var components = URLComponents(
            string: "\(APIConfig.baseURL)/search.json"
        )!

        components.queryItems = [
            URLQueryItem(name: "key", value: APIConfig.weatherAPIKey),
            URLQueryItem(name: "q", value: query)
        ]

        guard let url = components.url else {
            throw WeatherServiceError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {

            let apiError = try? JSONDecoder().decode(
                WeatherAPIErrorResponse.self,
                from: data
            )

            throw WeatherServiceError.apiError(
                apiError?.error.message ??
                "City search failed: \(httpResponse.statusCode)"
            )
        }

        do {
            return try JSONDecoder().decode(
                [CitySearchResult].self,
                from: data
            )
        } catch {
            throw WeatherServiceError.decodingError
        }
    }
}

// API Error Response

struct WeatherAPIErrorResponse: Decodable {
    let error: APIErrorDetails
}

struct APIErrorDetails: Decodable {
    let message: String
}

struct APIErrorDetailsWrapper: Decodable {
    let error: APIErrorDetails
}

// Service Errors

enum WeatherServiceError: LocalizedError {

    case invalidURL
    case invalidResponse
    case decodingError
    case apiError(String)

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "Invalid weather API URL."

        case .invalidResponse:
            return "Invalid server response."

        case .decodingError:
            return "Unable to process weather data."

        case .apiError(let message):
            return message
        }
    }
}
