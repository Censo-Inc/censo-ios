//
//  ContentView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Moya
import CryptoKit

struct ContentView: View {
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var pendingImport: Import?
    @Environment(\.apiProvider) var apiProvider
    @ObservedObject var deeplinkState = DeeplinkState.shared

    var body: some View {
        Authentication(
            loggedOutContent: { onSuccess in
                Login(onSuccess: onSuccess)
            },
            loggedInContent: { session in
                CloudCheck {
                    AppAttest(session: session) {
                        if let url = deeplinkState.url {
                            ProgressView()
                                .onAppear {
                                    openURL(url)
                                    deeplinkState.reset()
                                }
                        } else {
                            LoggedInOwnerView(pendingImport: $pendingImport, session: session)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name.maintenanceStatusCheckNotification)) { _ in
                    apiProvider.request(with: session, endpoint: .health) { _ in }
                }
            }
        )
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {
                deeplinkState.reset()
            })
        } message: { error in
            Text(error.localizedDescription)
        }
        
    }


    private func base64urlToBase64(base64url: String) -> String {
        var base64 = base64url
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        if base64.count % 4 != 0 {
            base64.append(String(repeating: "=", count: 4 - base64.count % 4))
        }
        return base64
    }
    
    private func openURL(_ url: URL) {
        guard let scheme = url.scheme,
              scheme.starts(with: "censo-main"),
              url.pathComponents.count == 6,
              let action = url.host,
              action == "import",
              let version = url.pathComponents[1] as String?,
              ["v1"].contains(version) else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }
        guard let importKey = try? Base58EncodedPublicKey(value: url.pathComponents[2]),
              let timestamp = Int64(url.pathComponents[3]),
              let signature = try? Base64EncodedString(value: base64urlToBase64(base64url: url.pathComponents[4])),
              let nameBase64 = try? Base64EncodedString(value: base64urlToBase64(base64url: url.pathComponents[5])),
              let name = String(data: nameBase64.data, encoding: .utf8) else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }

        // if signature is in raw uncompressed form, convert to DER
        var derSignature: Data
        if (signature.data.count > 64) {
            derSignature = signature.data
        } else {
            func makePositive(_ input: Data) -> Data {
                if (input[0] > 0x7f) {
                    return Data([0x00] + input)
                } else {
                    return input
                }
            }
            let r = makePositive(signature.data.subdata(in: 0..<32))
            let s = makePositive(signature.data.subdata(in: 32..<64))
            derSignature = Data([0x30, UInt8(r.count + s.count + 4), 0x02, UInt8(r.count)] + r + [0x02, UInt8(s.count)] + s)
        }

        var signedData = Data(String(timestamp).utf8)
        signedData.append(Data(SHA256.hash(data: name.data(using: .utf8)!)))

        guard let verified = try? EncryptionKey.generateFromPublicExternalRepresentation(
                base58PublicKey: importKey).verifySignature(
            for: signedData,
            signature: Base64EncodedString(value: derSignature.base64EncodedString())) else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }
        if (verified) {
            let linkCreationTime = Date(timeIntervalSince1970: (Double(timestamp) / 1000))
            // allow a link which is from up to 10 seconds in the future,
            // to account for clock drift wherever the SDK is running
            let linkValidityStart = linkCreationTime.addingTimeInterval(-10)
            // link should be valid for 10 minutes
            let linkValidityEnd = linkCreationTime.addingTimeInterval(60 * 10)
            let now = Date()
            if (now > linkValidityEnd) {
                showError(CensoError.linkExpired)
            } else if (now < linkValidityStart) {
                showError(CensoError.linkInFuture)
            } else {
                pendingImport = Import(importKey: importKey, timestamp: timestamp, signature: signature, name: name)
            }
        } else {
            showError(CensoError.invalidUrl(url: "\(url)"))
        }
    }
    
    private func showError(_ error: Error) {
        self.currentError = error
        self.showingError = true
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

extension CommandLine {
    static var isTesting: Bool = {
        arguments.contains("testing")
    }()
}
#endif
