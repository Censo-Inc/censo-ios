//
//  IdentityVerification.swift
//  Censo
//
//  Created by Ata Namvari on 2023-09-29.
//

import SwiftUI

struct IdentityVerification: View {
    @Binding var inProgress: Bool
    var onContinue: () -> Void

    var body: some View {
        VStack {
            Text("Establish your identity")
                .font(.title.bold())
                .padding()

            InfoBoard {
                Text("""
                    Access to your seed phrases always requires your approval which is obtained using an encrypted 3d face scan to confirm your identity.

                     This scan is not associated with any personally identifiable information and it provides a reliable way to securely control access to your seed phrases
                    """
                )
                .font(.callout)
            }

            Spacer()


            Button {

            } label: {
                Text("How does this work?")
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .frame(height: 44)
            }
            .padding(.horizontal)
            .buttonStyle(BorderedButtonStyle())

            Button {
                onContinue()
            } label: {
                if inProgress {
                    ProgressView()
                } else {
                    Text("Continue")
                }
            }
            .padding()
            .buttonStyle(FilledButtonStyle())
            .disabled(inProgress)
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
struct IdentityVerification_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            IdentityVerification(inProgress: .constant(false)) { }
        }
    }
}
#endif
