//
//  ApproverApp.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya
import raygun4apple

@main
struct ApproverApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}


class AppDelegate: NSObject, UIApplicationDelegate {
    #if DEBUG
    var testing: Bool = false
    #endif
    
    var provider: MoyaProvider<API> = MoyaProvider(plugins: [AuthPlugin()])

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        #if DEBUG
        if CommandLine.arguments.contains("testing") {
            self.testing = true
        }
        #endif

        let raygunClient = RaygunClient.sharedInstance(apiKey: Configuration.raygunApiKey)
        raygunClient.applicationVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        if Configuration.raygunEnabled {
            raygunClient.enableCrashReporting()
        }
        
        setupAppearance()

        return true
    }
    
    func setupAppearance() {
        UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(Color.Censo.blue)

        UITableView.appearance().backgroundColor = .clear
        UITableViewCell.appearance().backgroundColor = .clear

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        let buttonAppearance = UIBarButtonItemAppearance()
        buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.buttonAppearance = buttonAppearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().barTintColor = UIColor.white
    }
}
