import SwiftUI

enum RecipeDiet: String, CaseIterable, Identifiable {
    case vegan
    case vegetarian
    case eggitarian
    case nonVegetarian
    case unspecified

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .vegan: "Vegan"
        case .vegetarian: "Vegetarian"
        case .eggitarian: "Vegetarian + eggs"
        case .nonVegetarian: "Non-vegetarian"
        case .unspecified: "Not categorized"
        }
    }

    var explanation: LocalizedStringResource {
        switch self {
        case .vegan: "No animal ingredients, including dairy, eggs or honey."
        case .vegetarian: "No meat, fish or eggs. May contain dairy or honey."
        case .eggitarian: "Contains eggs; no meat or fish. May contain dairy."
        case .nonVegetarian: "Contains meat, fish, seafood or ingredients derived from them."
        case .unspecified: "Choose a category after checking the ingredients."
        }
    }

    var systemImage: String {
        switch self {
        case .vegan: "leaf"
        case .vegetarian: "carrot"
        case .eggitarian: "oval"
        case .nonVegetarian: "fork.knife"
        case .unspecified: "questionmark.circle"
        }
    }
}

struct RecipeDietBadge: View {
    let diet: RecipeDiet

    var body: some View {
        Label {
            Text(diet.title)
        } icon: {
            Image(systemName: diet.systemImage)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(SavourTheme.forest)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(SavourTheme.forest.opacity(0.08), in: Capsule())
    }
}
