import SwiftUI
import PassKit

/// UIKit wrapper for PKAddPassesViewController.
/// Presents the standard Apple "Add Pass" sheet with pass preview.
struct AddToWalletSheet: UIViewControllerRepresentable {
    let pass: PKPass
    var onDismiss: () -> Void = {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIViewController(context: Context) -> PKAddPassesViewController {
        let controller = PKAddPassesViewController(pass: pass)!
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: PKAddPassesViewController, context: Context) {}

    class Coordinator: NSObject, PKAddPassesViewControllerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
            controller.dismiss(animated: true) { [weak self] in
                self?.onDismiss()
            }
        }
    }
}
