import SwiftUI
import UIKit

enum SavourTheme {
    static let cream = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let paper = Color(red: 1.00, green: 0.99, blue: 0.96)
    static let forest = Color(red: 0.10, green: 0.25, blue: 0.18)
    static let moss = Color(red: 0.35, green: 0.45, blue: 0.28)
    static let terracotta = Color(red: 0.72, green: 0.30, blue: 0.18)
    static let ink = Color(red: 0.12, green: 0.14, blue: 0.11)
    static let muted = Color(red: 0.38, green: 0.39, blue: 0.34)
}

struct RecipeArtwork: View {
    let photoData: Data?
    let assetName: String?
    let seed: Int
    var height: CGFloat = 190

    private let palettes: [[Color]] = [
        [Color(red: 0.30, green: 0.42, blue: 0.25), Color(red: 0.72, green: 0.54, blue: 0.26)],
        [Color(red: 0.54, green: 0.18, blue: 0.12), Color(red: 0.90, green: 0.58, blue: 0.25)],
        [Color(red: 0.80, green: 0.42, blue: 0.16), Color(red: 0.38, green: 0.18, blue: 0.10)],
        [Color(red: 0.63, green: 0.18, blue: 0.12), Color(red: 0.96, green: 0.62, blue: 0.28)],
        [Color(red: 0.18, green: 0.42, blue: 0.24), Color(red: 0.72, green: 0.69, blue: 0.28)],
        [Color(red: 0.28, green: 0.47, blue: 0.35), Color(red: 0.92, green: 0.75, blue: 0.34)]
    ]

    var body: some View {
        ZStack {
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else {
                let palette = palettes[abs(seed) % palettes.count]
                LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
                Circle()
                    .fill(.white.opacity(0.16))
                    .frame(width: height * 0.72)
                    .offset(x: height * 0.34, y: -height * 0.22)
                Image(systemName: ["leaf.fill", "takeoutbag.and.cup.and.straw.fill", "frying.pan.fill", "carrot.fill", "tortoise.fill", "fork.knife"][abs(seed) % 6])
                    .font(.system(size: height * 0.30, weight: .light))
                    .foregroundStyle(.white.opacity(0.88))
                    .rotationEffect(.degrees(-8))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .accessibilityHidden(photoData == nil)
    }
}

struct RecipeCard: View {
    let recipe: Recipe
    var compact = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            RecipeArtwork(photoData: recipe.photoData, assetName: recipe.assetName, seed: recipe.visualSeed, height: compact ? 128 : 180)

            VStack(alignment: .leading, spacing: 7) {
                Text(recipe.cuisine.uppercased())
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(SavourTheme.terracotta)

                Text(recipe.title)
                    .font((compact ? Font.headline : Font.title3).weight(.semibold))
                    .foregroundStyle(SavourTheme.ink)
                    .lineLimit(2)

                RecipeDietBadge(diet: recipe.diet)

                HStack(spacing: 12) {
                    Label("\(recipe.cookingMinutes) min", systemImage: "clock")
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar.fill")
                }
                .font(.caption)
                .foregroundStyle(SavourTheme.muted)
            }
            .padding(14)
        }
        .background(SavourTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: SavourTheme.forest.opacity(0.08), radius: 12, y: 5)
    }
}

struct SectionHeading: View {
    let eyebrow: String?
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(eyebrow: String? = nil, title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 3) {
                if let eyebrow {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.4)
                        .foregroundStyle(SavourTheme.terracotta)
                }
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(SavourTheme.forest)
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SavourTheme.forest)
            }
        }
    }
}

struct EmptyKitchenView: View {
    let title: String
    let message: String
    let systemImage: String

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: systemImage)
        } description: {
            Text(message)
        }
        .foregroundStyle(SavourTheme.forest)
    }
}

extension View {
    func savourBackground() -> some View {
        background(SavourTheme.cream.ignoresSafeArea())
    }
}
