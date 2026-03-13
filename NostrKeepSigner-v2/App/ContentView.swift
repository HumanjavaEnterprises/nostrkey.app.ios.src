import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.showOnboarding {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var appState: AppState

    init() {
        // Theme the tab bar globally
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(NostrKeepSignerTheme.bgLight)

        // Normal state
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(NostrKeepSignerTheme.textMuted)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(NostrKeepSignerTheme.textMuted)
        ]

        // Selected state
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(NostrKeepSignerTheme.accent)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(NostrKeepSignerTheme.accent)
        ]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Theme the navigation bar globally
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(NostrKeepSignerTheme.bg)
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(NostrKeepSignerTheme.text)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(NostrKeepSignerTheme.text)
        ]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor(NostrKeepSignerTheme.accent)
    }

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(AppTab.home.rawValue, systemImage: AppTab.home.icon)
                }
                .tag(AppTab.home)

            ScannerView()
                .tabItem {
                    Label(AppTab.scanner.rawValue, systemImage: AppTab.scanner.icon)
                }
                .tag(AppTab.scanner)

            IdentityCardView()
                .tabItem {
                    Label(AppTab.identity.rawValue, systemImage: AppTab.identity.icon)
                }
                .tag(AppTab.identity)

            RelayListView()
                .tabItem {
                    Label(AppTab.relays.rawValue, systemImage: AppTab.relays.icon)
                }
                .tag(AppTab.relays)

            SettingsView()
                .tabItem {
                    Label(AppTab.settings.rawValue, systemImage: AppTab.settings.icon)
                }
                .tag(AppTab.settings)
        }
        .tint(NostrKeepSignerTheme.accent)
    }
}

// MARK: - Onboarding

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var isCreating = false
    @State private var showImport = false
    @State private var importNsec = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "key.fill")
                .font(.system(size: 72))
                .foregroundStyle(NostrKeepSignerTheme.accent)

            VStack(spacing: 8) {
                Text("NostrKeep Signer")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(NostrKeepSignerTheme.text)

                Text("Your identity. Your keys. Your rules.")
                    .font(.subheadline)
                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
            }

            Spacer()

            VStack(spacing: 16) {
                Button {
                    createIdentity()
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create New Identity")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(NostrKeepSignerTheme.accent)
                    .foregroundStyle(NostrKeepSignerTheme.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isCreating)

                Button {
                    showImport = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Import Existing Keys")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(NostrKeepSignerTheme.bgLight)
                    .foregroundStyle(NostrKeepSignerTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24)

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(NostrKeepSignerTheme.red)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
        .sheet(isPresented: $showImport) {
            ImportKeysView(nsec: $importNsec) {
                do {
                    try appState.importKeys(nsec: importNsec)
                    showImport = false
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func createIdentity() {
        isCreating = true
        errorMessage = nil
        Task {
            do {
                try await appState.createNewIdentity()
            } catch {
                errorMessage = error.localizedDescription
            }
            isCreating = false
        }
    }
}

// MARK: - Import Keys Sheet

struct ImportKeysView: View {
    @Binding var nsec: String
    @Environment(\.dismiss) var dismiss
    let onImport: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Paste your nsec (private key) below. It will be stored in the Secure Enclave on this device.")
                    .font(.subheadline)
                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                TextField("nsec1...", text: $nsec)
                    .font(.system(.body, design: .monospaced))
                    .padding()
                    .background(NostrKeepSignerTheme.bgLight)
                    .foregroundStyle(NostrKeepSignerTheme.text)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(NostrKeepSignerTheme.accent.opacity(0.3), lineWidth: 1)
                    }
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal)

                Button("Import") {
                    onImport()
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(nsec.isEmpty ? NostrKeepSignerTheme.bgLight : NostrKeepSignerTheme.accent)
                .foregroundStyle(nsec.isEmpty ? NostrKeepSignerTheme.textMuted : NostrKeepSignerTheme.bg)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal)
                .disabled(nsec.isEmpty)

                Spacer()
            }
            .padding(.top, 24)
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("Import Keys")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
