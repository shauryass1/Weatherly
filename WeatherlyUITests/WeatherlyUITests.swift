
import XCTest

final class WeatherlyUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testWeatherlyHomepageLaunches() throws {

        let app = XCUIApplication()
        app.launch()

        // Verify the homepage location heading.
        let locationHeading = app.staticTexts["WEATHER LOCATION"]

        XCTAssertTrue(
            locationHeading.waitForExistence(timeout: 10),
            "Weatherly homepage should display WEATHER LOCATION."
        )
    }

    @MainActor
    func testLaunchPerformance() throws {

        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
