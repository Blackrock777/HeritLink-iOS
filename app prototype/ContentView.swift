import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home
    case explore
    case kitchen
}

struct ContentView: View {
    @Query(sort: \LocalProfile.createdAt) private var profiles: [LocalProfile]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            if let profile = profiles.first {
                MainTabView(profile: profile)
            } else {
                WelcomeProfileView()
            }
        }
        .task {
            SeedData.insertIfNeeded(in: modelContext)
        }
        .preferredColorScheme(.light)
    }
}

struct MainTabView: View {
    let profile: LocalProfile
    @State private var selectedTab = AppTab.home
    @State private var showProfile = false
    @State private var requestedCuisine: String?

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: .home) {
                HomeView(
                    profile: profile,
                    selectedTab: $selectedTab,
                    requestedCuisine: $requestedCuisine,
                    onEditProfile: { showProfile = true }
                )
            }

            Tab("Explore", systemImage: "magnifyingglass", value: .explore) {
                ExploreView(requestedCuisine: $requestedCuisine)
            }

            Tab("My Kitchen", systemImage: "books.vertical.fill", value: .kitchen) {
                MyKitchenView(profile: profile)
            }
        }
        .tint(SavourTheme.forest)
        .sheet(isPresented: $showProfile) {
            LocalProfileEditorView(profile: profile)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Recipe.self, LocalProfile.self, ShoppingItem.self, RecipeNote.self], inMemory: true)
}
