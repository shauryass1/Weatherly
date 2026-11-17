
import SwiftUI
import SwiftData

struct ContentView: View {

    // ViewModel and Data

    @State private var viewModel = WeatherViewModel()

    @Environment(\.modelContext) private var modelContext

    @Query private var favoriteLocations: [FavoriteLocation]

    @State private var showingAddFavorite = false
    @State private var showingSettings = false

    // Preferences saved automatically using UserDefaults

    @AppStorage("temperatureUnit") private var temperatureUnit = "C"
    @AppStorage("windSpeedUnit") private var windSpeedUnit = "km/h"

    // Homepage City Search

    @State private var searchText = ""
    @State private var suggestions: [CitySearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?

    private let weatherService = WeatherService()

    var body: some View {
        ZStack {

            // Background

            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.17, blue: 0.34),
                    Color(red: 0.04, green: 0.09, blue: 0.20)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {

                VStack(spacing: 28) {

                    // Location Header

                    HStack {

                        VStack(alignment: .leading, spacing: 5) {

                            Text("WEATHER LOCATION")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.6))

                            HStack(spacing: 6) {

                                Image(systemName: "location.fill")

                                Text(
                                    "\(viewModel.cityName), \(viewModel.country)"
                                )
                            }
                            .font(.title2)
                            .fontWeight(.bold)
                        }

                        Spacer()

                        // Settings button

                        Button {
                            showingSettings = true
                        } label: {

                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(13)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Weather settings")

                        // Return to GPS weather

                        Button {
                            Task {
                                await viewModel.loadWeather()
                            }
                        } label: {

                            Image(systemName: "location.north.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.white)
                                .padding(13)
                                .background(.white.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Show my current location weather")
                    }

                    // Homepage City Search

                    VStack(alignment: .leading, spacing: 10) {

                        HStack {

                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.6))

                            TextField(
                                "Search any city...",
                                text: $searchText
                            )
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .foregroundStyle(.white)

                            if !searchText.isEmpty {

                                Button {
                                    searchText = ""
                                    suggestions = []
                                    searchError = nil
                                } label: {

                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white.opacity(0.6))
                                }
                            }
                        }
                        .padding(15)
                        .background(.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                        if isSearching {

                            HStack {
                                ProgressView()
                                    .tint(.white)

                                Text("Searching cities...")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                            .padding(.vertical, 5)

                        } else if let searchError {

                            Text(searchError)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                                .padding(.vertical, 5)

                        } else if !suggestions.isEmpty {

                            VStack(spacing: 0) {

                                ForEach(suggestions) { city in

                                    Button {

                                        Task {
                                            await selectCity(city)
                                        }

                                    } label: {

                                        HStack {

                                            Image(systemName: "mappin.circle.fill")
                                                .font(.title3)
                                                .foregroundStyle(.white.opacity(0.8))

                                            VStack(alignment: .leading, spacing: 3) {

                                                Text(city.name)
                                                    .font(.headline)
                                                    .foregroundStyle(.white)

                                                Text(
                                                    city.region.isEmpty
                                                    ? city.country
                                                    : "\(city.region), \(city.country)"
                                                )
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.6))
                                            }

                                            Spacer()

                                            Image(systemName: "arrow.up.left")
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                        .padding(12)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    if city.id != suggestions.last?.id {
                                        Divider()
                                            .overlay(.white.opacity(0.15))
                                    }
                                }
                            }
                            .background(.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }

                    // Current Weather

                    VStack(spacing: 12) {

                        Text(viewModel.dateText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))

                        Image(systemName: viewModel.weatherIcon)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.yellow, .white)
                            .font(.system(size: 85))
                            .padding(.vertical, 8)

                        Text("\(viewModel.temperature)°")
                            .font(.system(size: 86, weight: .thin))
                            .foregroundStyle(.white)

                        Text(viewModel.condition)
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)

                        Text(
                            "H: \(viewModel.highTemperature)°   L: \(viewModel.lowTemperature)°"
                        )
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                    }
                    .frame(maxWidth: .infinity)

                    // Loading Indicator

                    if viewModel.isLoading {

                        ProgressView("Fetching weather...")
                            .tint(.white)
                            .foregroundStyle(.white)
                    }

                    // Error Message

                    if let error = viewModel.errorMessage {

                        VStack(spacing: 12) {

                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)

                            Text(error)
                                .font(.footnote)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)

                            Button {

                                Task {
                                    await viewModel.loadWeather()
                                }

                            } label: {

                                Label(
                                    "Try Current Location Again",
                                    systemImage: "arrow.clockwise"
                                )
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.white.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }

                    // Weather Details

                    VStack(alignment: .leading, spacing: 15) {

                        Text("WEATHER DETAILS")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.6))

                        HStack(spacing: 12) {

                            MetricCard(
                                title: "Humidity",
                                value: "\(viewModel.humidity)%",
                                icon: "humidity.fill"
                            )

                            MetricCard(
                                title: "Wind",
                                value: "\(viewModel.windSpeed) \(viewModel.windSpeedUnit)",
                                icon: "wind"
                            )
                        }

                        HStack(spacing: 12) {

                            MetricCard(
                                title: "Feels Like",
                                value: "\(viewModel.feelsLike)°",
                                icon: "thermometer.medium"
                            )

                            MetricCard(
                                title: "UV Index",
                                value: "\(viewModel.uvIndex)",
                                icon: "sun.max.fill"
                            )
                        }
                    }

                    // Three Day Forecast

                    VStack(alignment: .leading, spacing: 15) {

                        Text("3-DAY FORECAST")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.6))

                        if viewModel.forecasts.isEmpty && viewModel.isLoading {

                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding()

                        } else {

                            HStack(spacing: 10) {

                                ForEach(viewModel.forecasts) { forecast in

                                    ForecastCard(
                                        day: forecast.day,
                                        icon: forecast.icon,
                                        high: forecast.high,
                                        low: forecast.low
                                    )
                                }
                            }
                        }
                    }

                    // Favorite Locations

                    VStack(alignment: .leading, spacing: 15) {

                        HStack {

                            Text("FAVORITE LOCATIONS")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.6))

                            Spacer()

                            Button {
                                showingAddFavorite = true
                            } label: {

                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                            }
                            .accessibilityLabel("Add favorite city")
                        }

                        if favoriteLocations.isEmpty {

                            Text("Add your favorite cities to see them here.")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                                .padding(.vertical, 8)

                        } else {

                            ForEach(favoriteLocations) { favorite in

                                HStack {

                                    // Select favorite city

                                    Button {

                                        Task {
                                            await viewModel.loadWeather(
                                                for: favorite.query
                                            )
                                        }

                                    } label: {

                                        HStack {

                                            Image(systemName: "mappin.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(.white.opacity(0.8))

                                            VStack(alignment: .leading, spacing: 4) {

                                                Text(favorite.name)
                                                    .font(.headline)
                                                    .foregroundStyle(.white)

                                                Text(favorite.country)
                                                    .font(.caption)
                                                    .foregroundStyle(.white.opacity(0.6))
                                            }

                                            Spacer()

                                            Image(systemName: "chevron.right")
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)

                                    // Delete favorite city

                                    Button(role: .destructive) {

                                        modelContext.delete(favorite)

                                    } label: {

                                        Image(systemName: "trash")
                                            .font(.body)
                                            .foregroundStyle(.red)
                                            .padding(10)
                                    }
                                    .accessibilityLabel(
                                        "Remove \(favorite.name) from favorites"
                                    )
                                }
                                .padding(10)
                                .background(.white.opacity(0.10))
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                            }
                        }
                    }
                }
                .padding(22)
            }
            .refreshable {
                await viewModel.loadWeather()
            }
        }
        .preferredColorScheme(.dark)

        // Add Favorite Sheet

        .sheet(isPresented: $showingAddFavorite) {
            AddFavoriteView()
        }

        // Settings Sheet

        .sheet(isPresented: $showingSettings) {
            SettingsView(
                temperatureUnit: $temperatureUnit,
                windSpeedUnit: $windSpeedUnit
            )
        }

        // Apply Saved Preferences

        .onAppear {
            viewModel.updateUnits(
                temperatureUnit: temperatureUnit,
                windSpeedUnit: windSpeedUnit
            )
        }

        .onChange(of: temperatureUnit) { _, newValue in
            viewModel.updateUnits(
                temperatureUnit: newValue,
                windSpeedUnit: windSpeedUnit
            )
        }

        .onChange(of: windSpeedUnit) { _, newValue in
            viewModel.updateUnits(
                temperatureUnit: temperatureUnit,
                windSpeedUnit: newValue
            )
        }

        // Load Weather on Launch

        .task {
            await viewModel.loadWeather()
        }

        // Search Cities as User Types

        .task(id: searchText) {
            await searchForCities()
        }
    }

    // Search Cities

    private func searchForCities() async {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        suggestions = []
        searchError = nil

        guard query.count >= 2 else {
            isSearching = false
            return
        }

        isSearching = true

        do {

            // Waiting briefly before calling the API.

            try await Task.sleep(for: .milliseconds(400))

            let results = try await weatherService.searchCities(
                query: query
            )

            guard !Task.isCancelled else {
                return
            }

            suggestions = results

        } catch is CancellationError {

            return

        } catch {

            searchError = error.localizedDescription
        }

        isSearching = false
    }

    // Select Search Result

    private func selectCity(_ city: CitySearchResult) async {

        let locationQuery = "\(city.lat),\(city.lon)"

        searchText = ""
        suggestions = []
        searchError = nil

        await viewModel.loadWeather(for: locationQuery)
    }
}

// Settings View

struct SettingsView: View {

    @Environment(\.dismiss) private var dismiss

    @Binding var temperatureUnit: String
    @Binding var windSpeedUnit: String

    var body: some View {

        NavigationStack {

            Form {

                Section {
                    Picker(
                        "Temperature",
                        selection: $temperatureUnit
                    ) {
                        Text("Celsius (°C)").tag("C")
                        Text("Fahrenheit (°F)").tag("F")
                    }
                    .pickerStyle(.segmented)

                } header: {
                    Text("Temperature Unit")
                } footer: {
                    Text("Choose how temperatures are displayed throughout the app.")
                }

                Section {
                    Picker(
                        "Wind Speed",
                        selection: $windSpeedUnit
                    ) {
                        Text("km/h").tag("km/h")
                        Text("mph").tag("mph")
                    }
                    .pickerStyle(.segmented)

                } header: {
                    Text("Wind Speed Unit")
                } footer: {
                    Text("Choose your preferred wind speed measurement.")
                }

                Section {
                    HStack {
                        Text("Temperature")
                        Spacer()
                        Text(temperatureUnit == "C" ? "Celsius" : "Fahrenheit")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Wind Speed")
                        Spacer()
                        Text(windSpeedUnit)
                            .foregroundStyle(.secondary)
                    }

                } header: {
                    Text("Current Preferences")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .confirmationAction) {

                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// Add Favorite View

struct AddFavoriteView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var favoriteLocations: [FavoriteLocation]

    @State private var searchText = ""
    @State private var suggestions: [CitySearchResult] = []
    @State private var isSearching = false
    @State private var searchError: String?

    private let weatherService = WeatherService()

    var body: some View {

        NavigationStack {

            VStack(spacing: 15) {

                // Search Field

                HStack {

                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(
                        "Search for a city...",
                        text: $searchText
                    )
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)

                    if !searchText.isEmpty {

                        Button {
                            searchText = ""
                            suggestions = []
                            searchError = nil
                        } label: {

                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(13)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

                // Search Results

                if isSearching {

                    ProgressView("Searching cities...")
                        .padding()

                } else if let searchError {

                    Text(searchError)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()

                } else if suggestions.isEmpty {

                    ContentUnavailableView(
                        "Find a City",
                        systemImage: "magnifyingglass",
                        description: Text("Start typing to find a city.")
                    )

                } else {

                    List(suggestions) { city in

                        Button {
                            saveFavorite(city)
                        } label: {

                            HStack {

                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.blue)

                                VStack(alignment: .leading, spacing: 4) {

                                    Text(city.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Text(
                                        city.region.isEmpty
                                        ? city.country
                                        : "\(city.region), \(city.country)"
                                    )
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "plus")
                                    .foregroundStyle(.blue)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(.plain)
                }

                Spacer()
            }
            .padding(.top, 15)
            .navigationTitle("Add Favorite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.light)

        .task(id: searchText) {
            await searchForCities()
        }
    }

    // Search Cities

    private func searchForCities() async {

        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        suggestions = []
        searchError = nil

        guard query.count >= 2 else {
            isSearching = false
            return
        }

        isSearching = true

        do {

            try await Task.sleep(for: .milliseconds(400))

            let results = try await weatherService.searchCities(
                query: query
            )

            guard !Task.isCancelled else {
                return
            }

            suggestions = results

        } catch is CancellationError {

            return

        } catch {

            searchError = error.localizedDescription
        }

        isSearching = false
    }

    // Save Favorite

    private func saveFavorite(_ city: CitySearchResult) {

        let query = "\(city.lat),\(city.lon)"

        let alreadyExists = favoriteLocations.contains {
            $0.name.localizedCaseInsensitiveCompare(city.name) == .orderedSame &&
            $0.country.localizedCaseInsensitiveCompare(city.country) == .orderedSame
        }

        guard !alreadyExists else {
            dismiss()
            return
        }

        let favorite = FavoriteLocation(
            name: city.name,
            country: city.country,
            query: query
        )

        modelContext.insert(favorite)

        dismiss()
    }
}

// Reusable Weather Metric Card

struct MetricCard: View {

    let title: String
    let value: String
    let icon: String

    var body: some View {

        VStack(alignment: .leading, spacing: 12) {

            HStack(spacing: 7) {

                Image(systemName: icon)
                    .foregroundStyle(.white.opacity(0.65))

                Text(title)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .font(.caption)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

//  Reusable Forecast Card

struct ForecastCard: View {

    let day: String
    let icon: String
    let high: String
    let low: String

    var body: some View {

        VStack(spacing: 15) {

            Text(day)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.white.opacity(0.65))

            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)

            Text(high)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text(low)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

// Preview

#Preview {

    ContentView()
        .modelContainer(
            for: FavoriteLocation.self,
            inMemory: true
        )
}
