import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    let profile: LocalProfile
    @Binding var selectedTab: AppTab
    let onEditProfile: () -> Void

    private var featured: Recipe? { recipes.first(where: { $0.title == "Tuscan White Bean Stew" }) ?? recipes.first }
    private var quickRecipes: [Recipe] { Array(recipes.filter { $0.cookingMinutes <= 30 }.prefix(4)) }
    private var cuisines: [String] { Array(Set(recipes.map(\.cuisine))).sorted() }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 28) {
                    HomeWelcomeHeader(
                        name: profile.name,
                        photoData: profile.photoData,
                        onProfile: onEditProfile
                    ) {
                        selectedTab = .explore
                    }

                    KitchenToolsCard()

                    if let featured {
                        NavigationLink(value: featured) {
                            FeaturedRecipeCard(recipe: featured)
                        }
                        .buttonStyle(.plain)
                    }

                    CuisineStrip(cuisines: cuisines) { _ in
                        selectedTab = .explore
                    }

                    SectionHeading(title: "Weeknight favorites", actionTitle: "Explore all") {
                        selectedTab = .explore
                    }

                    ScrollView(.horizontal) {
                        LazyHStack(spacing: 16) {
                            ForEach(quickRecipes) { recipe in
                                NavigationLink(value: recipe) {
                                    RecipeCard(recipe: recipe, compact: true)
                                        .frame(width: 225)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .scrollIndicators(.hidden)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .savourBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
        }
    }
}

struct HomeWelcomeHeader: View {
    let name: String
    let photoData: Data?
    let onProfile: () -> Void
    let onSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("HeritLink")
                        .font(.caption.weight(.black))
                        .tracking(2.4)
                        .foregroundStyle(SavourTheme.terracotta)
                    Text("Hello, \(name)")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(SavourTheme.forest)
                    Text("What shall we cook?")
                        .font(.subheadline)
                        .foregroundStyle(SavourTheme.muted)
                }
                Spacer()
                Button(action: onProfile) {
                    ProfileAvatar(photoData: photoData, name: name, size: 48)
                        .overlay(Circle().stroke(SavourTheme.paper, lineWidth: 3))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open local profile")
            }

            Button(action: onSearch) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search recipes and ingredients")
                    Spacer()
                }
                .font(.subheadline)
                .foregroundStyle(SavourTheme.muted)
                .padding()
                .background(SavourTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 16)
    }
}

struct FeaturedRecipeCard: View {
    let recipe: Recipe

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Color.clear
            LinearGradient(colors: [.clear, .black.opacity(0.78)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 8) {
                Text("TODAY’S PICK")
                    .font(.caption.weight(.bold))
                    .tracking(1.4)
                Label {
                    Text(recipe.diet.title)
                } icon: {
                    Image(systemName: recipe.diet.systemImage)
                }
                .font(.caption.weight(.semibold))
                Text(recipe.title)
                    .font(.title.weight(.bold))
                Text(recipe.summary)
                    .font(.subheadline)
                    .lineLimit(2)
                Label("\(recipe.cookingMinutes) minutes", systemImage: "clock")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 310)
        .background {
            RecipeArtwork(
                photoData: recipe.photoData,
                assetName: recipe.assetName,
                seed: recipe.visualSeed,
                height: 310
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: SavourTheme.forest.opacity(0.16), radius: 18, y: 8)
    }
}

struct CuisineStrip: View {
    let cuisines: [String]
    let onSelect: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(eyebrow: "Around the table", title: "Explore cuisines")
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(cuisines, id: \.self) { cuisine in
                        Button(cuisine) { onSelect(cuisine) }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SavourTheme.forest)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 11)
                            .background(SavourTheme.paper, in: Capsule())
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

struct ExploreView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @State private var searchText = ""
    @State private var cuisine = "All"
    @State private var difficulty: RecipeDifficulty?
    @State private var diet: RecipeDiet?
    @State private var maxMinutes = 180
    @State private var showFilters = false
    @State private var filteredRecipes: [Recipe] = []

    private var cuisines: [String] { ["All"] + Array(Set(recipes.map(\.cuisine))).sorted() }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 18) {
                    ExploreFilterBar(
                        cuisine: $cuisine,
                        cuisines: cuisines,
                        activeFilterCount: (difficulty == nil ? 0 : 1) + (maxMinutes < 180 ? 1 : 0) + (diet == nil ? 0 : 1),
                        showFilters: $showFilters
                    )

                    if let diet {
                        RecipeDietBadge(diet: diet)
                    }

                    if filteredRecipes.isEmpty {
                        EmptyKitchenView(
                            title: "No recipes found",
                            message: "Try a different food category, cuisine, ingredient or cooking time.",
                            systemImage: "fork.knife"
                        )
                        .frame(minHeight: 380)
                    } else {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                RecipeCard(recipe: recipe)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .savourBackground()
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Recipe or ingredient")
            .sheet(isPresented: $showFilters) {
                FilterSheet(difficulty: $difficulty, maxMinutes: $maxMinutes, diet: $diet)
                    .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .onAppear(perform: recompute)
            .onChange(of: recipes.map(\.updatedAt)) { recompute() }
            .onChange(of: recipes.map(\.dietRawValue)) { recompute() }
            .onChange(of: searchText) { recompute() }
            .onChange(of: cuisine) { recompute() }
            .onChange(of: difficulty) { recompute() }
            .onChange(of: diet) { recompute() }
            .onChange(of: maxMinutes) { recompute() }
        }
    }

    private func recompute() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        filteredRecipes = recipes.filter { recipe in
            let matchesText = query.isEmpty
                || recipe.title.localizedCaseInsensitiveContains(query)
                || recipe.cuisine.localizedCaseInsensitiveContains(query)
                || recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(query) }
            let matchesCuisine = cuisine == "All" || recipe.cuisine == cuisine
            let matchesDifficulty = difficulty == nil || recipe.difficulty == difficulty
            let matchesDiet = diet == nil || recipe.diet == diet
            return matchesText && matchesCuisine && matchesDifficulty && matchesDiet && recipe.cookingMinutes <= maxMinutes
        }
    }
}

struct ExploreFilterBar: View {
    @Binding var cuisine: String
    let cuisines: [String]
    let activeFilterCount: Int
    @Binding var showFilters: Bool

    var body: some View {
        HStack {
            Menu {
                Picker("Cuisine", selection: $cuisine) {
                    ForEach(cuisines, id: \.self) { Text($0).tag($0) }
                }
            } label: {
                Label(cuisine, systemImage: "globe.europe.africa")
                    .lineLimit(1)
            }

            Spacer()

            Button {
                showFilters = true
            } label: {
                Label(activeFilterCount == 0 ? "Filters" : "Filters \(activeFilterCount)", systemImage: "slider.horizontal.3")
            }
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(SavourTheme.forest)
        .padding(.vertical, 8)
    }
}

struct FilterSheet: View {
    @Binding var difficulty: RecipeDifficulty?
    @Binding var maxMinutes: Int
    @Binding var diet: RecipeDiet?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Food category", selection: $diet) {
                        Text("All categories").tag(nil as RecipeDiet?)
                        ForEach(RecipeDiet.allCases) { category in
                            Text(category.title).tag(category as RecipeDiet?)
                        }
                    }
                    if let diet { Text(diet.explanation).font(.caption).foregroundStyle(.secondary) }
                } header: {
                    Text("Food category")
                } footer: {
                    Text("Shows the selected category only. Vegan dishes have their own category; Vegetarian + eggs is eggitarian.")
                }

                Section("Difficulty") {
                    Picker("Difficulty", selection: $difficulty) {
                        Text("Any").tag(nil as RecipeDifficulty?)
                        ForEach(RecipeDifficulty.allCases) { value in
                            Text(value.rawValue).tag(value as RecipeDifficulty?)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Maximum cooking time") {
                    Stepper("\(maxMinutes) minutes", value: $maxMinutes, in: 15...180, step: 15)
                }

                Section {
                    Button("Reset filters") {
                        diet = nil
                        difficulty = nil
                        maxMinutes = 180
                    }
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
