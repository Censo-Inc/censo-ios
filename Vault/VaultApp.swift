//
//  VaultApp.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

@main
struct VaultApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if appDelegate.testing {
                ContentView()
            } else {
                ContentView()
                    .lockedByBiometry {
                        Locked()
                    }
            }
            #else
            ContentView()
                .lockedByBiometry {
                    Locked()
                }
            #endif
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    #if DEBUG
    var testing: Bool = false
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        #if DEBUG
        if CommandLine.arguments.contains("testing") {
            self.testing = true
        }
        #endif

        setupAppearance()

        return true
    }

    func setupAppearance() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.Censo.blue)

        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(red: 26.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(red: 26.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1)]
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(red: 26.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1)]
        appearance.buttonAppearance = buttonAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        UINavigationBar.appearance().tintColor = UIColor(red: 26.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1)
        UINavigationBar.appearance().barTintColor = UIColor(red: 26.0/255.0, green: 25.0/255.0, blue: 25.0/255.0, alpha: 1)
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
