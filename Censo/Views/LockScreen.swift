//
//  LockScreen.swift
//  Censo
//
//  Created by Brendan Flood on 10/20/23.
//

import SwiftUI

struct LockScreen: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready

    enum Route {
        case locked
        case authenticate
        case resetAuth
    }
    @State private var route: Route = .locked
    
    var body: some View {
        switch (route) {
        case .locked:
            GeometryReader { geometry in
                ZStack {
                    VStack {
                        Spacer()
                        Image("DogSleeping")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.3)
                            .ignoresSafeArea()
                    }
                    
                    VStack {
                        Image("CensoLogo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100)
                        
                        Text("Welcome back.")
                            .font(.largeTitle)
                            .padding(.bottom, 1)
                            .bold()
                        
                        Rectangle()
                            .fill(Color.Censo.aquaBlue)
                            .frame(width: 39, height: 6)
                            .padding(.vertical, 10)
                        
                        Text("The Seed Phrase Manager that lets you sleep at night.")
                            .font(.largeTitle)
                            .bold()
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom)
                        
                        Button {
                            route = .authenticate
                        } label: {
                            HStack {
                                Spacer()
                                Text("Continue")
                                Spacer()
                            }
                        }
                        .buttonStyle(RoundedButtonStyle())
                        .frame(maxWidth: 220)
                        .accessibilityIdentifier("lockContinueButton")
                        
                        if ownerState.canRequestAuthenticationReset {
                            Text("Having trouble with \(ownerState.authType == .facetec ? "face" : "password") verification?")
                                .font(.subheadline)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            Button(action: {
                                route = .resetAuth
                            }, label: {
                                Text("Tap here.")
                                    .font(.subheadline)
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.horizontal)
                            })
                        }
                        
                        Spacer()
                    }
                    .padding([.horizontal, .top])
                    .multilineTextAlignment(.center)
                }
            }
        case .authenticate:
            switch ownerState.authType {
            case .facetec:
                FacetecAuth<API.UnlockApiResponse>(
                    onFaceScanReady: { biometryData, completion in
                        ownerRepository.unlock(
                            API.UnlockApiRequest(biometryVerificationId: biometryData.verificationId, biometryData: biometryData),
                            completion
                        )
                    },
                    onSuccess: { response in
                        ownerStateStoreController.replace(response.ownerState)
                    },
                    onCancelled: {
                        route = .locked
                        ownerStateStoreController.reload()
                    }
                )
            case .password:
                NavigationStack {
                    PasswordAuth<API.UnlockWithPasswordApiResponse>(
                        submit: { password, completion in
                            ownerRepository.unlockWithPassword(API.UnlockWithPasswordApiRequest(password: password), completion)
                        },
                        onSuccess: { response in
                        ownerStateStoreController.replace(response.ownerState)
                        },
                        onInvalidPassword: {
                            ownerStateStoreController.reload()
                        },
                        onAuthResetTriggered: ownerState.canRequestAuthenticationReset ? {
                            route = .resetAuth
                        } : nil
                    )
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarBackButtonHidden(true)
                    .toolbarBackground(Color.Censo.primaryBackground, for: .navigationBar)
                    .toolbar(content: {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {
                                route = .locked
                            } label: {
                                Image(systemName: "chevron.left")
                            }
                        }
                    })
                }
            case .none:
                EmptyView().onAppear {
                    route = .locked
                }
            }
        case .resetAuth:
            NavigationStack {
                AuthenticationReset(
                    ownerState: ownerState,
                    onExit: {
                        route = .locked
                    }
                )
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationStack {
            LockScreen(
                ownerState: API.OwnerState.Ready.sample
            )
        }
    }
}

#Preview("can reset biometry") {
    LoggedInOwnerPreviewContainer {
        NavigationStack {
            LockScreen(
                ownerState: API.OwnerState.Ready(
                    policy: .sample,
                    vault: .sample,
                    authType: .facetec,
                    subscriptionStatus: .active,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: true
                )
            )
        }
    }
}

#Preview("can reset password") {
    LoggedInOwnerPreviewContainer {
        NavigationStack {
            LockScreen(
                ownerState: API.OwnerState.Ready(
                    policy: .sample,
                    vault: .sample,
                    authType: .password,
                    subscriptionStatus: .active,
                    timelockSetting: .sample,
                    subscriptionRequired: true,
                    onboarded: true,
                    canRequestAuthenticationReset: true
                )
            )
        }
    }
}
#endif
