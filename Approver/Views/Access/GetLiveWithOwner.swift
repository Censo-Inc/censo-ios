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
    
    var onContinue: () -> Void
    
    init(onContinue: @escaping () -> Void) {
        self.onContinue = onContinue
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Spacer()
                
                Text("Get live with the owner")
                    .font(.title2)
                    .bold()
                    .padding(.vertical)
                
                VStack(alignment: .leading) {
                    Text("For maximum security, it's best to be face-to-face with the phrase owner in a private location.")
                        .font(.subheadline)
                    
                    Text("This ensures direct and private sharing of the necessary codes and information, reducing the risk of eavesdropping and interception.")
                        .font(.subheadline)
                        .padding(.vertical)
                }
                
                Button {
                    onContinue()
                } label: {
                    Text("Continue live")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(RoundedButtonStyle())
            }
            .padding(.vertical)
            .padding(.horizontal, 32)
        }
        .navigationTitle(Text("Approve Access"))
        .toolbarBackground(.visible, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.black)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        GetLiveWithOwner(onContinue: {})
    }
}

extension Base58EncodedPublicKey {
    static var sample: Self {
        try! .init(value: "PQVchxggKG9sQRNx9Yi6Yu5gSCeLQFmxuCzmx1zmNBdRVoCTPeab1F612GE4N7UZezqGBDYUB25yGuFzWsob9wY2")
    }
}
extension API.GuardianPhase.RecoveryRequested {
    static var sample: Self {
        .init(createdAt: Date(), recoveryPublicKey: .sample)
    }
}

extension API.GuardianState {
    static var sample: Self {
        .init(
            participantId: .random(),
            phase: .recoveryRequested(.sample)
        )
    }
}
#endif
