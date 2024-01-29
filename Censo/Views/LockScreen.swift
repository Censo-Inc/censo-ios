//
//  LockScreen.swift
//  Censo
//
//  Created by Brendan Flood on 10/20/23.
//

import SwiftUI
import Moya

struct LockScreen: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var reloadOwnerState: () -> Void
    var onOwnerStateUpdated: (API.OwnerState) -> Void

//    enum Route: Hashable {
//        case authenticate
//        case resetAuth
//    }
//    
//    @State private var navPath = NavigationPath()
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
                    session: session,
                    onReadyToUploadResults: { biometryData in
                        return .unlock(API.UnlockApiRequest(biometryVerificationId: biometryData.verificationId, biometryData: biometryData))
                    },
                    onSuccess: { response in
                        onOwnerStateUpdated(response.ownerState)
                    },
                    onCancelled: {
                        route = .locked
                        reloadOwnerState()
                    }
                )
            case .password:
                NavigationStack {
                    PasswordAuth<API.UnlockWithPasswordApiResponse>(
                        session: session,
                        submitTo: { password in
                            return .unlockWithPassword(API.UnlockWithPasswordApiRequest(password: password))
                        },
                        onSuccess: { response in
                            onOwnerStateUpdated(response.ownerState)
                        },
                        onInvalidPassword: {
                            reloadOwnerState()
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
                    session: session,
                    ownerState: ownerState,
                    onOwnerStateUpdated: onOwnerStateUpdated,
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
    NavigationStack {
        LockScreen(
            session: .sample,
            ownerState: .sample,
            reloadOwnerState: {},
            onOwnerStateUpdated: { _ in }
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}

#Preview("can reset biometry") {
    NavigationStack {
        LockScreen(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                authType: .facetec,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: true
            ),
            reloadOwnerState: {},
            onOwnerStateUpdated: { _ in }
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}

#Preview("can reset password") {
    NavigationStack {
        LockScreen(
            session: .sample,
            ownerState: API.OwnerState.Ready(
                policy: .sample,
                vault: .sample,
                authType: .password,
                subscriptionStatus: .active,
                timelockSetting: .sample,
                subscriptionRequired: true,
                onboarded: true,
                canRequestAuthenticationReset: true
            ),
            reloadOwnerState: {},
            onOwnerStateUpdated: { _ in }
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
