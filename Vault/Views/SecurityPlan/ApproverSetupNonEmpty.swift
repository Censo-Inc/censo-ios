//
//  ApproverSetupNonEmpty.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

struct ApproverSetupNonEmpty: View {
    @State private var showingEditSheet = false
    @State private var editingIndex: Int?
    @State private var newName: String = ""
    @State private var showingRenameSheet = false

    var approvers: [String]
    @Binding var showingAddApprover: Bool
    var onRename: (Int, String) -> Void
    var onDelete: (Int) -> Void

    var body: some View {
        Group {
            Text("You have selected ") + Text("\(approvers.count) approver\(approvers.count == 1 ? "" : "s")").bold().foregroundColor(.black) + Text(" to help you access your seed phrase")
        }
        .font(.callout)
        .padding()
        .foregroundColor(.Censo.lightGray)

        List {
            ForEach(0..<approvers.count, id: \.self) { i in
                HStack {
                    VStack(alignment: .leading) {
                        Text("Approver")
                            .font(.caption)
                            .foregroundColor(.Censo.lightGray)
                        Text(approvers[i])
                    }

                    Spacer()

                    Button {
                        showingEditSheet = true
                        editingIndex = i
                    } label: {
                        Image(systemName: "pencil")
                            .renderingMode(.template)
                            .foregroundColor(.Censo.gray)
                    }
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
            .listRowSeparator(.hidden)
        }
        .listStyle(PlainListStyle())
        .confirmationDialog("Edit", isPresented: $showingEditSheet, presenting: editingIndex) { i in
            Button  {
                newName = approvers[i]
                showingRenameSheet = true
            } label: {
                Text("Rename")
            }

            Button(role: .destructive) {
                showingEditSheet = false
                onDelete(i)
            } label: {
                Text("Delete")
            }
        } message: { i in
            Text("Edit Approver \(approvers[i])")
        }
        .alert("Enter New Nickname", isPresented: $showingRenameSheet, presenting: editingIndex) { i in
            TextField("Nickname", text: $newName, prompt: Text("e.g. Ben"))

            Button(role: .cancel) {
                showingRenameSheet = false
            } label: {
                Text("Cancel")
            }

            Button {
                guard !newName.isEmpty else { return }
                onRename(i, newName)
            } label: {
                Text("Continue")
            }
        }

        Button {

        } label: {
            Text("How does this work?")
                .frame(maxWidth: .infinity, minHeight: 44)
                .frame(height: 44)
        }
        .padding(.horizontal)
        .buttonStyle(BorderedButtonStyle())

        NavigationLink {
            RequiredApprovals(approvers: approvers)
        } label: {
            Text("Next: Required Approvals")
        }
        .padding()
        .buttonStyle(FilledButtonStyle())
        .disabled(approvers.isEmpty)
    }
}
