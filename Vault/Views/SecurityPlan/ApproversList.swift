//
//  ApproversList.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

struct ApproversList: View {
    var approvers: [String]
    @Binding var showingAddApprover: Bool
    var onEdit: (Int) -> Void

    var body: some View {
        List {
            ForEach(0..<approvers.count, id: \.self) { i in
                ApproverRow(nickname: approvers[i]) {
                    onEdit(i)
                }
            }

            HStack {
                Spacer()

                Button {
                    showingAddApprover = true
                } label: {
                    Text("+ Select Another")
                        .padding(10)
                }
                .buttonStyle(BorderedButtonStyle())
                .frame(minWidth: .leastNonzeroMagnitude)

                Spacer()
            }

            HStack {

            }
            .frame(height: 1)
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
    }
}

struct ApproverRow: View {
    var nickname: String
    var onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Approver")
                    .font(.caption)
                    .foregroundColor(.Censo.lightGray)
                Text(nickname)
            }

            Spacer()

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .renderingMode(.template)
                    .foregroundColor(.Censo.gray)
            }
        }
    }
}
