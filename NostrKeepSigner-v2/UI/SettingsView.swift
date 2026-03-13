import SwiftUI

/// App settings and key management
struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showExportWarning = false
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            List {
                // Active Profile
                if let profile = appState.activeProfile {
                    Section("Active Identity") {
                        HStack {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundStyle(NostrKeepSignerTheme.accent)
                            VStack(alignment: .leading) {
                                Text(profile.name)
                                    .fontWeight(.medium)
                                    .foregroundStyle(NostrKeepSignerTheme.text)
                                Text(profile.displayNpub)
                                    .font(.caption)
                                    .foregroundStyle(NostrKeepSignerTheme.textMuted)
                            }
                        }
                        .listRowBackground(NostrKeepSignerTheme.bgLight)
                    }
                }

                // Security
                Section("Security") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(NostrKeepSignerTheme.accent)
                        Text("Secure Enclave")
                            .foregroundStyle(NostrKeepSignerTheme.text)
                        Spacer()
                        Text(appState.activeProfile?.isSecureEnclave == true ? "Active" : "Inactive")
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)

                    HStack {
                        Image(systemName: "faceid")
                            .foregroundStyle(NostrKeepSignerTheme.cyan)
                        Text("Biometric Authentication")
                            .foregroundStyle(NostrKeepSignerTheme.text)
                        Spacer()
                        Text("Required for signing")
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)
                }

                // Connected Sessions
                Section("NIP-46 Sessions") {
                    if appState.activeSessions.isEmpty {
                        Text("No active sessions")
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                            .listRowBackground(NostrKeepSignerTheme.bgLight)
                    } else {
                        ForEach(appState.activeSessions) { session in
                            HStack {
                                Circle()
                                    .fill(session.isActive ? NostrKeepSignerTheme.accent : NostrKeepSignerTheme.textMuted)
                                    .frame(width: 8, height: 8)
                                VStack(alignment: .leading) {
                                    Text(session.appName ?? "Unknown App")
                                        .fontWeight(.medium)
                                        .foregroundStyle(NostrKeepSignerTheme.text)
                                    Text(session.relayURL)
                                        .font(.caption)
                                        .foregroundStyle(NostrKeepSignerTheme.textMuted)
                                }
                            }
                            .listRowBackground(NostrKeepSignerTheme.bgLight)
                        }
                    }
                }

                // Key Management
                Section("Key Management") {
                    Button {
                        showExportWarning = true
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export Keys (nsec)")
                        }
                        .foregroundStyle(NostrKeepSignerTheme.orange)
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)

                    NavigationLink {
                        ProfileListView()
                    } label: {
                        HStack {
                            Image(systemName: "person.2")
                            Text("Manage Profiles")
                                .foregroundStyle(NostrKeepSignerTheme.text)
                        }
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)
                }

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                            .foregroundStyle(NostrKeepSignerTheme.text)
                        Spacer()
                        Text("2.0.0 (1)")
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)

                    Link(destination: URL(string: "https://nostrkeep.com")!) {
                        HStack {
                            Text("Website")
                                .foregroundStyle(NostrKeepSignerTheme.text)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        }
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)

                    Link(destination: URL(string: "https://github.com/HumanjavaEnterprises/nostrkeep-signer-ios")!) {
                        HStack {
                            Text("Source Code")
                                .foregroundStyle(NostrKeepSignerTheme.text)
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundStyle(NostrKeepSignerTheme.textMuted)
                        }
                    }
                    .listRowBackground(NostrKeepSignerTheme.bgLight)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
            .navigationTitle("Settings")
            .alert("Export Warning", isPresented: $showExportWarning) {
                Button("Cancel", role: .cancel) { }
                Button("Export", role: .destructive) {
                    // TODO: Export keys with biometric confirmation
                }
            } message: {
                Text("Exporting your nsec (private key) allows anyone who has it to control your Nostr identity. Only export if you need to back up or move your key. Never share it.")
            }
        }
    }
}

// MARK: - Profile List

struct ProfileListView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        List {
            ForEach(appState.profiles) { profile in
                HStack {
                    VStack(alignment: .leading) {
                        Text(profile.name)
                            .fontWeight(.medium)
                            .foregroundStyle(NostrKeepSignerTheme.text)
                        Text(profile.displayNpub)
                            .font(.caption)
                            .foregroundStyle(NostrKeepSignerTheme.textMuted)
                    }

                    Spacer()

                    if profile.isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(NostrKeepSignerTheme.accent)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    setActiveProfile(profile)
                }
                .listRowBackground(NostrKeepSignerTheme.bgLight)
            }
        }
        .scrollContentBackground(.hidden)
        .background(NostrKeepSignerTheme.bg.ignoresSafeArea())
        .navigationTitle("Profiles")
    }

    private func setActiveProfile(_ profile: NostrProfile) {
        for i in appState.profiles.indices {
            appState.profiles[i].isActive = (appState.profiles[i].id == profile.id)
        }
        appState.activeProfile = profile
        appState.saveProfiles()
    }
}
