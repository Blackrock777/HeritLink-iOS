import Foundation
import SwiftData

@Model
final class LocalProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    @Attribute(.externalStorage) var photoData: Data?
    var cookingLevel: String
    var interestsData: Data
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        photoData: Data? = nil,
        cookingLevel: String = CookingLevel.curious.rawValue,
        interests: [String] = []
    ) {
        self.id = id
        self.name = name
        self.photoData = photoData
        self.cookingLevel = cookingLevel
        self.interestsData = (try? JSONEncoder().encode(interests)) ?? Data()
        self.createdAt = .now
        self.updatedAt = .now
    }

    var interests: [String] {
        get { (try? JSONDecoder().decode([String].self, from: interestsData)) ?? [] }
        set { interestsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}

enum CookingLevel: String, CaseIterable, Identifiable {
    case curious = "Just curious"
    case comfortable = "Comfortable cook"
    case confident = "Confident cook"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .curious: "sparkles"
        case .comfortable: "frying.pan"
        case .confident: "flame.fill"
        }
    }
}

enum CookingInterest: String, CaseIterable, Identifiable {
    case quickMeals = "Quick meals"
    case baking = "Baking"
    case vegetarian = "Vegetarian"
    case globalCuisine = "Global cuisine"
    case familyRecipes = "Family recipes"
    case entertaining = "Entertainment"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .quickMeals: "clock"
        case .baking: "birthday.cake"
        case .vegetarian: "leaf"
        case .globalCuisine: "globe.europe.africa"
        case .familyRecipes: "book.closed"
        case .entertaining: "person.3"
        }
    }
}
