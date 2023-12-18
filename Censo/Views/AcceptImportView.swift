//
//  AcceptImportView.swift
//  Censo
//
//  Created by Ben Holzman on 12/13/23.
//

import SwiftUI

struct AcceptImportView: View {
    var importToAccept: Import
    var onAccept: (Import) -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack {
            Spacer()
            Text("\(importToAccept.name) would like to export a seed phrase to you.")
                .font(.title)
                .multilineTextAlignment(.center)
            
            Button {
                onAccept(importToAccept)
            } label: {
                Text("Accept")
                    .frame(maxWidth: .infinity)

            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            
            Button {
                onDecline()
            } label: {
                Text("Decline")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            Spacer()
        }
        .padding()
    }
}

#if DEBUG
#Preview {
    AcceptImportView(importToAccept: Import(importKey: .sample, timestamp: .max, signature: .sample, name: "Name"), onAccept: {_ in }, onDecline: {})
}
#endif
