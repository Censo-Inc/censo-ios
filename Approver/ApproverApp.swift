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
        
        UNUserNotificationCenter.current().delegate = self

        setupAppearance()

        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        debugPrint("didRegisterForRemoteNotificationsWithDeviceToken: \(deviceToken.toHexString())")
        if let userCredentials = Keychain.userCredentials, let deviceKey = SecureEnclaveWrapper.deviceKey(userIdentifier: userCredentials.userIdentifier) {
            provider.request(API(deviceKey: deviceKey, endpoint: .registerPushToken(deviceToken.toHexString()))) { result in
                switch result {
                case .failure(let error):
                    debugPrint("Error submitting push token: \(error.localizedDescription)")
                case .success(let response) where response.statusCode >= 400:
                    debugPrint("Could not submit push token: \(String(data: response.data, encoding: .utf8) ?? "")")
                case .success:
                    break
                }
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint("Failed to register for remote notifications: \(error.localizedDescription)")
        RaygunClient.sharedInstance(apiKey: Configuration.raygunApiKey).send(error: error, tags: ["push-registration"], customData: nil)
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

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])

        NotificationCenter.default.post(name: .userDidReceiveRemoteNotification, object: notification)
    }
}

extension Notification.Name {
    static let userDidReceiveRemoteNotification = Notification.Name("userDidReceiveRemoteNotification")
}