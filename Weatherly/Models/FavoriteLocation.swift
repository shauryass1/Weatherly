
import Foundation
import SwiftData

@Model
final class FavoriteLocation {

    var name: String
    var country: String
    var query: String

    init(name: String, country: String, query: String) {
        self.name = name
        self.country = country
        self.query = query
    }
}
