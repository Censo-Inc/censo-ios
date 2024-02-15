//
//  EnterInfoForBeneficiary.swift
//  Censo
//
//  Created by Anton Onyshchenko on 09.02.24.
//

import Foundation
import SwiftUI
import Sentry

struct EnterInfoForBeneficiary: View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    @EnvironmentObject var ownerStateStoreController: OwnerStateStoreController
    
    var ownerState: API.OwnerState.Ready
    
    enum Route: Hashable {
        case entryTypeChoice
        case approversContactInfoEntry
        case seedPhrasesList
        case seedPhraseNotesEntry(phrase: API.SeedPhrase)
    }
    
    class Router : ObservableObject {
        @Published var path: NavigationPath
        
        init(path: [Route]) {
            self.path = NavigationPath(path)
        }
        
        func navigate(to destination: Route) {
            path.append(destination)
        }
    }
    
    @StateObject private var router = Router(path: [])
    
    var body: some View {
        NavigationStack(path: $router.path) {
            Intro(router: router)
                .navigationDestination(for: Route.self) { destination in
                    switch destination {
                    case .entryTypeChoice: 
                        EntryTypeChoice(router: router)
                    case .approversContactInfoEntry: 
                        ApproversContactInfo(
                            policy: ownerState.policy,
                            publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey
                        )
                    case .seedPhrasesList: 
                        SeedPhrasesList(
                            router: router,
                            policy: ownerState.policy,
                            vault: ownerState.vault
                        )
                    case .seedPhraseNotesEntry(let phrase):
                        SeedPhraseNotes(
                            policy: ownerState.policy,
                            publicMasterEncryptionKey: ownerState.vault.publicMasterEncryptionKey,
                            seedPhrase: phrase,
                            forBeneficiary: true,
                            dismissButtonIcon: .back
                        )
                        .navigationInlineTitle("Legacy - \(phrase.label)")
                    }
                }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        VStack {}
            .sheet(isPresented: Binding.constant(true)) {
                EnterInfoForBeneficiary(
                    ownerState: API.OwnerState.Ready(
                        policy: .sample2ApproversAndAcceptedBeneficiary,
                        vault: .sample,
                        authType: .facetec,
                        subscriptionStatus: .active,
                        timelockSetting: .sample,
                        subscriptionRequired: true,
                        onboarded: true,
                        canRequestAuthenticationReset: false
                    )
                )
            }
    }
}
#endif
