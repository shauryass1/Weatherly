
import Foundation

struct WeatherResponse: Codable {
    let location: WeatherLocation
    let current: CurrentWeather
    let forecast: ForecastData
}

struct WeatherLocation: Codable {
    let name: String
    let country: String
    let localtime: String
}

struct CurrentWeather: Codable {
    let tempC: Double
    let tempF: Double
    let condition: WeatherCondition
    let windKph: Double
    let windMph: Double
    let humidity: Int
    let feelsLikeC: Double
    let feelsLikeF: Double
    let uv: Double

    enum CodingKeys: String, CodingKey {
        case tempC = "temp_c"
        case tempF = "temp_f"
        case condition
        case windKph = "wind_kph"
        case windMph = "wind_mph"
        case humidity
        case feelsLikeC = "feelslike_c"
        case feelsLikeF = "feelslike_f"
        case uv
    }
}

struct WeatherCondition: Codable {
    let text: String
    let icon: String
    let code: Int
}

struct ForecastData: Codable {
    let forecastday: [ForecastDay]
}

struct ForecastDay: Codable {
    let date: String
    let day: ForecastDayDetails
}

struct ForecastDayDetails: Codable {
    let maxtempC: Double
    let mintempC: Double
    let maxtempF: Double
    let mintempF: Double
    let condition: WeatherCondition

    enum CodingKeys: String, CodingKey {
        case maxtempC = "maxtemp_c"
        case mintempC = "mintemp_c"
        case maxtempF = "maxtemp_f"
        case mintempF = "mintemp_f"
        case condition
    }
}
