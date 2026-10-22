import Foundation
import SwiftData

enum SeedData {
    static func insertIfNeeded(in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Recipe>())) ?? []
        let existingByTitle = Dictionary(uniqueKeysWithValues: existing.map { ($0.title, $0) })

        for catalogRecipe in catalog {
            if let storedRecipe = existingByTitle[catalogRecipe.title], storedRecipe.isBuiltIn {
                storedRecipe.assetName = catalogRecipe.assetName
                if storedRecipe.diet == .unspecified {
                    // Clarify ingredient variants before applying the catalog's category.
                    storedRecipe.ingredients = storedRecipe.ingredients.map { ingredient in
                        var clarified = ingredient
                        if storedRecipe.title == "Vegetable Bibimbap", ingredient.name == "Kimchi" {
                            clarified.name = "Vegan kimchi"
                        }
                        if storedRecipe.title == "Lemon Herb Orzo", ingredient.name == "Feta" {
                            clarified.name = "Vegetarian feta"
                        }
                        return clarified
                    }
                    storedRecipe.diet = catalogRecipe.diet
                }
            } else if existingByTitle[catalogRecipe.title] == nil {
                context.insert(catalogRecipe)
            }
        }
        try? context.save()
    }

    static let catalog: [Recipe] = [
        Recipe(
            title: "Tuscan White Bean Stew",
            cuisine: "Italian",
            summary: "Silky beans, rosemary and garden vegetables in a deeply comforting broth.",
            story: "A simple cucina povera dish that turns pantry staples into something generous enough to share.",
            cookingMinutes: 40,
            servings: 4,
            difficulty: .easy,
            diet: .vegan,
            ingredients: [
                Ingredient(quantity: "2 tbsp", name: "Extra-virgin olive oil"),
                Ingredient(quantity: "1", name: "Yellow onion, diced"),
                Ingredient(quantity: "2 cloves", name: "Garlic, sliced"),
                Ingredient(quantity: "2 cans", name: "Cannellini beans"),
                Ingredient(quantity: "3 cups", name: "Vegetable stock"),
                Ingredient(quantity: "2 sprigs", name: "Rosemary"),
                Ingredient(quantity: "2 cups", name: "Tuscan kale")
            ],
            steps: [
                RecipeStep(instruction: "Warm the olive oil in a heavy pot. Soften the onion with a pinch of salt for 8 minutes."),
                RecipeStep(instruction: "Add garlic and rosemary. Stir until fragrant, about 30 seconds."),
                RecipeStep(instruction: "Add the beans and stock. Simmer uncovered for 20 minutes."),
                RecipeStep(instruction: "Crush a few beans against the pot, fold in the kale, and cook until tender. Season generously.")
            ],
            assetName: "TuscanStew",
            isBuiltIn: true,
            isSaved: true,
            visualSeed: 0
        ),
        Recipe(
            title: "Miso Butter Udon",
            cuisine: "Japanese",
            summary: "Glossy noodles with savory miso, butter, scallions and a bright squeeze of lime.",
            story: "A weeknight bowl inspired by the comforting meeting point of Japanese pantry flavors and buttery noodles.",
            cookingMinutes: 20,
            servings: 2,
            difficulty: .easy,
            diet: .vegetarian,
            ingredients: [
                Ingredient(quantity: "400 g", name: "Fresh udon noodles"),
                Ingredient(quantity: "2 tbsp", name: "White miso"),
                Ingredient(quantity: "2 tbsp", name: "Unsalted butter"),
                Ingredient(quantity: "1 tbsp", name: "Soy sauce"),
                Ingredient(quantity: "3", name: "Scallions"),
                Ingredient(quantity: "1", name: "Lime")
            ],
            steps: [
                RecipeStep(instruction: "Whisk miso, soy sauce and two tablespoons of warm water until smooth."),
                RecipeStep(instruction: "Cook the udon according to its package, reserving a little cooking water."),
                RecipeStep(instruction: "Melt butter in a wide pan. Add the miso mixture and noodles, tossing until glossy."),
                RecipeStep(instruction: "Loosen with cooking water, finish with scallions and lime, and serve immediately.")
            ],
            assetName: "MisoUdon",
            isBuiltIn: true,
            visualSeed: 1
        ),
        Recipe(
            title: "Chana Masala",
            cuisine: "Indian",
            summary: "Chickpeas simmered with tomato, ginger and toasted spices.",
            story: "Every household has its own balance of warmth, tang and heat. This version is bright with amchur and ginger.",
            cookingMinutes: 35,
            servings: 4,
            difficulty: .medium,
            diet: .vegan,
            ingredients: [
                Ingredient(quantity: "2 cans", name: "Chickpeas"),
                Ingredient(quantity: "1", name: "Onion, finely chopped"),
                Ingredient(quantity: "3", name: "Tomatoes, chopped"),
                Ingredient(quantity: "1 tbsp", name: "Grated ginger"),
                Ingredient(quantity: "2 tsp", name: "Garam masala"),
                Ingredient(quantity: "1 tsp", name: "Ground cumin"),
                Ingredient(quantity: "1 tsp", name: "Amchur")
            ],
            steps: [
                RecipeStep(instruction: "Toast cumin in oil, then cook the onion until deeply golden."),
                RecipeStep(instruction: "Add ginger, garam masala and tomatoes. Cook until jammy."),
                RecipeStep(instruction: "Stir in chickpeas and one cup of water. Simmer for 18 minutes."),
                RecipeStep(instruction: "Finish with amchur, salt and chopped coriander.")
            ],
            assetName: "ChanaMasala",
            isBuiltIn: true,
            visualSeed: 2
        ),
        Recipe(
            title: "Smoky Shakshuka",
            cuisine: "North African",
            summary: "Eggs gently poached in a paprika-rich tomato and pepper sauce.",
            story: "Made for tearing and dipping at the table, this one-pan breakfast travels happily into dinner.",
            cookingMinutes: 30,
            servings: 3,
            difficulty: .medium,
            diet: .eggitarian,
            ingredients: [
                Ingredient(quantity: "1", name: "Red bell pepper"),
                Ingredient(quantity: "1", name: "Onion"),
                Ingredient(quantity: "400 g", name: "Crushed tomatoes"),
                Ingredient(quantity: "1 tsp", name: "Smoked paprika"),
                Ingredient(quantity: "1 tsp", name: "Ground cumin"),
                Ingredient(quantity: "5", name: "Eggs"),
                Ingredient(quantity: "Handful", name: "Parsley")
            ],
            steps: [
                RecipeStep(instruction: "Soften the pepper and onion in olive oil for 10 minutes."),
                RecipeStep(instruction: "Add spices and tomatoes, then simmer until thickened."),
                RecipeStep(instruction: "Make five wells and crack in the eggs. Cover and cook until the whites set."),
                RecipeStep(instruction: "Scatter with parsley and serve with warm bread.")
            ],
            assetName: "Shakshuka",
            isBuiltIn: true,
            visualSeed: 3
        ),
        Recipe(
            title: "Green Mole Tacos",
            cuisine: "Mexican",
            summary: "Roasted vegetables, pumpkin seeds and herbs folded into warm corn tortillas.",
            story: "A fresh, herbaceous nod to the many green moles of central Mexico.",
            cookingMinutes: 50,
            servings: 4,
            difficulty: .challenging,
            diet: .vegan,
            ingredients: [
                Ingredient(quantity: "8", name: "Corn tortillas"),
                Ingredient(quantity: "6", name: "Tomatillos"),
                Ingredient(quantity: "1", name: "Poblano pepper"),
                Ingredient(quantity: "1/3 cup", name: "Pumpkin seeds"),
                Ingredient(quantity: "1 cup", name: "Coriander"),
                Ingredient(quantity: "2 cups", name: "Roasted seasonal vegetables")
            ],
            steps: [
                RecipeStep(instruction: "Char the tomatillos and poblano until blistered."),
                RecipeStep(instruction: "Toast the pumpkin seeds, then blend with the charred vegetables, coriander and water."),
                RecipeStep(instruction: "Simmer the sauce for 12 minutes and season with salt."),
                RecipeStep(instruction: "Warm the tortillas, fill with roasted vegetables and spoon over the green mole.")
            ],
            assetName: "GreenMoleTacos",
            isBuiltIn: true,
            visualSeed: 4
        ),
        Recipe(
            title: "Lemon Herb Orzo",
            cuisine: "Greek",
            summary: "A sunny one-pot orzo with spinach, feta, dill and plenty of lemon.",
            cookingMinutes: 25,
            servings: 4,
            difficulty: .easy,
            diet: .vegetarian,
            ingredients: [
                Ingredient(quantity: "300 g", name: "Orzo"),
                Ingredient(quantity: "3 cups", name: "Vegetable stock"),
                Ingredient(quantity: "2 cups", name: "Baby spinach"),
                Ingredient(quantity: "1", name: "Lemon"),
                Ingredient(quantity: "100 g", name: "Vegetarian feta"),
                Ingredient(quantity: "1/2 cup", name: "Fresh dill")
            ],
            steps: [
                RecipeStep(instruction: "Toast the orzo in olive oil for two minutes."),
                RecipeStep(instruction: "Add stock and simmer, stirring often, until tender."),
                RecipeStep(instruction: "Fold through spinach, lemon zest and juice."),
                RecipeStep(instruction: "Finish with crumbled feta, dill and black pepper.")
            ],
            assetName: "LemonHerbOrzo",
            isBuiltIn: true,
            visualSeed: 5
        ),
        Recipe(
            title: "Vegetable Bibimbap",
            cuisine: "Korean",
            summary: "A colorful rice bowl layered with seasoned vegetables, kimchi, egg and gochujang.",
            story: "Bibimbap means “mixed rice.” Arrange each topping beautifully, then mix everything at the table so every bite carries a little of each flavor.",
            cookingMinutes: 45,
            servings: 2,
            difficulty: .medium,
            diet: .eggitarian,
            ingredients: [
                Ingredient(quantity: "2 cups", name: "Cooked short-grain rice"),
                Ingredient(quantity: "2", name: "Eggs"),
                Ingredient(quantity: "1", name: "Carrot, cut into matchsticks"),
                Ingredient(quantity: "1", name: "Zucchini, sliced"),
                Ingredient(quantity: "150 g", name: "Spinach"),
                Ingredient(quantity: "150 g", name: "Shiitake mushrooms"),
                Ingredient(quantity: "1 cup", name: "Bean sprouts"),
                Ingredient(quantity: "1/2 cup", name: "Vegan kimchi"),
                Ingredient(quantity: "2 tbsp", name: "Gochujang"),
                Ingredient(quantity: "2 tsp", name: "Sesame oil")
            ],
            steps: [
                RecipeStep(instruction: "Season the spinach and bean sprouts separately with a little sesame oil and salt."),
                RecipeStep(instruction: "Sauté the carrot, zucchini and mushrooms separately until just tender, keeping their colors bright."),
                RecipeStep(instruction: "Fry the eggs sunny-side up while warming the rice."),
                RecipeStep(instruction: "Divide rice between bowls. Arrange the vegetables and kimchi in sections, then place an egg in the center."),
                RecipeStep(instruction: "Serve with gochujang and sesame oil. Mix thoroughly just before eating.")
            ],
            assetName: "Bibimbap",
            isBuiltIn: true,
            visualSeed: 6
        )
    ]
}
