//
//  Maintenance.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import SwiftUI

class MaintenanceState: ObservableObject {
    static let shared = MaintenanceState()
    @Published var isOn: Bool = false {
        didSet {
            if oldValue != isOn {
                maintenanceModeChange = (oldValue, isOn)
            }
        }
    }
    @Published var maintenanceModeChange: (oldValue: Bool, newValue: Bool) = (false, false)
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var contentWindow: UIWindow?
    var maintenanceWindow: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            setupContentWindow(in: windowScene)
            setupMaintenanceWindow(in: windowScene)
        }
        
        // handle the deep link if the app is launched by a deep link
        if let urlContext = connectionOptions.urlContexts.first {
            DeeplinkState.shared.url = urlContext.url
        }
    }
    
    // handle the deep link if app was already launched
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            DeeplinkState.shared.url = url
        }
    }
    
    func setupContentWindow(in scene: UIWindowScene) {
        let window = UIWindow(windowScene: scene)
        let contentView: some View = ContentView().foregroundColor(Color.Censo.primaryForeground)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.contentWindow = window
        window.makeKeyAndVisible()
    }
    
    func setupMaintenanceWindow(in scene: UIWindowScene) {
        let maintenanceWindow = PassThroughWindow(windowScene: scene)
        let maintenanceView: some View = MaintenanceView().foregroundColor(Color.Censo.primaryForeground)
        let maintenanceController = UIHostingController(rootView: maintenanceView)
        // transparent background to make content window visible
        maintenanceController.view.backgroundColor = .clear
        maintenanceWindow.rootViewController = maintenanceController
        // only one key window is allowed, therefore just making visible
        maintenanceWindow.isHidden = false
        self.maintenanceWindow = maintenanceWindow
    }
}

class PassThroughWindow: UIWindow {
    // If no SwiftUI view responds to the user touch, then the containing UIHostingController's (UI)view will.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hitView = super.hitTest(point, with: event) else { return nil }
        // If the returned view is the `UIHostingController`'s view, ignore. Click will be handled by windown below.
        return rootViewController?.view == hitView ? nil : hitView
    }
}
