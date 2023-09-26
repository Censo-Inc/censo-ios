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

    @State private var threshold: Float

    var approvers: [String]

    init(approvers: [String]) {
        self._threshold = State(initialValue: Float(approvers.count.recommendedThreshold))
        self.approvers = approvers
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

                VStack {
                    HStack {
                        ForEach(1...approvers.count, id: \.self) { i in
                            Image(systemName: "iphone")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15)
                                .overlay {
                                    if i <= Int(threshold) {
                                        Image(systemName: "checkmark")
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 7)
                                    }
                                }

                            if i != approvers.count {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 5)

                    Slider(value: $threshold, in: 1...Float(approvers.count), step: 1)
                        .tint(.Censo.darkBlue)

                    HStack {
                        ForEach(1...approvers.count, id: \.self) { i in
                            Text("\(i)")
                                .font(.caption.bold())

                            if i != approvers.count {
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .padding(.horizontal, 25)
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

            Button {

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
            RequiredApprovals(approvers: ["Ben", "Steve", "John"])
        }
    }
}
#endif
