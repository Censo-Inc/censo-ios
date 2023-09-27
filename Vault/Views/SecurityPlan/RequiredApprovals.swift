//
//  RequiredApprovals.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

private extension Int {
    var recommendedThreshold: Int {
        Int(ceil(Double(self) / 2))
    }
}

struct RequiredApprovals: View {
    @Environment(\.dismiss) var dismiss

    @State private var threshold: Int

    @Binding var approvers: [String]
    @Binding var showingAddApprover: Bool
    var onEdit: (Int) -> Void

    init(approvers: Binding<[String]>, showingAddApprover: Binding<Bool>, onEdit: @escaping (Int) -> Void) {
        self._threshold = State(initialValue: approvers.wrappedValue.count.recommendedThreshold)
        self._approvers = approvers
        self._showingAddApprover = showingAddApprover
        self.onEdit = onEdit
    }

    private var recommendedThreshold: Int {
        approvers.count.recommendedThreshold
    }

    var body: some View {
        VStack {
            Text("Required Approvals")
                .font(.title.bold())
                .padding()
                .padding(.bottom, 20)

            if approvers.count == 1 {
                InfoBoard {
                    Text("You have a single approver so their approval will be required to access your seed phrases.")
                }

                Spacer()
            } else {
                InfoBoard {
                    VStack(spacing: 40) {
                        Text("Choose how many approvals will be required for you to access your seed phrases")

                        Text("We recommend ") + Text("\(recommendedThreshold)").bold() + Text(" but you can change it below.")
                    }
                }

                Spacer()

                ThresholdSlider(threshold: $threshold, totalApprovers: approvers.count)
                    .padding(.vertical, 30)

                VStack {
                    Text("\(Int(threshold))").bold() + Text(" of ").font(.caption) + Text("\(approvers.count)").bold()
                    Text("approvals are required for access")
                        .font(.caption)
                }
                .padding(.bottom)
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
                SecurityPlanReview(
                    approvers: $approvers,
                    threshold: $threshold,
                    showingAddApprover: $showingAddApprover,
                    onEdit: onEdit
                )
            } label: {
                Text("Next: Review")
            }
            .padding()
            .buttonStyle(FilledButtonStyle())
        }
        .multilineTextAlignment(.center)
        .navigationTitle(Text("Setup Security Plan"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                        .foregroundColor(.white)
                        .font(.body.bold())
                }
            }
        }
    }
}



#if DEBUG
struct RequiredApprovals_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            RequiredApprovals(approvers: .constant(["Ben", "Jerry"]), showingAddApprover: .constant(false)) { _ in
                
            }
        }
    }
}
#endif
