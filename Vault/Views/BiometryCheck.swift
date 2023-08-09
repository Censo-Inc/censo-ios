//
//  BiometryCheck.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import LocalAuthentication

struct BiometryCheck<V>: ViewModifier where V : View {
    @State private var biometryEnabled = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

    @AppStorage("permissionAsked") private var permissionAsked = false

    private let appForegroundedPublisher = NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)

    var lockedView: () -> V

    func body(content: Content) -> some View {
        ZStack {
            content

            if !biometryEnabled {
                ZStack {
                    Color.Censo.primaryBackground.ignoresSafeArea()

                    lockedView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .onReceive(appForegroundedPublisher) { _ in
            biometryEnabled = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        }
        .onAppear {
            DispatchQueue.main.async {
                if !permissionAsked {
                    LAContext().evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Identify Yourself") { granted, error in
                        DispatchQueue.main.async {
                            permissionAsked = error != nil
                            biometryEnabled = granted
                        }
                    }
                }
            }
        }
    }
}

extension View {
    func lockedByBiometry<V>(@ViewBuilder lockedView: @escaping () -> V) -> some View where V : View {
        modifier(BiometryCheck(lockedView: lockedView))
    }
}

struct Locked: View {
    var biometryType: String {
        switch LAContext().biometryType {
        case .faceID:
            return "Face ID"
        default:
            return "Touch ID"
        }
    }

    var biometryIcon: Image {
        switch LAContext().biometryType {
        case .faceID:
            return Image(systemName: "faceid")
        default:
            return Image(systemName: "touchid")
        }
    }

    var body: some View {
        VStack {
            Spacer()
            Spacer()

            Image("LogoColor")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxHeight: 44)
                .padding(20)

            biometryIcon
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 50, height: 50)
                .foregroundColor(.Censo.red)
                .padding()

            Text("Biometry Required")
                .font(.title2)
                .padding()

            Spacer()

            if LAContext().biometryType == .none {
                Text("We're sorry")
                    .font(.title)

                Text("The Censo Mobile App requires biometric authentication for security purposes and your device does not support biometric authentication")
                    .padding()
            } else {
                Text("The Censo Mobile App requires \(biometryType) to be enabled for security purposes.")
                    .padding()

                Button {
                    goToAppSettings()
                } label: {
                    Text("Enable in Settings")
                        .frame(maxWidth: .infinity)
                }
                .padding(30)
                .buttonStyle(FilledButtonStyle())
            }

            Spacer()
        }
        .multilineTextAlignment(.center)
    }

    func goToAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }
}

#if DEBUG
struct Locked_Previews: PreviewProvider {
    static var previews: some View {
        Locked()
            .preferredColorScheme(.light)
    }
}
#endif
