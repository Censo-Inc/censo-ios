//
//  InitPhrasesAccessFlow.swift
//  Censo
//
//  Created by Anton Onyshchenko on 30.11.23.
//

import SwiftUI

struct InitPhrasesAccessFlow: View {
    var ownerState: API.OwnerState.Ready
    
    var body: some View {
        NavigationView {
            RequestAccess(
                ownerState: ownerState,
                intent: .accessPhrases,
                accessAvailableView: { params in
                    PhrasesAccessAvailable(
                        ownerState: ownerState,
                        onFinished: params.onFinished
                    )
                }
            )
        }
    }
}

