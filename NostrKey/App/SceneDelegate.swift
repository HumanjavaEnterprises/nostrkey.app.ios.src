import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()
        window.backgroundColor = UIColor(red: 0x27/255.0, green: 0x28/255.0, blue: 0x22/255.0, alpha: 1)
        self.window = window
        window.makeKeyAndVisible()
    }
}
