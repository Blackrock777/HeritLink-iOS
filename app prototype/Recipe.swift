import Foundation
import SwiftData
import UniformTypeIdentifiers

enum RecipeDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy"
    case medium = "Medium"
    case challenging = "Challenging"

    var id: String { rawValue }
}

struct Ingredient: Codable, Hashable, Identifiable {
    var id: UUID
    var quantity: String
    var name: String

    init(id: UUID = UUID(), quantity: String, name: String) {
        self.id = id
        self.quantity = quantity
        self.name = name
    }
}

struct RecipeStep: Codable, Hashable, Identifiable {
    var id: UUID
    var instruction: String

    init(id: UUID = UUID(), instruction: String) {
        self.id = id
        self.instruction = instruction
    }
}

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var cuisine: String
    var summary: String
    var story: String
    var cookingMinutes: Int
    var servings: Int
    var difficultyRawValue: String
    var dietRawValue: String = "unspecified"
    var ingredientsData: Data
    var stepsData: Data
    @Attribute(.externalStorage) var photoData: Data?
    var assetName: String?
    var isBuiltIn: Bool
    var isSaved: Bool
    var isUserCreated: Bool
    var createdAt: Date
    var updatedAt: Date
    var visualSeed: Int

    init(
        id: UUID = UUID(),
        title: String,
        cuisine: String,
        summary: String,
        story: String = "",
        cookingMinutes: Int,
        servings: Int,
        difficulty: RecipeDifficulty,
        diet: RecipeDiet = .unspecified,
        ingredients: [Ingredient],
        steps: [RecipeStep],
        photoData: Data? = nil,
        assetName: String? = nil,
        isBuiltIn: Bool = false,
        isSaved: Bool = false,
        isUserCreated: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        visualSeed: Int = 0
    ) {
        self.id = id
        self.title = title
        self.cuisine = cuisine
        self.summary = summary
        self.story = story
        self.cookingMinutes = cookingMinutes
        self.servings = servings
        self.difficultyRawValue = difficulty.rawValue
        self.dietRawValue = diet.rawValue
        self.ingredientsData = (try? JSONEncoder().encode(ingredients)) ?? Data()
        self.stepsData = (try? JSONEncoder().encode(steps)) ?? Data()
        self.photoData = photoData
        self.assetName = assetName
        self.isBuiltIn = isBuiltIn
        self.isSaved = isSaved
        self.isUserCreated = isUserCreated
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.visualSeed = visualSeed
    }

    var diet: RecipeDiet {
        get { RecipeDiet(rawValue: dietRawValue) ?? .unspecified }
        set { dietRawValue = newValue.rawValue }
    }

    var difficulty: RecipeDifficulty {
        get { RecipeDifficulty(rawValue: difficultyRawValue) ?? .easy }
        set { difficultyRawValue = newValue.rawValue }
    }

    var ingredients: [Ingredient] {
        get { (try? JSONDecoder().decode([Ingredient].self, from: ingredientsData)) ?? [] }
        set { ingredientsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var steps: [RecipeStep] {
        get { (try? JSONDecoder().decode([RecipeStep].self, from: stepsData)) ?? [] }
        set { stepsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }
}

struct RecipeTransfer: Codable {
    static let formatVersion = 1

    var formatVersion: Int
    var id: UUID
    var title: String
    var cuisine: String
    var summary: String
    var story: String
    var cookingMinutes: Int
    var servings: Int
    var difficulty: RecipeDifficulty
    var dietRawValue: String?
    var ingredients: [Ingredient]
    var steps: [RecipeStep]
    var photoData: Data?
    var visualSeed: Int

    init(recipe: Recipe, includePhoto: Bool = true) {
        formatVersion = Self.formatVersion
        id = recipe.id
        title = recipe.title
        cuisine = recipe.cuisine
        summary = recipe.summary
        story = recipe.story
        cookingMinutes = recipe.cookingMinutes
        servings = recipe.servings
        difficulty = recipe.difficulty
        dietRawValue = recipe.diet.rawValue
        ingredients = recipe.ingredients
        steps = recipe.steps
        photoData = includePhoto ? recipe.photoData : nil
        visualSeed = recipe.visualSeed
    }

    func makeRecipe() -> Recipe {
        Recipe(
            id: UUID(),
            title: title,
            cuisine: cuisine,
            summary: summary,
            story: story,
            cookingMinutes: cookingMinutes,
            servings: servings,
            difficulty: difficulty,
            diet: RecipeDiet(rawValue: dietRawValue ?? "") ?? .unspecified,
            ingredients: ingredients,
            steps: steps,
            photoData: photoData,
            isSaved: true,
            isUserCreated: true,
            visualSeed: visualSeed
        )
    }

    func encoded(prettyPrinted: Bool = false) throws -> Data {
        let encoder = JSONEncoder()
        if prettyPrinted { encoder.outputFormatting = [.prettyPrinted, .sortedKeys] }
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> RecipeTransfer {
        try JSONDecoder().decode(RecipeTransfer.self, from: data)
    }
}

extension UTType {
    static let savourRecipe = UTType(exportedAs: "com.savour.recipe", conformingTo: .json)
}
