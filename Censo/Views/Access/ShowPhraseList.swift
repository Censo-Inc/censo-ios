//
//  ShowPhraseList.swift
//  Censo
//
//  Created by Brendan Flood on 10/26/23.
//

import SwiftUI

struct ShowPhraseList: View {
    var ownerState: API.OwnerState.Ready
    var viewedPhrases: [Int]
    var onPhraseSelected: (Int) -> Void
    var onFinished: () -> Void
    @State private var confirmExit = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            
            Text("Select the seed phrase you would like to access:")
                .font(.body)
                .padding(.vertical)
            
            List {
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
                            
                            VStack(alignment: .trailing) {
                                if viewedPhrases.contains(i) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundStyle(.white, Color.Censo.green)
                                } else {
                                    Image(systemName: "chevron.forward")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
                            .symbolRenderingMode(.palette)
                            .frame(width: 24, height: 24)
                        }
                    }
                    .padding(.top)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets())
                }
            }
            .padding(.bottom)
            .listStyle(.plain)
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
            
            Spacer()
            
            Divider()
                .padding(.bottom)
            
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
            .accessibilityIdentifier("finishedButton")
        }
        .padding(.vertical)
        .padding(.horizontal, 32)
        .alert("Exit accessing phrases", isPresented: $confirmExit) {
            Button {
                onFinished()
            } label: { Text("Confirm") }.accessibilityIdentifier("confirmExitAccessingPhrasesButton")
            Button {
            } label: { Text("Cancel") }.accessibilityIdentifier("cancelExitAccessingPhrasesButton")
        } message: {
            Text("Are you all finished accessing phrases? If you exit you will need to \(ownerState.policy.externalApproversCount > 0 ? "request approval" : "wait for the timelock period") to access your phrases again.")
        }
    }
}



#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        VStack {}
        .sheet(isPresented: Binding.constant(true), content: {
            NavigationView {
                ShowPhraseList(
                    ownerState: .sample,
                    viewedPhrases: [1],
                    onPhraseSelected: {_ in },
                    onFinished: {}
                )
                .navigationTitle(Text("Access"))
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarBackButtonHidden()
            }
        })
    }
}
#endif

