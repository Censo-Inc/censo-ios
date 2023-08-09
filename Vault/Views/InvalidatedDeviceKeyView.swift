//
//  InvalidatedDeviceKeyView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct InvalidatedDeviceKeyView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack {
            Spacer()

            Text("Your biometry has changed and phrases cannot be accessed.")
                .font(.title)
                .padding(100)

            Spacer()

            Button {
                onContinue()
            } label: {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .padding(30)
        }
        .buttonStyle(FilledButtonStyle())
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
struct InvalidatedDeviceKeyView_Previews: PreviewProvider {
    static var previews: some View {
        InvalidatedDeviceKeyView(onContinue: {})
    }
}
#endif
