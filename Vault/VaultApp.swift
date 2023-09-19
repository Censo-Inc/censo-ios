//
//  VaultApp.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Moya
import raygun4apple

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
                    .onAppear(perform: handlePushRegistration)
            }
            #else
            ContentView()
                .onAppear(perform: handlePushRegistration)
            #endif
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
