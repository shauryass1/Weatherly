
import XCTest
@testable import Weatherly

@MainActor
final class WeatherViewModelTests: XCTestCase {

    func testWeatherLoadsFromMockService() async {

        // Arrange: Create a mock weather service.
        let mockService = MockWeatherService()

        // Inject it into the ViewModel.
        let viewModel = WeatherViewModel(
            weatherService: mockService
        )

        // Act: Load weather without using the real API.
        await viewModel.loadWeather(for: "Kassel")

        // Assert: Check the displayed weather values.
        XCTAssertEqual(viewModel.cityName, "Kassel")
        XCTAssertEqual(viewModel.country, "Test Country")
        XCTAssertEqual(viewModel.temperature, 22)
        XCTAssertEqual(viewModel.condition, "Sunny")
        XCTAssertEqual(viewModel.humidity, 45)
        XCTAssertEqual(viewModel.windSpeed, 12)
        XCTAssertEqual(viewModel.feelsLike, 23)
        XCTAssertEqual(viewModel.forecasts.count, 3)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testTemperatureChangesToFahrenheit() async {

        let mockService = MockWeatherService()

        let viewModel = WeatherViewModel(
            weatherService: mockService
        )

        await viewModel.loadWeather(for: "Kassel")

        viewModel.updateUnits(
            temperatureUnit: "F",
            windSpeedUnit: "km/h"
        )

        XCTAssertEqual(viewModel.temperature, 72)
        XCTAssertEqual(viewModel.feelsLike, 73)
    }
}
