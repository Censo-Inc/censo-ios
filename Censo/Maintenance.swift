//
//  Maintenance.swift
//  Censo
//
//  Created by imykolenko on 1/8/24.
//

import SwiftUI
import Moya

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
    
    var maintenanceWindow: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Configure and attach maintenance window to the provided UIWindowScene 'scene'.
        if let windowScene = scene as? UIWindowScene {
            setupMaintenanceWindow(in: windowScene)
        }
    }
    
    private func setupMaintenanceWindow(in scene: UIWindowScene) {
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

struct MaintenanceStatusCheck<Content>: View where Content : View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        content()
            .onReceive(NotificationCenter.default.publisher(for: Notification.Name.maintenanceStatusCheckNotification)) { _ in
                apiProvider.request(with: session, endpoint: .health) { _ in }
            }
    }
}
