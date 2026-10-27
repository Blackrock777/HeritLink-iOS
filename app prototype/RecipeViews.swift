import SwiftUI
import SwiftData
import PhotosUI

struct RecipeDetailView: View {
    @Bindable var recipe: Recipe
    @State private var showCookingMode = false
    @State private var showEditor = false
    @State private var showExchange = false
    @State private var showShopping = false
    @State private var isEditingNote = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 24) {
                RecipeArtwork(photoData: recipe.photoData, assetName: recipe.assetName, seed: recipe.visualSeed, height: 330)
                    .containerRelativeFrame(.horizontal)
                RecipeTitleSection(
                    cuisine: recipe.cuisine,
                    title: recipe.title,
                    summary: recipe.summary,
                    cookingMinutes: recipe.cookingMinutes,
                    servings: recipe.servings,
                    difficulty: recipe.difficulty
                )
                RecipeDietBadge(diet: recipe.diet)
                    .padding(.horizontal, 20)
                RecipeIngredientsSection(ingredients: recipe.ingredients)
                Button("Shopping needs", systemImage: "basket") { showShopping = true }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 20)
                PersonalRecipeNotesView(recipeID: recipe.id, isEditing: $isEditingNote)
                RecipeInstructionsSection(steps: recipe.steps)
                if !recipe.story.isEmpty {
                    RecipeStorySection(story: recipe.story, isBuiltIn: recipe.isBuiltIn)
                }
            }
            .padding(.bottom, 24)
        }
        .savourBackground()
        .ignoresSafeArea(edges: .top)
        .safeAreaInset(edge: .bottom) {
            if !isEditingNote {
                HStack(spacing: 12) {
                    Button {
                        recipe.isSaved.toggle()
                        recipe.updatedAt = .now
                        try? modelContext.save()
                    } label: {
                        Image(systemName: recipe.isSaved ? "bookmark.fill" : "bookmark")
                            .frame(width: 44, height: 44)
                            .background(SavourTheme.paper, in: Circle())
                    }
                    .accessibilityLabel(recipe.isSaved ? "Remove from saved recipes" : "Save recipe")

                    Button {
                        showCookingMode = true
                    } label: {
                        Label("Start cooking", systemImage: "flame.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(SavourTheme.forest, in: Capsule())
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showExchange = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                if recipe.isUserCreated {
                    Button("Edit") { showEditor = true }
                }
            }
        }
        .fullScreenCover(isPresented: $showCookingMode) {
            CookingModeView(recipe: recipe)
        }
        .sheet(isPresented: $showEditor) {
            NavigationStack {
                RecipeEditorView(recipe: recipe)
            }
        }
        .sheet(isPresented: $showShopping) {
            RecipeShoppingPicker(recipe: recipe)
        }
        .sheet(isPresented: $showExchange) {
            RecipeExchangeView(recipe: recipe)
        }
        .tint(SavourTheme.forest)
    }
}

struct RecipeTitleSection: View {
    let cuisine: String
    let title: String
    let summary: String
    let cookingMinutes: Int
    let servings: Int
    let difficulty: RecipeDifficulty

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(cuisine.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.6)
                .foregroundStyle(SavourTheme.terracotta)
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(SavourTheme.forest)
            Text(summary)
                .font(.body)
                .foregroundStyle(SavourTheme.muted)
                .lineSpacing(4)
            HStack(spacing: 18) {
                Label("\(cookingMinutes) min", systemImage: "clock")
                Label("\(servings) servings", systemImage: "person.2")
                Label(difficulty.rawValue, systemImage: "chart.bar")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(SavourTheme.forest)
        }
        .padding(.horizontal, 20)
    }
}

struct RecipeIngredientsSection: View {
    let ingredients: [Ingredient]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeading(title: "Ingredients")
            VStack(spacing: 0) {
                ForEach(ingredients) { ingredient in
                    HStack(alignment: .firstTextBaseline) {
                        Text(ingredient.quantity)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(SavourTheme.terracotta)
                            .frame(width: 78, alignment: .leading)
                        Text(ingredient.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 12)
                    if ingredient.id != ingredients.last?.id {
                        Divider()
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(SavourTheme.paper, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal, 20)
    }
}

struct RecipeInstructionsSection: View {
    let steps: [RecipeStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeading(title: "Method")
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 14) {
                    Text("\(index + 1)")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(SavourTheme.forest, in: Circle())
                    Text(step.instruction)
                        .font(.body)
                        .foregroundStyle(SavourTheme.ink)
                        .lineSpacing(4)
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct RecipeStorySection: View {
    let story: String
    let isBuiltIn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeading(eyebrow: "From the table", title: isBuiltIn ? "Behind the dish" : "The story")
            Text(story)
                .font(.body.italic())
                .foregroundStyle(SavourTheme.muted)
                .lineSpacing(5)
        }
        .padding(20)
        .background(SavourTheme.paper, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(.horizontal, 20)
    }
}

struct CookingModeView: View {
    let recipe: Recipe
    @State private var stepIndex = 0
    @State private var showIngredients = false
    @State private var showTerms = false
    @Environment(\.dismiss) private var dismiss

    private var steps: [RecipeStep] { recipe.steps }
    private var currentStep: RecipeStep? {
        steps.indices.contains(stepIndex) ? steps[stepIndex] : nil
    }
    private var displayedStep: Int { currentStep == nil ? 0 : stepIndex + 1 }
    private var isLastStep: Bool { steps.isEmpty || stepIndex >= steps.count - 1 }
    private var instruction: String {
        guard let currentStep else { return "No cooking steps are available for this recipe." }
        return currentStep.instruction.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "This step has no instructions. Continue when you’re ready."
            : currentStep.instruction
    }

    var body: some View {
        ZStack {
            SavourTheme.forest.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Button("Close", systemImage: "xmark") { dismiss() }
                    Spacer()
                    Text("\(displayedStep) of \(steps.count)")
                        .font(.subheadline.monospacedDigit())
                }
                .foregroundStyle(.white.opacity(0.9))
                .padding()

                ProgressView(value: Double(displayedStep), total: Double(max(steps.count, 1)))
                    .tint(Color(red: 0.90, green: 0.68, blue: 0.30))
                    .padding(.horizontal)

                ViewThatFits(in: .horizontal) {
                    HStack {
                        Button("Ingredients", systemImage: "list.bullet") { showIngredients = true }
                        Button("Cooking terms", systemImage: "questionmark.circle") { showTerms = true }
                    }
                    VStack {
                        Button("Ingredients", systemImage: "list.bullet") { showIngredients = true }
                        Button("Cooking terms", systemImage: "questionmark.circle") { showTerms = true }
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.white)
                .padding()

                ScrollView {
                    VStack(spacing: 24) {
                        Text(currentStep == nil ? "NO STEPS" : "STEP \(displayedStep)")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(Color(red: 0.90, green: 0.68, blue: 0.30))
                        Text(instruction)
                            .font(.system(.title, design: .rounded, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .lineSpacing(7)
                            .foregroundStyle(.white)
                            .contentTransition(.numericText())
                            .id(stepIndex)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                    }
                    .padding(30)
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: 14) {
                    Button {
                        withAnimation { stepIndex = max(0, stepIndex - 1) }
                    } label: {
                        Image(systemName: "arrow.left")
                            .frame(width: 56, height: 56)
                            .background(.white.opacity(0.12), in: Circle())
                    }
                    .disabled(stepIndex == 0 || currentStep == nil)
                    .accessibilityLabel("Previous step")

                    Button {
                        if isLastStep {
                            dismiss()
                        } else {
                            withAnimation { stepIndex += 1 }
                        }
                    } label: {
                        Text(steps.isEmpty ? "Done" : (isLastStep ? "Finish" : "Next step"))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(red: 0.90, green: 0.68, blue: 0.30), in: Capsule())
                            .foregroundStyle(SavourTheme.forest)
                            .fontWeight(.bold)
                    }
                }
                .foregroundStyle(.white)
                .padding(20)
            }
        }
        .sheet(isPresented: $showIngredients) {
            NavigationStack {
                ScrollView {
                    if recipe.ingredients.isEmpty {
                        Text("No ingredients listed for this recipe.").padding()
                    } else {
                        RecipeIngredientsSection(ingredients: recipe.ingredients)
                            .padding(.vertical)
                    }
                }
                .savourBackground()
                .navigationTitle("Ingredients")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showIngredients = false }
                    }
                }
            }
            .tint(SavourTheme.forest)
        }
        .sheet(isPresented: $showTerms) {
            NavigationStack {
                List {
                    Section("Sauté") {
                        Text("Cook in a little oil or butter over medium to high heat, stirring or tossing regularly.")
                    }
                    Section("Simmer") {
                        Text("Cook liquid gently with small bubbles breaking the surface occasionally. Lower the heat if it bubbles vigorously.")
                    }
                    Section("Boil") {
                        Text("Heat liquid until large bubbles rise continuously and break at the surface.")
                    }
                    Section("Fold") {
                        Text("Gently lift the mixture from the bottom over the top with a spatula, turning the bowl as you go.")
                    }
                }
                .navigationTitle("Cooking terms")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showTerms = false }
                    }
                }
            }
            .tint(SavourTheme.forest)
        }
        .interactiveDismissDisabled()
    }
}

struct RecipeEditorView: View {
    let recipe: Recipe?
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var cuisine: String
    @State private var summary: String
    @State private var story: String
    @State private var cookingMinutes: Int
    @State private var servings: Int
    @State private var difficulty: RecipeDifficulty
    @State private var diet: RecipeDiet
    @State private var ingredients: [Ingredient]
    @State private var steps: [RecipeStep]
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?

    init(recipe: Recipe? = nil) {
        self.recipe = recipe
        _title = State(initialValue: recipe?.title ?? "")
        _cuisine = State(initialValue: recipe?.cuisine ?? "")
        _summary = State(initialValue: recipe?.summary ?? "")
        _story = State(initialValue: recipe?.story ?? "")
        _cookingMinutes = State(initialValue: recipe?.cookingMinutes ?? 30)
        _servings = State(initialValue: recipe?.servings ?? 4)
        _difficulty = State(initialValue: recipe?.difficulty ?? .easy)
        _diet = State(initialValue: recipe?.diet ?? .unspecified)
        _ingredients = State(initialValue: recipe?.ingredients ?? [Ingredient(quantity: "", name: "")])
        _steps = State(initialValue: recipe?.steps ?? [RecipeStep(instruction: "")])
        _photoData = State(initialValue: recipe?.photoData)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !cuisine.trimmingCharacters(in: .whitespaces).isEmpty
            && ingredients.contains { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
            && steps.contains { !$0.instruction.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        Form {
            Section("Photo") {
                ZStack {
                    if let photoData {
                        RecipeArtwork(photoData: photoData, assetName: nil, seed: recipe?.visualSeed ?? 0, height: 190)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(SavourTheme.cream)
                            .frame(height: 150)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.largeTitle)
                                    Text("Optional recipe photo")
                                        .font(.subheadline.weight(.medium))
                                }
                                .foregroundStyle(SavourTheme.moss)
                            }
                    }
                }
                .listRowInsets(EdgeInsets())
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(photoData == nil ? "Choose photo" : "Change photo", systemImage: "photo")
                }
                if photoData != nil {
                    Button("Remove photo", role: .destructive) { photoData = nil }
                }
            }

            Section("Recipe") {
                TextField("Recipe name", text: $title)
                TextField("Cuisine", text: $cuisine)
                TextField("Short description", text: $summary, axis: .vertical)
                    .lineLimit(2...5)
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(RecipeDifficulty.allCases) { Text($0.rawValue).tag($0) }
                }
                Stepper("\(cookingMinutes) minutes", value: $cookingMinutes, in: 5...480, step: 5)
                Stepper("\(servings) servings", value: $servings, in: 1...24)
            }

            Section("Food category") {
                Picker("Category", selection: $diet) {
                    ForEach(RecipeDiet.allCases) { category in
                        Text(category.title).tag(category)
                    }
                }
                Text(diet.explanation).font(.caption).foregroundStyle(.secondary)
            }

            Section("Ingredients") {
                ForEach($ingredients) { $ingredient in
                    HStack {
                        TextField("Quantity", text: $ingredient.quantity)
                            .frame(width: 95)
                        TextField("Ingredient", text: $ingredient.name)
                    }
                }
                .onDelete { ingredients.remove(atOffsets: $0) }

                Button("Add ingredient", systemImage: "plus") {
                    ingredients.append(Ingredient(quantity: "", name: ""))
                }
            }

            Section("Instructions") {
                ForEach(Array(steps.indices), id: \.self) { index in
                    HStack(alignment: .top) {
                        Text("\(index + 1)")
                            .foregroundStyle(.secondary)
                        TextField("Describe this step", text: $steps[index].instruction, axis: .vertical)
                    }
                }
                .onDelete { steps.remove(atOffsets: $0) }

                Button("Add step", systemImage: "plus") {
                    steps.append(RecipeStep(instruction: ""))
                }
            }

            Section("Cultural story (optional)") {
                TextField("Where does this recipe come from?", text: $story, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .scrollContentBackground(.hidden)
        .savourBackground()
        .navigationTitle(recipe == nil ? "New Recipe" : "Edit Recipe")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(!canSave)
            }
        }
        .task(id: photoItem) {
            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                photoData = data
            }
        }
    }

    private func save() {
        let cleanIngredients = ingredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
        let cleanSteps = steps.filter { !$0.instruction.trimmingCharacters(in: .whitespaces).isEmpty }

        if let recipe {
            recipe.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.cuisine = cuisine.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.story = story.trimmingCharacters(in: .whitespacesAndNewlines)
            recipe.cookingMinutes = cookingMinutes
            recipe.servings = servings
            recipe.difficulty = difficulty
            recipe.diet = diet
            recipe.ingredients = cleanIngredients
            recipe.steps = cleanSteps
            recipe.photoData = photoData
            recipe.updatedAt = .now
        } else {
            let newRecipe = Recipe(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                cuisine: cuisine.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                story: story.trimmingCharacters(in: .whitespacesAndNewlines),
                cookingMinutes: cookingMinutes,
                servings: servings,
                difficulty: difficulty,
                diet: diet,
                ingredients: cleanIngredients,
                steps: cleanSteps,
                photoData: photoData,
                isSaved: true,
                isUserCreated: true,
                visualSeed: Int.random(in: 0...5)
            )
            modelContext.insert(newRecipe)
        }
        try? modelContext.save()
        dismiss()
    }
}
