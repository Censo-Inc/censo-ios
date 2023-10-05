//
//  SecurityPlanReview.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-26.
//

import SwiftUI

struct SecurityPlanReview: View {
    var session: Session
    @Binding var approvers: [String]
    @Binding var threshold: Int
    @Binding var showingAddApprover: Bool
    var onEdit: (Int) -> Void
    var onComplete: (API.OwnerState) -> Void

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Text("Review")
                        .font(.title.bold())
                        .padding([.top, .horizontal])

                    LazyVStack {
                        ForEach(0..<approvers.count, id: \.self) { i in
                            ApproverRow(nickname: approvers[i]) {
                                onEdit(i)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 5)

                            Divider()
                                .padding(.leading, 20)
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
                        .padding(.top, 5)
                    }

                    Spacer()

                    VStack {
                        InfoBoard {
                            if approvers.count == 0 {
                                Text("You must at least add one approver")
                            } else if approvers.count == 1 {
                                Text("You have a single approver so their approval will be required to access your seed phrases.")
                            } else {
                                VStack {
                                    Text("To access your seed phrases,")
                                        .font(.caption)
                                    Text("\(Int(threshold))").bold() + Text(" of ").font(.caption) + Text("\(approvers.count)").bold()
                                    Text("approvals are required for access")
                                        .font(.caption)
                                }
                            }
                        }

                        if approvers.count > 1 {
                            ThresholdSlider(threshold: $threshold, totalApprovers: approvers.count)
                        }
                    }

                    NavigationLink {
                        PolicySetup(session: session, threshold: threshold, approvers: approvers, onComplete: onComplete)
                    } label: {
                        Text("Confirm")
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .frame(height: 44)
                    }
                    .padding()
                    .buttonStyle(FilledButtonStyle())
                }
                .multilineTextAlignment(.center)
                .frame(minHeight: geometry.size.height)
            }
        }
        .navigationTitle(Text("Setup Security Plan"))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .onChange(of: approvers) { newApprovers in
            threshold = min(threshold, newApprovers.count)
        }
    }
}

#if DEBUG
struct SecurityPlanReview_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SecurityPlanReview(session: .sample, approvers: .constant(["Jerry", "Elaine", "Kramer", "George"]), threshold: .constant(1), showingAddApprover: .constant(false)) { i in
            } onComplete: { _ in

            }
        }
    }
}
#endif
