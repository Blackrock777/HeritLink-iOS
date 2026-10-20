import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Query(sort: \ShoppingItem.createdAt) private var items: [ShoppingItem]
    @Environment(\.modelContext) private var modelContext
    @State private var newItem = ""
    @State private var errorMessage: String?

    private var remaining: [ShoppingItem] { items.filter { !$0.isChecked } }
    private var checked: [ShoppingItem] { items.filter(\.isChecked) }
    private var shareText: String {
        "Savour shopping list\n\n" + remaining.map {
            let source = $0.recipeTitle.isEmpty ? "" : " — \($0.recipeTitle)"
            return "☐ \($0.quantity) \($0.name)\(source)"
        }.joined(separator: "\n")
    }

    var body: some View {
        List {
            Section {
                HStack {
                    TextField("Add something else", text: $newItem)
                        .submitLabel(.done).onSubmit(addItem)
                    Button("Add", systemImage: "plus", action: addItem)
                        .labelStyle(.iconOnly)
                        .disabled(newItem.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                Text("\(remaining.count) left to pick up")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            if items.isEmpty {
                ContentUnavailableView("Your list is ready", systemImage: "basket",
                                       description: Text("Add items here or open a recipe and tap Shopping needs."))
            }
            Section("To buy") {
                ForEach(remaining) { item in
                    ShoppingItemRow(item: item) { toggle(item) }
                }
                .onDelete { offsets in remove(offsets.map { remaining[$0] }) }
            }
            if !checked.isEmpty {
                Section("In the basket") {
                    ForEach(checked) { item in
                        ShoppingItemRow(item: item) { toggle(item) }
                    }
                    .onDelete { offsets in remove(offsets.map { checked[$0] }) }
                    Button("Clear checked items") { remove(checked) }
                }
            }
            if let errorMessage { Text(errorMessage).foregroundStyle(.red) }
        }
        .navigationTitle("Shopping list")
        .toolbar(.visible, for: .navigationBar)
        .scrollContentBackground(.hidden)
        .savourBackground()
        .toolbar {
            ShareLink(item: shareText) {
                Label("Share shopping list", systemImage: "square.and.arrow.up")
            }
            .disabled(remaining.isEmpty)
        }
    }

    private func addItem() {
        let name = newItem.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        modelContext.insert(ShoppingItem(name: name))
        if save() { newItem = "" }
    }

    private func toggle(_ item: ShoppingItem) {
        item.isChecked.toggle()
        _ = save()
    }

    private func remove(_ removed: [ShoppingItem]) {
        for item in removed { modelContext.delete(item) }
        _ = save()
    }

    @discardableResult
    private func save() -> Bool {
        do {
            try modelContext.save()
            errorMessage = nil
            return true
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn’t save your changes. Please try again."
            return false
        }
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2).foregroundStyle(SavourTheme.forest)
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(item.quantity) \(item.name)".trimmingCharacters(in: .whitespaces))
                        .strikethrough(item.isChecked)
                        .foregroundStyle(.primary)
                    if !item.recipeTitle.isEmpty {
                        Text(item.recipeTitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(item.quantity) \(item.name), \(item.isChecked ? "checked" : "not checked")")
        .accessibilityHint("Double tap to change whether this item is in your basket")
    }
}

struct PersonalRecipeNotesView: View {
    let recipeID: UUID
    @Query private var notes: [RecipeNote]
    @Environment(\.modelContext) private var modelContext
    @State private var draft = ""
    @Binding var isEditing: Bool
    @FocusState private var isNoteFocused: Bool
    @State private var errorMessage: String?

    init(recipeID: UUID, isEditing: Binding<Bool>) {
        self.recipeID = recipeID
        _isEditing = isEditing
        _notes = Query(filter: #Predicate<RecipeNote> { $0.recipeID == recipeID })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Next time I cook this", systemImage: "note.text")
                .font(.title2.bold()).foregroundStyle(SavourTheme.forest)
            Text("Your private tweaks. Never included in shared recipes.")
                .font(.caption).foregroundStyle(.secondary)
            if isEditing {
                TextField("Less salt? More lemon? Write what worked.", text: $draft, axis: .vertical)
                    .lineLimit(3...10)
                    .focused($isNoteFocused)
                    .padding(12)
                    .background(SavourTheme.cream, in: RoundedRectangle(cornerRadius: 12))
                HStack {
                    Button("Cancel") { isEditing = false; errorMessage = nil }
                    Spacer()
                    Button("Save note", action: save).buttonStyle(.borderedProminent)
                }
            } else {
                if let note = notes.first, !note.text.isEmpty {
                    Text(note.text).textSelection(.enabled)
                    Text(note.updatedAt, format: .dateTime.day().month().year())
                        .font(.caption).foregroundStyle(.secondary)
                }
                Button(notes.first == nil ? "Add a cooking note" : "Edit note") {
                    draft = notes.first?.text ?? ""
                    isEditing = true
                }
            }
            if let errorMessage { Text(errorMessage).font(.caption).foregroundStyle(.red) }
        }
        .padding(20)
        .background(SavourTheme.paper, in: RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, 20)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isNoteFocused = false }
            }
        }
    }

    private func save() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        if let note = notes.first {
            if text.isEmpty { modelContext.delete(note) }
            else { note.text = text; note.updatedAt = .now }
        } else if !text.isEmpty {
            modelContext.insert(RecipeNote(recipeID: recipeID, text: text))
        }
        do {
            try modelContext.save()
            isEditing = false
            errorMessage = nil
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn’t save your note. Your draft is still here; try again."
        }
    }
}
