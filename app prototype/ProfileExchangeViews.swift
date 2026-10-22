import SwiftUI
import SwiftData
import UIKit

struct KitchenTransfer: Codable, Identifiable {
    var formatVersion = 1
    var id: UUID
    var name: String
    var cookingLevel: String
    var recipes: [RecipeTransfer]

    func encoded() throws -> Data {
        try JSONEncoder().encode(self)
    }

    var qrData: Data? {
        guard let data = try? encoded() else { return nil }
        let payload = Data(("SAVOURK1:" + data.base64EncodedString()).utf8)
        // Leave room for error correction; never silently drop recipes to fit.
        return payload.count <= 2_200 ? payload : nil
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count <= 10_000_000 else { throw CocoaError(.fileReadCorruptFile) }
        let value = try JSONDecoder().decode(Self.self, from: data)
        guard value.formatVersion == 1, value.recipes.count <= 100,
              Set(value.recipes.map(\.id)).count == value.recipes.count,
              !value.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              value.recipes.allSatisfy({
                  $0.formatVersion == RecipeTransfer.formatVersion &&
                  !$0.title.isEmpty && $0.cookingMinutes > 0 && $0.servings > 0
              }) else { throw CocoaError(.fileReadCorruptFile) }
        return value
    }
}

struct KitchenShareView: View {
    let profile: LocalProfile
    @Query(filter: #Predicate<Recipe> { $0.isUserCreated }, sort: \Recipe.title)
    private var recipes: [Recipe]
    @Environment(\.dismiss) private var dismiss
    @State private var selection: Set<UUID> = []
    @State private var prepared: KitchenTransfer?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Label(profile.name, systemImage: "person.crop.circle")
                        .font(.title2.bold())
                    Text("Share your name, cooking rhythm and only the recipes you choose. Photos and interests stay private.")
                        .foregroundStyle(.secondary)
                }
                Section("Choose recipes") {
                    if recipes.isEmpty {
                        Text("You can share your profile now and add recipes later.")
                    }
                    ForEach(recipes) { recipe in
                        Toggle(recipe.title, isOn: Binding(
                            get: { selection.contains(recipe.id) },
                            set: { selected in
                                if selected { selection.insert(recipe.id) }
                                else { selection.remove(recipe.id) }
                            }
                        ))
                    }
                }
                Section {
                    Button("Create share card") {
                        prepared = KitchenTransfer(
                            id: profile.id, name: profile.name,
                            cookingLevel: profile.cookingLevel,
                            recipes: recipes.filter { selection.contains($0.id) }
                                .map { RecipeTransfer(recipe: $0, includePhoto: false) }
                        )
                    }
                    .disabled(selection.count > 100 || profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("Up to 100 recipes per file. Small selections can fit in a QR code.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Share my kitchen")
            .toolbar { Button("Done") { dismiss() } }
            .sheet(item: $prepared) { KitchenShareCard(transfer: $0) }
        }
        .tint(SavourTheme.forest)
    }
}

struct KitchenShareCard: View {
    let transfer: KitchenTransfer
    @Environment(\.dismiss) private var dismiss
    @State private var qrImage: UIImage?
    @State private var fileURL: URL?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    SharedKitchenHeader(name: transfer.name, level: transfer.cookingLevel, count: transfer.recipes.count)
                    if let qrImage {
                        Image(uiImage: qrImage)
                            .interpolation(.none).resizable().scaledToFit()
                            .frame(maxWidth: 300).padding(20)
                            .background(.white, in: RoundedRectangle(cornerRadius: 20))
                            .accessibilityLabel("Offline kitchen QR code for \(transfer.name)")
                        Text("In HeritLink, open My Kitchen → Import → Scan QR. Both phones can be offline.")
                            .font(.subheadline).multilineTextAlignment(.center)
                    } else {
                        Label("Use a file for this kitchen", systemImage: "doc")
                            .font(.headline)
                        Text("This selection is too large for one QR. Share the file below, or go back and choose fewer recipes.")
                            .multilineTextAlignment(.center)
                    }
                    if let fileURL {
                        ShareLink(item: fileURL) {
                            Label("Share kitchen file", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.borderedProminent)
                        Text("The recipient can save the file, then choose Import file in My Kitchen.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
                    Text("A snapshot of your kitchen. Changes you make later won’t update shared copies.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .savourBackground()
            .navigationTitle("Your kitchen card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .task {
                qrImage = transfer.qrData.flatMap { QRCodeGenerator.image(from: $0) }
                do {
                    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
                    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                    let url = directory.appendingPathComponent("HeritLink Kitchen.json")
                    try transfer.encoded().write(to: url, options: .atomic)
                    fileURL = url
                } catch {
                    errorMessage = "Couldn’t prepare the file. Close this card and try again."
                }
            }
        }
    }
}

struct SharedKitchenHeader: View {
    let name: String
    let level: String
    let count: Int

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle).foregroundStyle(SavourTheme.forest)
            Text(name).font(.title.bold())
            Text(level).foregroundStyle(.secondary)
            Text("\(count) shared recipes").font(.subheadline)
        }
        .frame(maxWidth: .infinity).padding(.vertical)
    }
}

struct KitchenPreviewView: View {
    let transfer: KitchenTransfer
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var savedIDs: Set<UUID> = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                SharedKitchenHeader(name: transfer.name, level: transfer.cookingLevel, count: transfer.recipes.count)
                Text("Shared snapshot · saved recipes stay available offline.")
                    .font(.caption).foregroundStyle(.secondary)
                if transfer.recipes.isEmpty {
                    Text("This cook shared their profile without recipes.")
                }
                ForEach(transfer.recipes, id: \.id) { recipe in
                    DisclosureGroup(recipe.title) {
                        RecipeDietBadge(diet: RecipeDiet(rawValue: recipe.dietRawValue ?? "") ?? .unspecified)
                        Text(recipe.summary)
                        Label("\(recipe.cookingMinutes) min · \(recipe.servings) servings", systemImage: "clock")
                        ForEach(recipe.ingredients) { ingredient in
                            Text("\(ingredient.quantity) \(ingredient.name)")
                        }
                        ForEach(recipe.steps) { step in Text(step.instruction) }
                        if !recipe.story.isEmpty { Text(recipe.story).italic() }
                        Button(savedIDs.contains(recipe.id) ? "Saved" : "Save recipe") { save(recipe) }
                            .disabled(savedIDs.contains(recipe.id))
                    }
                }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
            }
            .navigationTitle("Shared kitchen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
        .tint(SavourTheme.forest)
    }

    private func save(_ transfer: RecipeTransfer) {
        do {
            let sourceID = transfer.id
            let existing = try modelContext.fetch(FetchDescriptor<Recipe>(
                predicate: #Predicate { $0.id == sourceID }
            ))
            if let recipe = existing.first {
                recipe.isSaved = true
            } else {
                let recipe = transfer.makeRecipe()
                recipe.id = transfer.id
                recipe.isUserCreated = false
                modelContext.insert(recipe)
            }
            try modelContext.save()
            savedIDs.insert(transfer.id)
            errorMessage = nil
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn’t save this recipe. Please try again."
        }
    }
}
