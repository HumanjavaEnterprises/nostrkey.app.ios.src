import SwiftUI
import CoreImage.CIFilterBuiltins

/// Main dashboard view — the default tab.
/// Shows active profile card with context actions (Details, Share, History, Manage),
/// profile list, relay status, and NIP-46 sessions.
struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCopied = false
    @State private var showCreateProfile = false
    @State private var showImport = false
    @State private var importNsec = ""
    @State private var errorMessage: String?

    // Profile action sheets
    @State private var showDetails = false
    @State private var showShare = false
    @State private var showHistory = false
    @State private var showManage = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active profile card (if any)
                    if let profile = appState.activeProfile {
                        activeProfileCard(profile: profile)

                        // Profile context actions
                        profileActions
                    }

                    // Profile list
                    profileListSection

                    // Relay status
                    relayStatusSection

                    // NIP-46 sessions
                    if !appState.activeSessions.isEmpty {
                        sessionsSection
                    }
                }
                .padding()
            }
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("NostrKeep Signer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCreateProfile = true
                        } label: {
                            Label("Create New Identity", systemImage: "plus.circle")
                        }
                        Button {
                            showImport = true
                        } label: {
                            Label("Import Existing Keys", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(NostrKeepSignerTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showCreateProfile) {
                CreateProfileSheet()
            }
            .sheet(isPresented: $showImport) {
                ImportKeysView(nsec: $importNsec) {
                    do {
                        try appState.importKeys(nsec: importNsec)
                        showImport = false
                        importNsec = ""
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            }
            .sheet(isPresented: $showDetails) {
                if let profile = appState.activeProfile {
                    ProfileDetailsSheet(profile: profile)
                }
            }
            .sheet(isPresented: $showShare) {
                if let profile = appState.activeProfile {
                    ProfileShareSheet(profile: profile)
                }
            }
            .sheet(isPresented: $showHistory) {
                ProfileHistorySheet()
            }
            .sheet(isPresented: $showManage) {
                ProfileManageSheet()
            }
        }
    }

    // MARK: - Active Profile Card

    @ViewBuilder
    private func activeProfileCard(profile: NostrProfile) -> some View {
        VStack(spacing: 16) {
            // Header row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Profile")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)

                    Text(profile.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(NostrKeepSignerTheme.text)
                }

                Spacer()

                // Security badge
                HStack(spacing: 4) {
                    Image(systemName: profile.isSecureEnclave ? "lock.shield.fill" : "lock.open")
                        .font(.caption)
                    Text(profile.isSecureEnclave ? "Secured" : "Software")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    (profile.isSecureEnclave ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.orange)
                        .opacity(0.15)
                )
                .foregroundStyle(profile.isSecureEnclave ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.orange)
                .clipShape(Capsule())
            }

            // QR Code
            if let qrImage = generateQRCode(from: profile.npub) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.vertical, 4)
            }

            // npub display
            Button {
                UIPasteboard.general.string = profile.npub
                showCopied = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showCopied = false
                }
            } label: {
                HStack {
                    Text(profile.displayNpub)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        .lineLimit(1)

                    Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(showCopied ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.textMuted)
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(NostrKeepSignerTheme.bgLight)
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(NostrKeepSignerTheme.accent.opacity(0.3), lineWidth: 1)
                }
        }
    }

    // MARK: - Profile Context Actions

    @ViewBuilder
    private var profileActions: some View {
        HStack(spacing: 12) {
            profileActionButton(
                icon: "info.circle",
                label: "Details",
                color: NostrKeepSignerTheme.cyan
            ) {
                showDetails = true
            }

            profileActionButton(
                icon: "square.and.arrow.up",
                label: "Share",
                color: NostrKeepSignerTheme.accent
            ) {
                showShare = true
            }

            profileActionButton(
                icon: "clock.arrow.circlepath",
                label: "History",
                color: NostrKeepSignerTheme.orange
            ) {
                showHistory = true
            }

            profileActionButton(
                icon: "slider.horizontal.3",
                label: "Manage",
                color: NostrKeepSignerTheme.textMuted
            ) {
                showManage = true
            }
        }
    }

    @ViewBuilder
    private func profileActionButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(NostrKeepSignerTheme.bgLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Profile List

    @ViewBuilder
    private var profileListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Profiles")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(NostrKeepSignerTheme.textMuted)

            if appState.profiles.isEmpty {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    Text("No profiles yet. Create or import one to get started.")
                        .font(.subheadline)
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(NostrKeepSignerTheme.bgLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(appState.profiles.enumerated()), id: \.element.id) { index, profile in
                        profileRow(profile: profile, index: index)

                        if index < appState.profiles.count - 1 {
                            Divider()
                                .background(NostrKeepSignerTheme.bg)
                        }
                    }
                }
                .background(NostrKeepSignerTheme.bgLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    @ViewBuilder
    private func profileRow(profile: NostrProfile, index: Int) -> some View {
        let isActive = profile.id == appState.activeProfile?.id

        Button {
            setActiveProfile(index: index)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.title2)
                    .foregroundStyle(isActive ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.brown)

                VStack(alignment: .leading, spacing: 2) {
                    Text(profile.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isActive ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.text)

                    Text(profile.displayNpub)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        .lineLimit(1)
                }

                Spacer()

                if isActive {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(NostrKeepSignerTheme.accent)
                } else {
                    Text("Select")
                        .font(.caption)
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Relay Status

    @ViewBuilder
    private var relayStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Relays")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(NostrKeepSignerTheme.textMuted)

            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(appState.relays.isEmpty ? NostrKeepSignerTheme.orange : NostrKeepSignerTheme.accent)

                if appState.relays.isEmpty {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No relays configured")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(NostrKeepSignerTheme.orange)

                        Text("Add relays to connect to the Nostr network.")
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }

                    Spacer()

                    Button("Add") {
                        appState.selectedTab = .relays
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(NostrKeepSignerTheme.accent)
                    .foregroundStyle(NostrKeepSignerTheme.bg)
                    .clipShape(Capsule())
                } else {
                    Text("\(appState.relays.count) relay\(appState.relays.count == 1 ? "" : "s") configured")
                        .font(.subheadline)
                        .foregroundStyle(NostrKeepSignerTheme.text)

                    Spacer()

                    Button {
                        appState.selectedTab = .relays
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }
                }
            }
            .padding()
            .background(NostrKeepSignerTheme.bgLight)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - NIP-46 Sessions

    @ViewBuilder
    private var sessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connected Apps")
                .font(.caption)
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(NostrKeepSignerTheme.textMuted)

            ForEach(appState.activeSessions, id: \.id) { session in
                HStack {
                    Image(systemName: "app.connected.to.app.below.fill")
                        .foregroundStyle(NostrKeepSignerTheme.cyan)

                    VStack(alignment: .leading) {
                        Text(session.appName ?? "Unknown App")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(NostrKeepSignerTheme.text)

                        Text(session.relayURL)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }

                    Spacer()

                    Circle()
                        .fill(NostrKeepSignerTheme.accent)
                        .frame(width: 8, height: 8)
                }
                .padding()
                .background(NostrKeepSignerTheme.bgLight)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helpers

    private func setActiveProfile(index: Int) {
        guard index < appState.profiles.count else { return }
        for i in 0..<appState.profiles.count {
            appState.profiles[i].isActive = false
        }
        appState.profiles[index].isActive = true
        appState.activeProfile = appState.profiles[index]
        appState.saveProfiles()
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scale = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = ciImage.transformed(by: scale)
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Create Profile Sheet

struct CreateProfileSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var profileName = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    @State private var createdProfile: NostrProfile?

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(NostrKeepSignerTheme.accent)
                    .padding(.top, 8)

                Text("Create a name for this identity. A new Nostr keypair will be generated and stored securely on this device.")
                    .font(.subheadline)
                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                // Name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Profile Name")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .textCase(.uppercase)
                        .foregroundStyle(NostrKeepSignerTheme.textMuted)

                    TextField("e.g. Personal, Work, Anon", text: $profileName)
                        .font(.body)
                        .padding()
                        .background(NostrKeepSignerTheme.bgLight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(NostrKeepSignerTheme.accent.opacity(0.3), lineWidth: 1)
                        }
                        .autocorrectionDisabled()
                }
                .padding(.horizontal)

                // Created profile preview
                if let profile = createdProfile {
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(NostrKeepSignerTheme.accent)
                            Text("Identity Created")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(NostrKeepSignerTheme.accent)
                        }

                        Text(profile.npub)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(NostrKeepSignerTheme.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(NostrKeepSignerTheme.red)
                        .padding(.horizontal)
                }

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    if createdProfile == nil {
                        Button {
                            generateProfile()
                        } label: {
                            HStack {
                                if isCreating {
                                    ProgressView()
                                        .tint(NostrKeepSignerTheme.bg)
                                } else {
                                    Image(systemName: "key.fill")
                                }
                                Text(isCreating ? "Generating..." : "Generate Identity")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(profileName.trimmingCharacters(in: .whitespaces).isEmpty ? NostrKeepSignerTheme.bgLight : NostrKeepSignerTheme.accent)
                            .foregroundStyle(profileName.trimmingCharacters(in: .whitespaces).isEmpty ? NostrKeepSignerTheme.textMuted : NostrKeepSignerTheme.bg)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(profileName.trimmingCharacters(in: .whitespaces).isEmpty || isCreating)
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Text("Done")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(NostrKeepSignerTheme.accent)
                                .foregroundStyle(NostrKeepSignerTheme.bg)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 16)
            }
            .padding(.top, 24)
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("New Identity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func generateProfile() {
        let name = profileName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        isCreating = true
        errorMessage = nil

        Task {
            do {
                try await appState.createNewIdentity(name: name)
                createdProfile = appState.activeProfile
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}

// MARK: - Profile Details Sheet

struct ProfileDetailsSheet: View {
    let profile: NostrProfile
    @Environment(\.dismiss) var dismiss
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // QR Code
                    if let qrImage = generateQRCode(from: profile.npub) {
                        Image(uiImage: qrImage)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Profile info rows
                    VStack(spacing: 0) {
                        detailRow(label: "Name", value: profile.name)
                        Divider().background(NostrKeepSignerTheme.bg)
                        detailRow(label: "Public Key (npub)", value: profile.npub, monospaced: true, copiable: true)
                        Divider().background(NostrKeepSignerTheme.bg)
                        detailRow(label: "Hex Pubkey", value: profile.pubkeyHex, monospaced: true, copiable: true)
                        Divider().background(NostrKeepSignerTheme.bg)
                        detailRow(label: "Created", value: profile.createdAt.formatted(date: .abbreviated, time: .shortened))
                        Divider().background(NostrKeepSignerTheme.bg)
                        detailRow(label: "Key Storage", value: profile.isSecureEnclave ? "Secure Enclave + Face ID" : "Software Keychain")
                    }
                    .background(NostrKeepSignerTheme.bgLight)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
            }
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("Profile Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    @ViewBuilder
    private func detailRow(label: String, value: String, monospaced: Bool = false, copiable: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(NostrKeepSignerTheme.textMuted)

            HStack {
                if monospaced {
                    Text(value)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(NostrKeepSignerTheme.text)
                        .lineLimit(3)
                } else {
                    Text(value)
                        .font(.subheadline)
                        .foregroundStyle(NostrKeepSignerTheme.text)
                }

                Spacer()

                if copiable {
                    Button {
                        UIPasteboard.general.string = value
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.accent)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Profile Share Sheet

struct ProfileShareSheet: View {
    let profile: NostrProfile
    @Environment(\.dismiss) var dismiss
    @State private var showCopied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // QR for sharing
                if let qrImage = generateQRCode(from: profile.npub) {
                    Image(uiImage: qrImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Text(profile.displayNpub)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(NostrKeepSignerTheme.textMuted)

                VStack(spacing: 12) {
                    // Copy npub
                    Button {
                        UIPasteboard.general.string = profile.npub
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showCopied = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                            Text(showCopied ? "Copied!" : "Copy npub")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(NostrKeepSignerTheme.accent.opacity(0.15))
                        .foregroundStyle(NostrKeepSignerTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Share
                    ShareLink(
                        item: profile.npub,
                        subject: Text("My Nostr Identity"),
                        message: Text("Follow me on Nostr: \(profile.npub)")
                    ) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Identity")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(NostrKeepSignerTheme.bgLight)
                        .foregroundStyle(NostrKeepSignerTheme.text)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    // Add to Apple Wallet
                    AddToWalletButton()
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("Share \(profile.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    private func generateQRCode(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Profile History Sheet

struct ProfileHistorySheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack {
                if appState.activeSessions.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 48))
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)

                        Text("No Signing History")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(NostrKeepSignerTheme.text)

                        Text("When you authenticate with apps via NIP-46, your signing history will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(appState.activeSessions, id: \.id) { session in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(session.appName ?? "Unknown App")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundStyle(NostrKeepSignerTheme.text)

                                    Text(session.relayURL)
                                        .font(.system(.caption2, design: .monospaced))
                                        .foregroundStyle(NostrKeepSignerTheme.textMuted)

                                    Text(session.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                }

                                Spacer()

                                Circle()
                                    .fill(session.isActive ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.textMuted)
                                    .frame(width: 8, height: 8)
                            }
                            .listRowBackground(NostrKeepSignerTheme.bgLight)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("Signing History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Profile Manage Sheet

struct ProfileManageSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var editingName = ""
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let profile = appState.activeProfile {
                    List {
                        // Rename section
                        Section {
                            HStack {
                                Text("Name")
                                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                Spacer()
                                if isEditing {
                                    TextField("Profile name", text: $editingName)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundStyle(NostrKeepSignerTheme.text)
                                } else {
                                    Text(profile.name)
                                        .foregroundStyle(NostrKeepSignerTheme.text)
                                }
                            }
                            .listRowBackground(NostrKeepSignerTheme.bgLight)
                        } header: {
                            Text("Profile")
                        }

                        // Actions section
                        Section {
                            Button {
                                if isEditing {
                                    saveName()
                                } else {
                                    editingName = profile.name
                                    isEditing = true
                                }
                            } label: {
                                HStack {
                                    Image(systemName: isEditing ? "checkmark.circle" : "pencil")
                                        .foregroundStyle(NostrKeepSignerTheme.accent)
                                    Text(isEditing ? "Save Name" : "Rename Profile")
                                        .foregroundStyle(NostrKeepSignerTheme.accent)
                                }
                            }
                            .listRowBackground(NostrKeepSignerTheme.bgLight)

                            if isEditing {
                                Button {
                                    isEditing = false
                                } label: {
                                    HStack {
                                        Image(systemName: "xmark.circle")
                                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                        Text("Cancel Editing")
                                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                    }
                                }
                                .listRowBackground(NostrKeepSignerTheme.bgLight)
                            }
                        } header: {
                            Text("Actions")
                        }

                        // Danger zone
                        if appState.profiles.count > 1 {
                            Section {
                                Button(role: .destructive) {
                                    showDeleteConfirm = true
                                } label: {
                                    HStack {
                                        Image(systemName: "trash")
                                        Text("Delete Profile")
                                    }
                                    .foregroundStyle(NostrKeepSignerTheme.red)
                                }
                                .listRowBackground(NostrKeepSignerTheme.bgLight)
                            } header: {
                                Text("Danger Zone")
                            } footer: {
                                Text("This will permanently remove the profile and its private key from this device. This cannot be undone.")
                                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("Manage Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Delete Profile?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    deleteActiveProfile()
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently remove this profile and its private key from this device.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func saveName() {
        let trimmed = editingName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if let index = appState.profiles.firstIndex(where: { $0.id == appState.activeProfile?.id }) {
            appState.profiles[index].name = trimmed
            appState.activeProfile = appState.profiles[index]
            appState.saveProfiles()
        }
        isEditing = false
    }

    private func deleteActiveProfile() {
        guard let activeId = appState.activeProfile?.id else { return }
        appState.profiles.removeAll { $0.id == activeId }
        appState.activeProfile = appState.profiles.first
        if let first = appState.profiles.first {
            if let index = appState.profiles.firstIndex(where: { $0.id == first.id }) {
                appState.profiles[index].isActive = true
            }
        }
        appState.saveProfiles()

        if appState.profiles.isEmpty {
            appState.showOnboarding = true
        }
    }
}
