//
//  ApproverSetupNonEmpty.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

struct ApproverSetupNonEmpty: View {
    var session: Session
    @Binding var approvers: [String]
    @Binding var showingAddApprover: Bool
    var onEdit: (Int) -> Void
    var onComplete: (API.OwnerState) -> Void

    var body: some View {
        Group {
            Text("You have selected ") + Text("\(approvers.count) approver\(approvers.count == 1 ? "" : "s")").bold().foregroundColor(.black) + Text(" to help you access your seed phrase")
        }
        .font(.callout)
        .padding()
        .foregroundColor(.Censo.lightGray)

        ApproversList(
            approvers: approvers,
            showingAddApprover: $showingAddApprover,
            onEdit: onEdit
        )

        Button {

        } label: {
            Text("How does this work?")
                .frame(maxWidth: .infinity, minHeight: 44)
                .frame(height: 44)
        }
        .padding(.horizontal)
        .buttonStyle(BorderedButtonStyle())

        NavigationLink {
            RequiredApprovals(
                session: session,
                approvers: $approvers,
                showingAddApprover: $showingAddApprover,
                onEdit: onEdit,
                onComplete: onComplete
            )
        } label: {
            Text("Next: Required Approvals")
        }
        .padding()
        .buttonStyle(FilledButtonStyle())
        .disabled(approvers.isEmpty)
    }
}


