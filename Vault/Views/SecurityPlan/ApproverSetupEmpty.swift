//
//  ApproverSetupEmpty.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

struct ApproverSetupEmpty: View {
    @Binding var showingAddApprover: Bool

    var body: some View {
        InfoBoard {
            Text("Select only people you trust. You will rely upon your approvers to help you access your seed phrases when you require it, although your approvers can never access your seed phrases themselves.")
        }
        .padding()

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
            showingAddApprover = true
        } label: {
            Text("Select First Approver")
        }
        .padding()
        .buttonStyle(FilledButtonStyle())
    }
}
