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

    @AppStorage("approvers") private var _approvers: String = ""

    private var approvers: [String] {
        get {
            _approvers.split(separator: "|").map(String.init)
        }
        nonmutating set {
            _approvers = newValue.joined(separator: "|")
        }
    }

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
                        approvers: approvers,
                        showingAddApprover: $showingAddApprover
                    ) { i, newName in
                        approvers[i] = newName
                    } onDelete: { i in
                        approvers.remove(at: i)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .navigationTitle(Text("Setup Security Plan"))
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard)
            .alert("Enter Nickname", isPresented: $showingAddApprover) {
                TextField("Nickname", text: $nickname, prompt: Text("e.g. Ben"))

                Button(role: .cancel) {
                    nickname = ""
                } label: {
                    Text("Cancel")
                }

                Button {
                    guard !nickname.isEmpty else { return }
                    approvers.append(nickname)
                    nickname = ""
                } label: {
                    Text("Continue")
                }
            } message: {
                Text("Just something for you to remember this approver by")
            }
        }
    }
}

#if DEBUG
struct ApproversSetup_Previews: PreviewProvider {
    static var previews: some View {
        ApproversSetup()
    }
}
#endif
