//
//  IdentityEstablished.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-29.
//

import SwiftUI

struct IdentityEstablished: View {
    var action: () -> Void

    var body: some View {
        OpenVault {
            VStack {
                Text("Your identity has been established")
                    .font(.title)
                    .padding()

                InfoBoard {
                    VStack(spacing: 20) {
                        Text("From this point forward your face scan will be required to use the app.")
                            .bold()

                        Text("Each scan will allow you 15 minutes of use and you will see a timer on-screen that shows your remaining time")
                    }
                    .foregroundColor(.black)
                }

                Spacer()

                Button {
                    action()
                } label: {
                    Text("Next: Activate Approvers")
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .frame(height: 44)
                }
                .buttonStyle(FilledButtonStyle())
                .padding()
            }
            .multilineTextAlignment(.center)
        }
    }
}

#if DEBUG
struct IdentityEstablished_Previews: PreviewProvider {
    static var previews: some View {
        IdentityEstablished { }
    }
}
#endif
