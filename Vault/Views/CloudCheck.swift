//
//  CloudCheck.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-26.
//

import SwiftUI

struct CloudCheck<Content>: View where Content : View {
    @State private var signedInToCloud = FileManager.default.ubiquityIdentityToken != nil

    @ViewBuilder var content: () -> Content

    var body: some View {
        Group {
            if signedInToCloud {
                content()
            } else {
                Text("You will need to be logged in to an iCloud account to continue")
                    .padding()
                    .multilineTextAlignment(.center)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification), perform: { _ in
            signedInToCloud = FileManager.default.ubiquityIdentityToken != nil
        })
    }
}
