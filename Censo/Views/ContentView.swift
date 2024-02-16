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
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.scenePhase) private var scenePhase
    @State private var url: URL?
    @State private var showingError = false
    @State private var currentError: Error?
    @State private var pendingImport: Import?
    @State private var beneficiaryInvitationId: BeneficiaryInvitationId?

    @State private var showLoginIdResetFlow: Bool = false
    @State private var showBeneficiaryLoggedOutWelcome: Bool = false
    @StateObject private var loginIdResetTokensStore = LoginIdResetTokensStore()
    
    var body: some View {
        Group {
            if showLoginIdResetFlow {
                LoginIdReset(
                    tokens: $loginIdResetTokensStore.tokens,
                    onComplete: {
                        loginIdResetTokensStore.clear()
                        showLoginIdResetFlow = false
                    }
                )
            } else {
                Authentication(
                    loggedOutContent: { onSuccess in
                        if showBeneficiaryLoggedOutWelcome {
                            BeneficiaryLoggedOutWelcome {
                                showBeneficiaryLoggedOutWelcome = false
                            }
                        } else {
                            Login(
                                onShowLoginIdResetFlow: {
                                    showLoginIdResetFlow = true
                                },
                                onSuccess: onSuccess
                            )
                            .onOpenURL(perform: {
                                if $0.host != "reset" {
                                    self.url = $0
                                }
                            })
                        }
                    },
                    loggedInContent: { session in
                        if let url {
                            ProgressView()
                                .onAppear {
                                    self.url = nil
                                    openURL(url)
                                }
                        } else {
                            LoggedInOwnerView(
                                session: session,
                                pendingImport: $pendingImport,
                                beneficiaryInvitationId: $beneficiaryInvitationId
                            )
                            .onOpenURL(perform: openURL)
                        }
                    }
                )
            }
        }
        .onAppear {
            do {
                try loginIdResetTokensStore.load()
                if loginIdResetTokensStore.tokens.count > 0 {
                    showLoginIdResetFlow = true
                }
            } catch {
                showError(error)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .inactive {
                do {
                    try loginIdResetTokensStore.save()
                } catch {
                    showError(error)
                }
            }
        }
        .onOpenURL(perform: {
            if $0.host == "beneficiary" {
                self.showBeneficiaryLoggedOutWelcome = true
            }
        })
        .errorAlert(isPresented: $showingError, presenting: currentError)
    }

    private func openURL(_ url: URL) {
        do {
            if url.host == "import" {
                pendingImport = try Import.fromURL(url)
            } else if url.host == "beneficiary" {
                beneficiaryInvitationId = try BeneficiaryInvitationId.fromURL(url)
            } else {
                throw CensoError.invalidUrl(url: "\(url)")
            }
        } catch {
            showError(error)
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
            .foregroundColor(.Censo.primaryForeground)
    }
}

extension CommandLine {
    static var isTesting: Bool = {
        arguments.contains("testing")
    }()
}
#endif
