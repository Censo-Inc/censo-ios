//
//  ContentView.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI
import Moya

struct ContentView: View {
    @State private var url: URL?
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var pendingImport: Import?
    var body: some View {
        Authentication(
            loggedOutContent: { onSuccess in
                Login(onSuccess: onSuccess)
                    .onOpenURL(perform: { self.url = $0 })
            },
            loggedInContent: { session in
                CloudCheck {
                    AppAttest(session: session) {
                        if let url {
                            ProgressView()
                                .onAppear {
                                    self.url = nil
                                    openURL(url)
                                }
                        } else {
                            LoggedInOwnerView(pendingImport: $pendingImport, session: session)
                                .onOpenURL(perform: openURL)
                        }
                    }
                }
            }
        )
        .alert("Error", isPresented: $showingError, presenting: currentError) { _ in
            Button("OK", role: .cancel, action: {
                self.url = nil
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
              scheme.starts(with: "censo-import"),
              url.pathComponents.count == 5,
              let version = url.host,
              ["v1"].contains(version) else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }
        guard let importKey = try? Base58EncodedPublicKey(value: url.pathComponents[1]),
              let timestamp = Int64(url.pathComponents[2]),
              let signature = try? Base64EncodedString(value: base64urlToBase64(base64url: url.pathComponents[3])),
              let nameBase64 = try? Base64EncodedString(value: base64urlToBase64(base64url: url.pathComponents[4])),
              let name = String(data: nameBase64.data, encoding: .utf8) else {
            showError(CensoError.invalidUrl(url: "\(url)"))
            return
        }
        // TODO - verify signature and timestamp

        pendingImport = Import(importKey: importKey, timestamp: timestamp, signature: signature, name: name)
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
