//
//  LoginIdReset.swift
//  Censo
//
//  Created by Anton Onyshchenko on 08.01.24.
//

import SwiftUI
import Moya

class LoginIdResetTokensStore: ObservableObject {
    @Published var tokens: Set<LoginIdResetToken> = []
    
    private let keychainService = "co.censo.LoginIdResetTokensStore"
    
    func load() throws {
        if let data = try Keychain.load(account: keychainService, service: keychainService) {
            self.tokens = Set(try JSONDecoder().decode([LoginIdResetToken].self, from: data))
        } else {
            self.tokens = []
        }
    }
    
    func save() throws {
        let data = try JSONEncoder().encode(Array(tokens))
        try Keychain.save(account: keychainService, service: keychainService, data: data)
    }
    
    func clear() {
        tokens.removeAll()
        Keychain.clear(account: keychainService, service: keychainService)
    }
}

struct LoginIdReset: View {
    var tokens: Binding<Set<LoginIdResetToken>>
    var onComplete: () -> Void
    
    @State private var step: Step = .collectingTokens
    
    enum Step {
        case collectingTokens
        case signIn
        case startVerification
        case chooseVerificationMethod
        case resetWithBiometry
        case resetWithPassword
    }
    
    var body: some View {
        Authentication(
            loggedOutContent: { onLoginSuccess in
                LoginIdResetLoggedOutSteps(
                    step: $step,
                    tokens: tokens,
                    onLoginSuccess: onLoginSuccess,
                    onCancel: onComplete
                )
            },
            loggedInContent: { session in
                LoginIdResetLoggedInSteps(
                    session: session,
                    step: $step,
                    tokens: tokens,
                    onComplete: onComplete
                )
            }
        )
    }
}

struct LoginIdResetLoggedOutSteps: View {
    @Binding var step: LoginIdReset.Step
    @Binding var tokens: Set<LoginIdResetToken>
    var onLoginSuccess: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                WithResetLoginIdHeader {
                    LoginIdResetCollectTokensStep(
                        enabled: step == .collectingTokens,
                        tokens: $tokens
                    )
                    .onChange(of: tokens) { newValue in
                        if step == .collectingTokens && newValue.count == resetTokensThreshold {
                            step = .signIn
                        }
                    }
                    
                    LoginIdResetSignInStep(
                        enabled: step == .signIn,
                        onSuccess: {
                            self.step = .startVerification
                            onLoginSuccess()
                        }
                    )
                    
                    LoginIdResetStartVerificationStep(
                        enabled: false,
                        session: nil,
                        tokens: $tokens,
                        onDeviceCreated: { }
                    )
                    
                    LoginIdResetInitKeyRecoveryStep(
                        enabled: false,
                        session: nil,
                        onButtonPressed: { }
                    )
                }
            }
            .onAppear {
                if tokens.count == resetTokensThreshold {
                    self.step = .signIn
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbarBackground(Color.Censo.primaryBackground, for: .navigationBar)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        }
    }
}

struct LoginIdResetLoggedInSteps: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    @Binding var step: LoginIdReset.Step
    @Binding var tokens: Set<LoginIdResetToken>
    var onComplete: () -> Void
    
    var body: some View {
        NavigationView {
            switch (step) {
            case .collectingTokens, .signIn, .startVerification:
                ScrollView {
                    WithResetLoginIdHeader {
                        LoginIdResetCollectTokensStep(
                            enabled: false,
                            tokens: $tokens
                        )
                        
                        LoginIdResetSignInStep(
                            enabled: false,
                            onSuccess: {}
                        )
                        
                        LoginIdResetStartVerificationStep(
                            enabled: step == .startVerification,
                            session: session,
                            tokens: $tokens,
                            onDeviceCreated: {
                                self.step = .chooseVerificationMethod
                            }
                        )
                        
                        // This button is enabled in OwnerKeyRecovery screen
                        // where we have ownerState and can start the key recovery process.
                        // LoggedInOwnerView detects that owner's approver key is missing
                        // and renders the OwnerKeyRecovery from which user can't exit
                        LoginIdResetInitKeyRecoveryStep(
                            enabled: false,
                            session: session,
                            onButtonPressed: { }
                        )
                    }
                    .onAppear {
                        if tokens.count == resetTokensThreshold {
                            self.step = .startVerification
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbarBackground(Color.Censo.primaryBackground, for: .navigationBar)
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                Keychain.removeUserCredentials()
                                onComplete()
                            } label: {
                                Image(systemName: "xmark")
                            }
                        }
                    })
                }
            case .chooseVerificationMethod:
                WithResetLoginIdHeader {
                    SelectIdentityVerificationMethod(step: $step)
                }
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden(true)
                .toolbarBackground(Color.Censo.primaryBackground, for: .navigationBar)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            step = .startVerification
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                })
            case .resetWithBiometry:
                FacetecAuth<API.ResetLoginIdApiResponse>(
                    session: session,
                    onReadyToUploadResults: { biometryData in
                        return .resetLoginId(API.ResetLoginIdApiRequest(
                            identityToken: session.userCredentials.userIdentifier,
                            resetTokens: Array(tokens),
                            biometryVerificationId: biometryData.verificationId,
                            biometryData: biometryData
                        ))
                    },
                    onSuccess: { _ in
                        onComplete()
                    },
                    onCancelled: {
                        step = .chooseVerificationMethod
                    }
                )
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            step = .startVerification
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                    }
                })
            case .resetWithPassword:
                ScrollView {
                    WithResetLoginIdHeader {
                        PasswordAuth<API.ResetLoginIdWithPasswordApiResponse>(
                            session: session,
                            submitTo: { password in
                                return .resetLoginIdWithPassword(
                                    API.ResetLoginIdWithPasswordApiRequest(
                                        identityToken: session.userCredentials.userIdentifier,
                                        resetTokens: Array(tokens),
                                        password: password
                                    )
                                )
                            },
                            onSuccess: { _ in
                                onComplete()
                            }
                        )
                    }
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbarBackground(Color.Censo.primaryBackground, for: .navigationBar)
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                step = .chooseVerificationMethod
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                        }
                    })
                }
            }
        }
    }
}

struct WithResetLoginIdHeader<Content: View>: View {
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Reset Login ID")
                .fixedSize(horizontal: false, vertical: true)
                .font(.title)
                .fontWeight(.semibold)
                .padding(.bottom, 32)
            
            VStack(spacing: 0) {
                content()
            }
        }
        .padding()
    }
}

private struct SelectIdentityVerificationMethod: View {
    @Binding var step: LoginIdReset.Step
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Please select your identity verification method:")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.bottom)
            
            VStack {
                Button(action: {
                    step = .resetWithBiometry
                }, label: {
                    Text("Biometric")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
                
                Button(action: {
                    step = .resetWithPassword
                }, label: {
                    Text("Password")
                        .font(.title3)
                        .frame(maxWidth: .infinity)
                })
                .buttonStyle(RoundedButtonStyle())
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding(.top)
    }
}

private let resetTokensThreshold = 2

#if DEBUG
#Preview {
    LoginIdReset(
        tokens: Binding.constant([]),
        onComplete: {}
    )
    .foregroundColor(.Censo.primaryForeground)
}

#Preview {
    NavigationView {
        WithResetLoginIdHeader {
            SelectIdentityVerificationMethod(
                step: Binding.constant(.chooseVerificationMethod)
            )
        }
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
