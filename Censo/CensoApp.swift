//
//  CensoApp.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Sentry

import Moya

@main
struct CensoApp: App {
    @UIApplicationDelegateAdaptor private var appDelegate: AppDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .foregroundColor(Color.Censo.primaryForeground)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    #if DEBUG
    var testing: Bool = false
    #endif
    
    var provider: MoyaProvider<API> = MoyaProvider(plugins: [AuthPlugin()])

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

        #if DEBUG
        if CommandLine.arguments.contains("testing") {
            self.testing = true
            if CommandLine.arguments.count >= 3 {
                UIPasteboard.general.string = CommandLine.arguments[2]
            }
            UIApplication.shared.keyWindow?.layer.speed = 0

            Keychain.userCredentials = .init(idToken: "testIdToken".data(using: .utf8)!, userIdentifier: CommandLine.arguments.last!)
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
        }
        #endif
        
        if Configuration.sentryEnabled {
            SentrySDK.start { options in
                options.dsn = Configuration.sentryDsn
                options.environment = Configuration.sentryEnvironment
            }
        }
        
        UNUserNotificationCenter.current().delegate = self

        setupAppearance()
        
        handlePushRegistration()

        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // connect SceneDelegate to configure scene with the maintenance window
        let sceneConfig: UISceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
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
    private func handlePushRegistration() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                if settings.authorizationStatus == .authorized {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint("Failed to register for remote notifications: \(error.localizedDescription)")
        SentrySDK.captureWithTag(error: error, tagValue: "push-registration")
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

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])

        NotificationCenter.default.post(name: .userDidReceiveRemoteNotification, object: notification)
    }
}

extension Notification.Name {
    static let userDidReceiveRemoteNotification = Notification.Name("userDidReceiveRemoteNotification")
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
