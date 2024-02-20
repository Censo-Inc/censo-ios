//
//  ApproverApp.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya
import Sentry

@main
struct ApproverApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .foregroundColor(Color.Censo.primaryForeground)
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
        
        if Configuration.sentryEnabled {
            SentrySDK.start { options in
                options.dsn = Configuration.sentryDsn
                options.environment = Configuration.sentryEnvironment
            }
        }
        
        setupAppearance()

        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // connect SceneDelegate to configure scene with the maintenance window
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }

    func setupAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.Censo.primaryForeground]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.Censo.primaryForeground]
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = buttonAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
