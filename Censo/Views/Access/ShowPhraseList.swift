//
//  ShowPhraseList.swift
//  Censo
//
//  Created by Brendan Flood on 10/26/23.
//

import SwiftUI
import Moya

struct ShowPhraseList: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    var ownerState: API.OwnerState.Ready
    var onOwnerStateUpdated: (API.OwnerState) -> Void
    var viewedPhrases: [Int]
    var onPhraseSelected: (Int) -> Void
    var onFinished: () -> Void
    @State private var confirmExit = false
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("Select the seed phrase you would like to access:")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()
            
            ScrollView {
                ForEach(0..<ownerState.vault.seedPhrases.count, id: \.self) { i in
                    Button {
                        onPhraseSelected(i)
                    } label: {
                        HStack {
                            Text(ownerState.vault.seedPhrases[i].label)
                                .font(.title2)
                                .fontWeight(.medium)
                                .padding([.leading])
                                .foregroundColor(viewedPhrases.contains(i) ? .green : .Censo.primaryForeground)
                                .frame(maxWidth: 300, minHeight: 107, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                        .foregroundColor(.Censo.gray224)
                                )
                                .multilineTextAlignment(.leading)
                                .buttonStyle(PlainButtonStyle())
                            Spacer()
                            VStack {
                                if viewedPhrases.contains(i) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(.white, Color.Censo.green)
                                        .font(.system(size: 28))
                                } else {
                                    Image(systemName: "chevron.forward")
                                        .symbolRenderingMode(.palette)
                                        .font(.system(size: 28))
                                }
                            }.frame(minWidth: 40)
                            
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            Button {
                if ownerState.policy.externalApproversCount > 0 || ownerState.timelockSetting.currentTimelockInSeconds != nil {
                    confirmExit = true
                } else {
                    onFinished()
                }
            } label: {
                Text("Exit accessing phrases")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
        }
        .padding()
        .alert("Exit accessing phrases", isPresented: $confirmExit) {
            Button {
                onFinished()
            } label: { Text("Confirm") }
            Button {
            } label: { Text("Cancel") }
        } message: {
            Text("Are you all finished accessing phrases? If you exit you will need to \(ownerState.policy.externalApproversCount > 0 ? "request approval" : "wait for the timelock period") to access your phrases again.")
        }
    }
}



#if DEBUG
#Preview {
    NavigationView {
        ShowPhraseList(
            session: .sample,
            ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .active, timelockSetting: .sample),
            onOwnerStateUpdated: {_ in },
            viewedPhrases: [1],
            onPhraseSelected: {_ in },
            onFinished: {}
        )
        .foregroundColor(Color.Censo.primaryForeground)
    }
}
#endif

