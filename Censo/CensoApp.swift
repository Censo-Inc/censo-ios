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
            // Windows are provided by the SceneDelegate
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
        appearance.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 242/255, alpha: 1)
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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var contentWindow: UIWindow?
  var maintenanceWindow: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    if let windowScene = scene as? UIWindowScene {
      setupContentWindow(in: windowScene)
      setupMaintenanceWindow(in: windowScene)
    }
  }
    
//    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
//        if userActivity.activityType == NSUserActivityTypeBrowsingWeb  {
//            debugPrint("//doSomethingWith(url: userActivity.webpageURL)")
//            //doSomethingWith(url: userActivity.webpageURL)
//        }
//    }

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
