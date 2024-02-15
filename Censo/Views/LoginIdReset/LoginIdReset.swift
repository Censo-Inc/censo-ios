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
    @Environment(\.apiProvider) var apiProvider
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
                VStack(spacing: 0) {
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
                        ownerRepository: nil,
                        tokens: $tokens,
                        onDeviceCreated: { }
                    )
                    
                    LoginIdResetInitKeyRecoveryStep(
                        enabled: false,
                        loggedIn: false,
                        onButtonPressed: { }
                    )
                }
                .padding(.top)
                .padding(.horizontal)
            }
            .onAppear {
                if tokens.count == resetTokensThreshold {
                    self.step = .signIn
                }
            }
            .navigationInlineTitle("Reset Login ID")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    DismissButton(icon: .close, action: onCancel)
                }
            }
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
        // We wrap internal view here to inject MoyaProvider from the environment into its initializer
        // This has to do with AppAttest sitting between ContentView and this view
        // and replacing the MoyaProvider in the environment with one that knows about attestation
        InternalView(
            apiProvider: apiProvider,
            session: session,
            step: $step,
            tokens: $tokens,
            onComplete: onComplete
        )
    }
    
    private struct InternalView: View {
        @Binding var step: LoginIdReset.Step
        @Binding var tokens: Set<LoginIdResetToken>
        var onComplete: () -> Void
        
        @StateObject private var ownerRepository: OwnerRepository
        
        init(apiProvider: MoyaProvider<API>, session: Session, step: Binding<LoginIdReset.Step>, tokens: Binding<Set<LoginIdResetToken>>, onComplete: @escaping () -> Void) {
            self._step = step
            self._tokens = tokens
            self.onComplete = onComplete
            self._ownerRepository = StateObject(wrappedValue: OwnerRepository(apiProvider, session))
        }
        
        var body: some View {
            NavigationView {
                switch (step) {
                case .collectingTokens, .signIn, .startVerification:
                    ScrollView {
                        VStack(spacing: 0) {
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
                                ownerRepository: ownerRepository,
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
                                loggedIn: true,
                                onButtonPressed: { }
                            )
                        }
                        .onAppear {
                            if tokens.count == resetTokensThreshold {
                                self.step = .startVerification
                            }
                        }
                        .padding(.top)
                        .padding(.horizontal)
                    }
                    .navigationInlineTitle("Reset Login ID")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            DismissButton(icon: .close, action: {
                                Keychain.removeUserCredentials()
                                onComplete()
                            })
                        }
                    }
                case .chooseVerificationMethod:
                    SelectIdentityVerificationMethod(step: $step)
                        .navigationInlineTitle("Reset Login ID")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                DismissButton(icon: .back, action: {
                                    step = .startVerification
                                })
                            }
                        }
                case .resetWithBiometry:
                    FacetecAuth<API.ResetLoginIdApiResponse>(
                        onFaceScanReady: { biometryData, completion in
                            ownerRepository.resetLoginId(API.ResetLoginIdApiRequest(
                                identityToken: ownerRepository.userIdentifier,
                                resetTokens: Array(tokens),
                                biometryVerificationId: biometryData.verificationId,
                                biometryData: biometryData
                            ), completion)
                        },
                        onSuccess: { _ in
                            onComplete()
                        },
                        onCancelled: {
                            step = .chooseVerificationMethod
                        }
                    )
                case .resetWithPassword:
                    ScrollView {
                        PasswordAuth<API.ResetLoginIdWithPasswordApiResponse>(
                            submit: { password, completion in
                                ownerRepository.resetLoginIdWithPassword(
                                    API.ResetLoginIdWithPasswordApiRequest(
                                        identityToken: ownerRepository.userIdentifier,
                                        resetTokens: Array(tokens),
                                        password: password
                                    ),
                                    completion
                                )
                            },
                            onSuccess: { _ in
                                onComplete()
                            }
                        )
                        .padding(.horizontal)
                    }
                    .navigationInlineTitle("Reset Login ID")
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            DismissButton(icon: .back, action: {
                                step = .chooseVerificationMethod
                            })
                        }
                    }
                }
            }
            .environmentObject(ownerRepository)
        }
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
        SelectIdentityVerificationMethod(
            step: Binding.constant(.chooseVerificationMethod)
        )
        .navigationInlineTitle("Reset Login ID")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                DismissButton(icon: .back)
            }
        }
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
