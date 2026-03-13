import SwiftUI
import PassKit

// TODO: Hide button when PKPassLibrary.isPassLibraryAvailable() is false (Simulator)
// TODO: Add haptic feedback on successful pass addition
// TODO: Show "View in Wallet" option after pass is already added

/// Reusable "Add to Apple Wallet" button that handles the full flow:
/// NIP-98 auth, pass download, and PKAddPassesViewController presentation.
struct AddToWalletButton: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var walletManager = WalletPassManager()
    @State private var showPassSheet = false
    @State private var showError = false

    var body: some View {
        Button {
            guard let profile = appState.activeProfile else { return }
            Task {
                await walletManager.requestPass(
                    npub: profile.npub,
                    displayName: profile.name,
                    keyManager: appState.keyManager,
                    pubkeyHex: profile.pubkeyHex
                )
            }
        } label: {
            HStack {
                if walletManager.state == .loading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "wallet.pass")
                }
                Text(buttonLabel)
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.black)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(walletManager.state == .loading)
        .onChange(of: walletManager.state) { _, newState in
            switch newState {
            case .success:
                showPassSheet = true
            case .error:
                showError = true
            default:
                break
            }
        }
        .sheet(isPresented: $showPassSheet) {
            if let pass = walletManager.pass {
                AddToWalletSheet(pass: pass) {
                    walletManager.reset()
                }
            }
        }
        .alert("Wallet Pass Error", isPresented: $showError) {
            Button("OK") {
                walletManager.reset()
            }
        } message: {
            if case .error(let msg) = walletManager.state {
                Text(msg)
            }
        }
    }

    private var buttonLabel: String {
        if walletManager.state == .loading {
            return "Downloading..."
        }
        if let profile = appState.activeProfile,
           walletManager.hasExistingPass(for: profile.npub) {
            return "Update Wallet Pass"
        }
        return "Add to Apple Wallet"
    }
}
