//
//  BiometryFailed.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct BiometryFailed: View {
    var onRetry: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Text("Biometry Failed")
                .font(.title)
                .padding()

            Spacer()

            Button {
                onRetry()
            } label: {
                Text("Try again")
                    .frame(maxWidth: .infinity)
            }
            .padding(30)
        }
        .multilineTextAlignment(.center)
        .buttonStyle(FilledButtonStyle())
    }
}

#if DEBUG
struct BiometryFailed_Preview: PreviewProvider {
    static var previews: some View {
        BiometryFailed(onRetry: {})
    }
}
#endif
