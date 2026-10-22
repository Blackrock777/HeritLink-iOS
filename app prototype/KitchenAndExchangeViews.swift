import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins
import VisionKit
import Vision
import UIKit

struct MyKitchenView: View {
    @Query(sort: \Recipe.updatedAt, order: .reverse) private var recipes: [Recipe]
    let profile: LocalProfile
    @Environment(\.modelContext) private var modelContext
    @State private var segment = KitchenSegment.created
    @State private var showEditor = false
    @State private var showImporter = false
    @State private var showScanner = false
    @State private var showProfile = false
    @State private var showKitchenShare = false
    @State private var receivedKitchen: KitchenTransfer?
    @State private var importMessage: String?

    private var visibleRecipes: [Recipe] {
        switch segment {
        case .created: recipes.filter(\.isUserCreated)
        case .saved: recipes.filter(\.isSaved)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Button { showKitchenShare = true } label: {
                    Label("Share my kitchen", systemImage: "qrcode")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .tint(SavourTheme.forest)

                Picker("Collection", selection: $segment) {
                    ForEach(KitchenSegment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding()

                if visibleRecipes.isEmpty {
                    EmptyKitchenView(
                        title: segment == .created ? "Your recipes live here" : "Nothing saved yet",
                        message: segment == .created ? "Add a family favorite or invent something new." : "Bookmark any recipe to keep it close.",
                        systemImage: segment == .created ? "book.closed" : "bookmark"
                    )
                } else {
                    List {
                        ForEach(visibleRecipes) { recipe in
                            NavigationLink(value: recipe) {
                                KitchenRecipeRow(recipe: recipe)
                            }
                            .listRowBackground(SavourTheme.paper)
                        }
                        .onDelete(perform: delete)
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .savourBackground()
            .navigationTitle("My Kitchen")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Button("Import file", systemImage: "doc.badge.plus") { showImporter = true }
                        Button("Scan QR", systemImage: "qrcode.viewfinder") { showScanner = true }
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                    }
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    NavigationLink {
                        ShoppingListView()
                    } label: {
                        Label("Shopping list", systemImage: "basket")
                    }

                    Button {
                        showProfile = true
                    } label: {
                        ProfileAvatar(photoData: profile.photoData, name: profile.name, size: 30)
                    }
                    .accessibilityLabel("Edit local profile")

                    Button("Add recipe", systemImage: "plus") { showEditor = true }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .sheet(isPresented: $showEditor) {
                NavigationStack { RecipeEditorView() }
            }
            .sheet(isPresented: $showKitchenShare) {
                KitchenShareView(profile: profile)
            }
            .sheet(item: $receivedKitchen) { KitchenPreviewView(transfer: $0) }
            .sheet(isPresented: $showProfile) {
                LocalProfileEditorView(profile: profile)
            }
            .sheet(isPresented: $showScanner) {
                RecipeScannerView { transfer in
                    importTransfer(transfer)
                    showScanner = false
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.savourRecipe, .json],
                allowsMultipleSelection: false
            ) { result in
                importFile(result)
            }
            .alert("Recipe Import", isPresented: Binding(
                get: { importMessage != nil },
                set: { if !$0 { importMessage = nil } }
            )) {
                Button("OK") { importMessage = nil }
            } message: {
                Text(importMessage ?? "")
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let recipe = visibleRecipes[index]
            if recipe.isUserCreated {
                modelContext.delete(recipe)
            } else {
                recipe.isSaved = false
            }
        }
        try? modelContext.save()
    }

    private func importFile(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            if let kitchen = try? KitchenTransfer.decode(data) {
                receivedKitchen = kitchen
            } else {
                importTransfer(try RecipeTransfer.decode(data))
            }
        } catch {
            importMessage = "That file could not be read as a supported HeritLink recipe or kitchen."
        }
    }

    private func importTransfer(_ transfer: RecipeTransfer) {
        guard transfer.formatVersion <= RecipeTransfer.formatVersion else {
            importMessage = "This recipe was made by a newer version of HeritLink."
            return
        }
        modelContext.insert(transfer.makeRecipe())
        try? modelContext.save()
        segment = .created
        importMessage = "“\(transfer.title)” was added to My Kitchen."
    }
}

enum KitchenSegment: String, CaseIterable, Identifiable {
    case created = "My Recipes"
    case saved = "Saved"

    var id: String { rawValue }
}

struct KitchenRecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 14) {
            RecipeArtwork(photoData: recipe.photoData, assetName: recipe.assetName, seed: recipe.visualSeed, height: 78)
                .frame(width: 92)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.title)
                    .font(.headline)
                    .foregroundStyle(SavourTheme.ink)
                RecipeDietBadge(diet: recipe.diet)
                Text(recipe.cuisine)
                    .font(.subheadline)
                    .foregroundStyle(SavourTheme.terracotta)
                Label("\(recipe.cookingMinutes) min", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct RecipeExchangeView: View {
    let recipe: Recipe
    @State private var shareURL: URL?
    @State private var showShareSheet = false
    @Environment(\.dismiss) private var dismiss

    private var compactData: Data? {
        guard let data = try? RecipeTransfer(recipe: recipe, includePhoto: false).encoded() else { return nil }
        let payload = "SAVOUR1:" + data.base64EncodedString()
        return payload.data(using: .utf8)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 8) {
                        Text("Share offline")
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(SavourTheme.forest)
                        Text("The QR code carries the recipe itself. No server, account or connection is used.")
                            .font(.subheadline)
                            .foregroundStyle(SavourTheme.muted)
                            .multilineTextAlignment(.center)
                    }

                    if let compactData, compactData.count <= 2_200,
                       let image = QRCodeGenerator.image(from: compactData) {
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 280)
                            .padding(18)
                            .background(.white, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .accessibilityLabel("QR code for \(recipe.title)")
                        Text("Point another iPhone’s HeritLink scanner here.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ContentUnavailableView(
                            "Recipe is too detailed for QR",
                            systemImage: "qrcode",
                            description: Text("Use the complete recipe file below instead.")
                        )
                    }

                    Button {
                        prepareFile()
                    } label: {
                        Label("Share complete recipe file", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(SavourTheme.forest, in: Capsule())
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    }
                }
                .padding(24)
            }
            .savourBackground()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL {
                    ActivityView(items: [shareURL])
                }
            }
        }
    }

    private func prepareFile() {
        do {
            let safeTitle = recipe.title
                .replacingOccurrences(of: "/", with: "-")
                .replacingOccurrences(of: ":", with: "-")
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(safeTitle)
                .appendingPathExtension("savourrecipe")
            try RecipeTransfer(recipe: recipe).encoded(prettyPrinted: true).write(to: url, options: .atomic)
            shareURL = url
            showShareSheet = true
        } catch {
            shareURL = nil
        }
    }
}

enum QRCodeGenerator {
    private static let context = CIContext()

    static func image(from data: Data) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "M"
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 10, y: 10)),
              let cgImage = context.createCGImage(output, from: output.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

struct RecipeScannerView: View {
    let onImport: (RecipeTransfer) -> Void
    @State private var message = "Center a HeritLink QR code in the frame."
    @State private var isScanning = true
    @State private var receivedKitchen: KitchenTransfer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                    DataScannerRepresentable(isScanning: $isScanning) { payload in
                        decode(payload)
                    }
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(.white, lineWidth: 3)
                        .frame(width: 280, height: 280)
                        .shadow(color: .black.opacity(0.4), radius: 6)
                    VStack {
                        Spacer()
                        Text(message)
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding()
                            .background(.black.opacity(0.65), in: Capsule())
                            .padding(.bottom, 30)
                    }
                } else {
                    ContentUnavailableView(
                        "Scanner unavailable",
                        systemImage: "camera.fill",
                        description: Text("This device does not support live recipe scanning. Import a recipe file instead.")
                    )
                    .foregroundStyle(.white)
                }
            }
            .sheet(item: $receivedKitchen, onDismiss: { isScanning = true }) {
                KitchenPreviewView(transfer: $0)
            }
            .navigationTitle("Scan QR")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func decode(_ payload: String) {
        guard isScanning else { return }
        if payload.hasPrefix("SAVOURK1:") {
            guard payload.utf8.count <= 2_200,
                  let data = Data(base64Encoded: String(payload.dropFirst(9))),
                  let kitchen = try? KitchenTransfer.decode(data) else {
                message = "This kitchen code is invalid or needs a newer version of HeritLink."
                return
            }
            isScanning = false
            receivedKitchen = kitchen
            return
        }
        guard payload.hasPrefix("SAVOUR1:"),
              let data = Data(base64Encoded: String(payload.dropFirst(8))),
              let transfer = try? RecipeTransfer.decode(data) else {
            message = "That isn’t a supported HeritLink QR code."
            return
        }
        isScanning = false
        onImport(transfer)
    }
}

struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var isScanning: Bool
    let onPayload: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPayload: onPayload)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: true,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        if isScanning && !controller.isScanning {
            try? controller.startScanning()
        } else if !isScanning && controller.isScanning {
            controller.stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let onPayload: (String) -> Void

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            for item in addedItems {
                if case let .barcode(barcode) = item, let payload = barcode.payloadStringValue {
                    onPayload(payload)
                    return
                }
            }
        }
    }
}
