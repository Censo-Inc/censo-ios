//
//  InitPhrasesAccessFlow.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI
import Moya
import raygun4apple

struct InitPhrasesAccessFlow: View {
    @Environment(\.apiProvider) var apiProvider
    @Environment(\.dismiss) var dismiss
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    
    var body: some View {
        NavigationView {
            RequestAccess(
                session: session,
                ownerState: ownerState,
                onOwnerStateUpdated: onOwnerStateUpdated,
                intent: .accessPhrases,
                accessAvailableView: { params in
                    PhrasesAccessAvailable(
                        session: session,
                        ownerState: ownerState,
                        onFinished: params.onFinished,
                        onOwnerStateUpdated: onOwnerStateUpdated
                    )
                }
            )
        }
    }
}

