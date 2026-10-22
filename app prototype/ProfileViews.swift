import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct WelcomeProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @State private var cookingLevel = CookingLevel.curious
    @State private var selectedInterests: Set<String> = []
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @FocusState private var isNameFocused: Bool

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            WelcomeBackdrop()

            ScrollView {
                VStack(spacing: 26) {
                    WelcomeBrandHeader()
                    ProfilePhotoPicker(photoData: photoData, selection: $photoItem)
                    WelcomeIdentitySection(name: $name, isNameFocused: $isNameFocused)
                    CookingLevelPicker(selection: $cookingLevel)
                    CookingInterestsPicker(selection: $selectedInterests)
                    WelcomePrivacyNote()

                    Button(action: createProfile) {
                        Text("Enter HeritLink")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(SavourTheme.forest, in: Capsule())
                            .foregroundStyle(.white)
                    }
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.45)
                    .accessibilityHint("Creates a profile stored only on this iPhone")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 30)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .task(id: photoItem) {
            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                photoData = data
            }
        }
    }

    private func createProfile() {
        let profile = LocalProfile(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData,
            cookingLevel: cookingLevel.rawValue,
            interests: selectedInterests.sorted()
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }
}

struct WelcomeBackdrop: View {
    var body: some View {
        ZStack {
            SavourTheme.cream.ignoresSafeArea()
            Circle()
                .fill(SavourTheme.terracotta.opacity(0.10))
                .frame(width: 330, height: 330)
                .offset(x: 170, y: -330)
            Circle()
                .fill(SavourTheme.moss.opacity(0.12))
                .frame(width: 280, height: 280)
                .offset(x: -170, y: 370)
        }
        .accessibilityHidden(true)
    }
}

struct WelcomeBrandHeader: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 54))
                .symbolRenderingMode(.palette)
                .foregroundStyle(SavourTheme.paper, SavourTheme.forest)

            Text("HeritLink")
                .font(.caption.weight(.black))
                .tracking(3)
                .foregroundStyle(SavourTheme.terracotta)

            Text("Your kitchen, remembered.")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(SavourTheme.forest)

            Text("Tell us a little about how you cook. This stays private on your iPhone.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(SavourTheme.muted)
                .lineSpacing(3)
        }
    }
}

struct ProfilePhotoPicker: View {
    let photoData: Data?
    @Binding var selection: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selection, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                ProfileAvatar(photoData: photoData, name: "", size: 112)
                Image(systemName: "camera.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(SavourTheme.terracotta, in: Circle())
                    .overlay(Circle().stroke(SavourTheme.cream, lineWidth: 3))
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(photoData == nil ? "Add an optional profile photo" : "Change profile photo")
    }
}

struct WelcomeIdentitySection: View {
    @Binding var name: String
    let isNameFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("What should we call you?")
                .font(.headline)
                .foregroundStyle(SavourTheme.forest)
            HStack {
                Image(systemName: "person")
                    .foregroundStyle(SavourTheme.moss)
                TextField("Your name", text: $name)
                    .textContentType(.name)
                    .submitLabel(.done)
                    .focused(isNameFocused)
            }
            .padding()
            .background(SavourTheme.paper, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

struct CookingLevelPicker: View {
    @Binding var selection: CookingLevel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your cooking rhythm")
                .font(.headline)
                .foregroundStyle(SavourTheme.forest)

            VStack(spacing: 8) {
                ForEach(CookingLevel.allCases) { level in
                    Button {
                        selection = level
                    } label: {
                        HStack {
                            Image(systemName: level.systemImage)
                                .frame(width: 24)
                            Text(level.rawValue)
                            Spacer()
                            Image(systemName: selection == level ? "checkmark.circle.fill" : "circle")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(selection == level ? SavourTheme.forest : SavourTheme.muted)
                        .padding(13)
                        .background(
                            selection == level ? SavourTheme.forest.opacity(0.10) : SavourTheme.paper,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct CookingInterestsPicker: View {
    @Binding var selection: Set<String>

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("What inspires you?")
                .font(.headline)
                .foregroundStyle(SavourTheme.forest)
            Text("Optional · choose as many as you like")
                .font(.caption)
                .foregroundStyle(SavourTheme.muted)

            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(CookingInterest.allCases) { interest in
                    let isSelected = selection.contains(interest.rawValue)
                    Button {
                        if isSelected {
                            selection.remove(interest.rawValue)
                        } else {
                            selection.insert(interest.rawValue)
                        }
                    } label: {
                        Label(interest.rawValue, systemImage: interest.systemImage)
                            .font(.caption.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .foregroundStyle(isSelected ? .white : SavourTheme.forest)
                            .background(
                                isSelected ? SavourTheme.forest : SavourTheme.paper,
                                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
        }
    }
}

struct WelcomePrivacyNote: View {
    var body: some View {
        Label {
            Text("No account or password. Your profile never leaves this device unless you choose to share your kitchen or a recipe.")
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(SavourTheme.moss)
        }
        .font(.caption)
        .foregroundStyle(SavourTheme.muted)
        .padding(14)
        .background(SavourTheme.paper.opacity(0.8), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct LocalProfileEditorView: View {
    @Bindable var profile: LocalProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var photoItem: PhotosPickerItem?
    @State private var selectedInterests: Set<String>
    @State private var selectedLevel: CookingLevel
    @State private var showLogoutConfirmation = false

    init(profile: LocalProfile) {
        self.profile = profile
        _selectedInterests = State(initialValue: Set(profile.interests))
        _selectedLevel = State(initialValue: CookingLevel(rawValue: profile.cookingLevel) ?? .curious)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        ProfilePhotoPicker(photoData: profile.photoData, selection: $photoItem)
                        Spacer()
                    }
                }

                Section("Profile") {
                    TextField("Your name", text: $profile.name)
                        .textContentType(.name)
                    Picker("Cooking rhythm", selection: $selectedLevel) {
                        ForEach(CookingLevel.allCases) { level in
                            Text(level.rawValue).tag(level)
                        }
                    }
                }

                Section("Interests") {
                    CookingInterestsPicker(selection: $selectedInterests)
                        .padding(.vertical, 6)
                }

                Section {
                    WelcomePrivacyNote()
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                Section {
                    Button("Log Out on This Device", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                        showLogoutConfirmation = true
                    }
                } footer: {
                    Text("This removes only your local profile. Your recipes and saved collection stay on this iPhone.")
                }
            }
            .scrollContentBackground(.hidden)
            .savourBackground()
            .navigationTitle("Your Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: save)
                        .disabled(profile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task(id: photoItem) {
                if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                    profile.photoData = data
                }
            }
            .confirmationDialog(
                "Log out of HeritLink?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Log Out", role: .destructive, action: logOut)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your recipes remain safely stored. You’ll return to the local welcome screen.")
            }
        }
    }

    private func logOut() {
        modelContext.delete(profile)
        try? modelContext.save()
        dismiss()
    }

    private func save() {
        profile.name = profile.name.trimmingCharacters(in: .whitespacesAndNewlines)
        profile.cookingLevel = selectedLevel.rawValue
        profile.interests = selectedInterests.sorted()
        profile.updatedAt = .now
        try? modelContext.save()
        dismiss()
    }
}

struct ProfileAvatar: View {
    let photoData: Data?
    let name: String
    let size: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(SavourTheme.forest)
            if let photoData, let image = UIImage(data: photoData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else if let initial = name.trimmingCharacters(in: .whitespaces).first {
                Text(String(initial).uppercased())
                    .font(.system(size: size * 0.38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.34))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
