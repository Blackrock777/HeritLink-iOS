import Foundation
import SwiftData

@Model
final class ShoppingItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: String
    var recipeTitle: String
    var sourceKey: String
    var isChecked: Bool
    var createdAt: Date

    init(name: String, quantity: String = "", recipeTitle: String = "", sourceKey: String = "") {
        id = UUID()
        self.name = name
        self.quantity = quantity
        self.recipeTitle = recipeTitle
        self.sourceKey = sourceKey
        isChecked = false
        createdAt = .now
    }
}

@Model
final class RecipeNote {
    @Attribute(.unique) var recipeID: UUID
    var text: String
    var updatedAt: Date

    init(recipeID: UUID, text: String) {
        self.recipeID = recipeID
        self.text = text
        updatedAt = .now
    }
}

enum PantryMatcher {
    // Explicit plural forms avoid treating different foods as interchangeable.
    private static let pluralForms = [
        "tomatoes": "tomato", "potatoes": "potato", "onions": "onion",
        "carrots": "carrot", "lemons": "lemon", "limes": "lime",
        "beans": "bean", "chickpeas": "chickpea", "noodles": "noodle",
        "scallions": "scallion", "eggs": "egg", "mushrooms": "mushroom",
        "peppers": "pepper", "peas": "pea", "lentils": "lentil"
    ]

    static func entries(_ text: String) -> [String] {
        var seen: Set<String> = []
        return text.components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert(normalized($0)).inserted }
    }

    static func normalized(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .map { pluralForms[$0] ?? $0 }
            .joined(separator: " ")
    }

    static func matches(_ ingredient: String, entry: String) -> Bool {
        let candidate = normalized(ingredient)
        let query = normalized(entry)
        guard !query.isEmpty else { return false }
        // Match whole words/phrases, so "rice" never matches "licorice".
        // Deliberately avoid guessing substitutions or dietary equivalence.
        return (" " + candidate + " ").contains(" " + query + " ")
    }

    static func missing(from ingredients: [Ingredient], pantry: [String]) -> [Ingredient] {
        ingredients.filter { ingredient in
            !pantry.contains { matches(ingredient.name, entry: $0) }
        }
    }
}

struct PantryMatch: Identifiable {
    let recipe: Recipe
    let missing: [Ingredient]
    let matchedCount: Int
    let usesPriority: Bool
    var id: UUID { recipe.id }
}

enum ShoppingListWriter {
    static func add(_ ingredients: [Ingredient], from recipe: Recipe, in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<ShoppingItem>())
        for ingredient in ingredients {
            let key = recipe.id.uuidString + ":" + ingredient.id.uuidString
            if let item = existing.first(where: { $0.sourceKey == key }) {
                item.isChecked = false
                item.name = ingredient.name
                item.quantity = ingredient.quantity
                item.recipeTitle = recipe.title
            } else {
                context.insert(ShoppingItem(
                    name: ingredient.name, quantity: ingredient.quantity,
                    recipeTitle: recipe.title, sourceKey: key
                ))
            }
        }
        try context.save()
    }
}
