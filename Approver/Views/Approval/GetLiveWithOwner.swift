//
//  GetLiveWithOwner.swift
//  Access
//
//  Created by Anton Onyshchenko on 11/01/23.
//

import SwiftUI

import SwiftUI
import Moya

struct GetLiveWithOwner: View {
    @Environment(\.dismiss) var dismiss
    
    var intent: Intent
    var onContinue: () -> Void
    var onBack: (() -> Void)?
    
    enum Intent {
        case accessApproval
        case loginIdReset
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Spacer()
                
                switch (intent) {
                case .accessApproval:
                    Text("Approve request")
                        .font(.title2)
                        .bold()
                        .padding(.vertical)
                    
                    Text("Approving a request will take about 2 minutes. This approval should preferably take place while you’re on the phone or in-person to ensure that you are assisting the proper individual.\n\nIn the next step you will verify the identity of the person you are assisting before approving the request.")
                        .font(.subheadline)
                case .loginIdReset:
                    Text("Get live with the person that contacted you")
                        .font(.title2)
                        .bold()
                        .padding(.vertical)
                    
                    Text("This process should preferably take place while you’re on the phone or in-person to ensure that you are assisting the proper individual.")
                        .font(.subheadline)
                }
                
                Spacer()
                
                Button {
                    onContinue()
                } label: {
                    Text("Continue")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .padding(.vertical)
            .padding(.horizontal, 32)
        }
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                if let onBack {
                    Button {
                        onBack()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                } else {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        })
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GetLiveWithOwner(intent: .accessApproval, onContinue: {})
    }
}

extension Base58EncodedPublicKey {
    static var sample: Self {
        try! .init(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
    }
}
extension API.ApproverPhase.AccessRequested {
    static var sample: Self {
        .init(createdAt: Date(), accessPublicKey: .sample)
    }
}

extension API.ApproverState {
    static var sample: Self {
        .init(
            participantId: .random(),
            phase: .accessRequested(.sample)
        )
    }
}
#endif