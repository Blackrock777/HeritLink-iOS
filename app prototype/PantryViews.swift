import SwiftUI
import SwiftData

struct KitchenToolsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Make tonight easier").font(.title2.bold())
            NavigationLink {
                PantryRescueView()
            } label: {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cook with what I have").font(.headline)
                        Text("Use what’s in your kitchen. Buy less.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "carrot.fill").font(.title2)
                }
            }
            Divider()
            NavigationLink {
                ShoppingListView()
            } label: {
                Label("Shopping list", systemImage: "checklist")
                    .font(.headline)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SavourTheme.paper, in: RoundedRectangle(cornerRadius: 22))
        .foregroundStyle(SavourTheme.forest)
    }
}

struct PantryRescueView: View {
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @AppStorage("savour.pantry") private var pantryText = ""
    @State private var priority = ""
    @State private var quickOnly = false
    @State private var results: [PantryMatch] = []
    @FocusState private var focusedField: InputField?

    private enum InputField: Hashable {
        case pantry, priority
    }

    var body: some View {
        List {
            Section {
                Text("What’s already in your kitchen?")
                    .font(.title2.bold()).foregroundStyle(SavourTheme.forest)
                TextField("e.g. garlic, onion, olive oil", text: $pantryText, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focusedField, equals: .pantry)
                Text("Separate ingredients with commas. Saved on this device.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Use something up") {
                TextField("Prioritize one ingredient, e.g. kale", text: $priority)
                    .focused($focusedField, equals: .priority)
                    .submitLabel(.done)
                    .onSubmit { focusedField = nil }
                Toggle("30 minutes or less", isOn: $quickOnly)
                Text("Name matches are a starting point. Check the exact ingredient and quantity before cooking.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Your closest matches") {
                if PantryMatcher.entries(pantryText).isEmpty && priority.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    ContentUnavailableView("Start with your ingredients", systemImage: "carrot",
                                           description: Text("Add a few things you have to find recipes that use them."))
                } else if results.isEmpty {
                    ContentUnavailableView("No matches yet", systemImage: "fork.knife",
                                           description: Text("Try another ingredient name or turn off the time limit."))
                } else {
                    ForEach(results) { match in
                        PantryMatchRow(match: match)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .savourBackground()
        .navigationTitle("Pantry rescue")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focusedField = nil }
            }
        }
        .onAppear(perform: recompute)
        .onChange(of: pantryText) { recompute() }
        .onChange(of: priority) { recompute() }
        .onChange(of: quickOnly) { recompute() }
        .onChange(of: recipes.map(\.updatedAt)) { recompute() }
    }

    private func recompute() {
        let pantry = PantryMatcher.entries(pantryText)
        let priorityName = priority.trimmingCharacters(in: .whitespacesAndNewlines)
        results = recipes.compactMap { recipe -> PantryMatch? in
            guard !quickOnly || recipe.cookingMinutes <= 30 else { return nil }
            let ingredients = recipe.ingredients
            guard !ingredients.isEmpty else { return nil }
            let missing = PantryMatcher.missing(from: ingredients, pantry: pantry)
            let matched = ingredients.count - missing.count
            let usesPriority = !priorityName.isEmpty &&
                ingredients.contains { PantryMatcher.matches($0.name, entry: priorityName) }
            guard matched > 0 || usesPriority else { return nil }
            return PantryMatch(recipe: recipe, missing: missing, matchedCount: matched, usesPriority: usesPriority)
        }.sorted {
            if $0.usesPriority != $1.usesPriority { return $0.usesPriority }
            if $0.missing.count != $1.missing.count { return $0.missing.count < $1.missing.count }
            if $0.matchedCount != $1.matchedCount { return $0.matchedCount > $1.matchedCount }
            return $0.recipe.title < $1.recipe.title
        }
    }
}

struct PantryMatchRow: View {
    let match: PantryMatch
    @State private var showShopping = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                RecipeDetailView(recipe: match.recipe)
            } label: {
                VStack(alignment: .leading, spacing: 6) {
                    Text(match.recipe.title).font(.headline)
                    Text("\(match.matchedCount) ingredient matches · \(match.recipe.cookingMinutes) min")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            if match.usesPriority {
                Label("Uses your priority ingredient", systemImage: "leaf")
                    .font(.caption).foregroundStyle(SavourTheme.forest)
            }
            Text(match.missing.isEmpty ? "All ingredient names matched — check quantities." :
                    "Still needed: " + match.missing.map(\.name).formatted(.list(type: .and)))
                .font(.subheadline).foregroundStyle(.secondary)
            Button("Review shopping needs", systemImage: "basket") { showShopping = true }
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.semibold))
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showShopping) {
            RecipeShoppingPicker(recipe: match.recipe)
        }
    }
}

struct RecipeShoppingPicker: View {
    let recipe: Recipe
    @AppStorage("savour.pantry") private var pantryText = ""
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selected: Set<UUID> = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(recipe.title).font(.headline)
                    Text("Uncheck anything you already have. Pantry matches start unchecked; verify quantities. Amounts are for \(recipe.servings) servings.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section("Add to shopping list") {
                    ForEach(recipe.ingredients) { ingredient in
                        Button {
                            if !selected.insert(ingredient.id).inserted { selected.remove(ingredient.id) }
                        } label: {
                            HStack {
                                Image(systemName: selected.contains(ingredient.id) ? "checkmark.circle.fill" : "circle")
                                Text("\(ingredient.quantity) \(ingredient.name)")
                                    .foregroundStyle(.primary)
                            }
                            .frame(minHeight: 36, alignment: .leading)
                        }
                        .accessibilityAddTraits(selected.contains(ingredient.id) ? .isSelected : [])
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Shopping needs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add \(selected.count)") {
                        do {
                            try ShoppingListWriter.add(recipe.ingredients.filter { selected.contains($0.id) },
                                                       from: recipe, in: modelContext)
                            dismiss()
                        } catch {
                            modelContext.rollback()
                            errorMessage = "Couldn’t update your list. Please try again."
                        }
                    }
                    .disabled(selected.isEmpty)
                }
            }
            .onAppear {
                selected = Set(PantryMatcher.missing(from: recipe.ingredients,
                                                    pantry: PantryMatcher.entries(pantryText)).map(\.id))
            }
        }
        .tint(SavourTheme.forest)
    }
}
