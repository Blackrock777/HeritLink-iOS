import SwiftUI
import SwiftData

@main
struct SavourApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [Recipe.self, LocalProfile.self, ShoppingItem.self, RecipeNote.self],
            isAutosaveEnabled: true,
            isUndoEnabled: true
        )
    }
}
