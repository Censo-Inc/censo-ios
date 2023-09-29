//
//  ApproversSetup.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-25.
//

import SwiftUI

struct ApproversSetup: View {
    @State private var showingAddApprover = false
    @State private var nickname: String = ""
    @State private var showingEditSheet = false
    @State private var editingIndex: Int?
    @State private var newNickname = ""
    @State private var showingRenameSheet = false

    @AppStorage("approvers") private var _approvers: String = ""

    private var approvers: Binding<[String]> {
        Binding {
            _approvers.split(separator: "|").map(String.init)
        } set: { newValue in
            _approvers = newValue.joined(separator: "|")
        }
    }

    var session: Session
    var onComplete: (API.OwnerState) -> Void

    var body: some View {
        NavigationStack {
            VStack {
                Text("Select Approvers")
                    .font(.title.bold())
                    .padding(.top)

                if approvers.isEmpty {
                    ApproverSetupEmpty(showingAddApprover: $showingAddApprover)
                } else {
                    ApproverSetupNonEmpty(
                        session: session,
                        approvers: approvers,
                        showingAddApprover: $showingAddApprover,
                        onEdit: { i in
                            showingEditSheet = true
                            editingIndex = i
                        },
                        onComplete: onComplete
                    )
                }
            }
            .multilineTextAlignment(.center)
            .navigationTitle(Text("Setup Security Plan"))
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard)
        }
        .alert("Enter Nickname", isPresented: $showingAddApprover) {
            TextField("Nickname", text: $nickname, prompt: Text("e.g. Ben"))

            Button(role: .cancel) {
                nickname = ""
            } label: {
                Text("Cancel")
            }

            Button {
                guard !nickname.sanitized.isEmpty else { return }
                approvers.wrappedValue.append(nickname.sanitized)
                nickname = ""
            } label: {
                Text("Continue")
            }
        } message: {
            Text("Just something for you to remember this approver by")
        }
        .confirmationDialog("Edit", isPresented: $showingEditSheet, presenting: editingIndex) { i in
            Button  {
                newNickname = approvers.wrappedValue[i]
                showingRenameSheet = true
            } label: {
                Text("Rename")
            }

            Button(role: .destructive) {
                showingEditSheet = false
                approvers.wrappedValue.remove(at: i)
            } label: {
                Text("Delete")
            }
        } message: { i in
            Text("Edit Approver \(approvers.wrappedValue[i])")
        }
        .alert("Enter New Nickname", isPresented: $showingRenameSheet, presenting: editingIndex) { i in
            TextField("Nickname", text: $newNickname, prompt: Text("e.g. Ben"))

            Button(role: .cancel) {
                showingRenameSheet = false
            } label: {
                Text("Cancel")
            }

            Button {
                guard !newNickname.sanitized.isEmpty else { return }
                approvers.wrappedValue[i] = newNickname.sanitized
            } label: {
                Text("Continue")
            }
        }
    }
}

private extension String {
    var sanitized: String {
        replacingOccurrences(of: "|", with: "")
    }
}

#if DEBUG
struct ApproversSetup_Previews: PreviewProvider {
    static var previews: some View {
        ApproversSetup(session: .sample) { _ in }
    }
}
#endif
