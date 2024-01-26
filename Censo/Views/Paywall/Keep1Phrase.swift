//
//  Keep1Phrase.swift
//  Censo
//
//  Created by Ben Holzman on 1/25/24.
//

import SwiftUI
import Sentry
import Moya

struct Keep1Phrase: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.apiProvider) var apiProvider
    @Binding var ownerState: API.OwnerState
    var session: Session
    @State var selectedPhrase: Int?
    @State private var confirmDeletion = false
    @State private var deleteInProgress = false

    var body: some View {
        VStack {
            Text("Pick one phrase to keep for free")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            switch ownerState {
            case .initial:
                EmptyView()
            case .ready(let ready):
                ScrollView {
                    ForEach(0..<ready.vault.seedPhrases.count, id: \.self) { i in
                        Button {
                            selectedPhrase = i
                        } label: {
                            let strikeThroughActive = selectedPhrase != nil && selectedPhrase != i
                            HStack(alignment: .center) {
                                Text(ready.vault.seedPhrases[i].label)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .padding([.horizontal])
                                    .foregroundColor(selectedPhrase == i ? .Censo.green : .Censo.primaryForeground)
                                    .strikethrough(strikeThroughActive)
                                    .multilineTextAlignment(.leading)
                                    .buttonStyle(PlainButtonStyle())
                                if (selectedPhrase == i) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .symbolRenderingMode(.palette)
                                        .foregroundStyle(Color.Censo.green)
                                        .font(.system(size: 20))
                                        .padding([.horizontal], 10)
                                }
                            }
                            .frame(maxWidth: 300, minHeight: 107, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                    .foregroundColor(.Censo.gray224)
                            )
                        }
                        .padding()
                    }
                }
            }
            Button {
                confirmDeletion = true
            } label: {
                if deleteInProgress {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(selectedPhrase == nil)
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
        .toolbar(content: {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            }
        })
        .alert("Confirm delete phrases", isPresented: $confirmDeletion) {
            Button("Confirm", role: .destructive) {
                switch ownerState {
                case .initial:
                    break
                case .ready(let ready):
                    deleteInProgress = true
                    let selectedPhraseId = ready.vault.seedPhrases[selectedPhrase!].guid
                    apiProvider.decodableRequest(
                        with: session,
                        endpoint: .deleteMultipleSeedPhrases(
                            guids: ready.vault.seedPhrases
                                .filter {$0.guid != selectedPhraseId }
                                .map { $0.guid }
                        )
                    ) { (result: Result<API.DeleteSeedPhraseApiResponse, MoyaError>) in
                        deleteInProgress = false
                        switch result {
                        case .success(let response):
                            ownerState = response.ownerState
                        case .failure(let error):
                            SentrySDK.captureWithTag(error: error, tagValue: "Delete Multiple Phrases")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            switch ownerState {
            case .ready(let ready):
                if (selectedPhrase != nil) {
                    Text("Please confirm that you want to delete \(ready.vault.seedPhrases.count - 1) seed phrases and keep '\(ready.vault.seedPhrases[selectedPhrase!].label)'.\nAre you sure?")
                } else {
                    Text("Please confirm that you want to delete your data.\nAre you sure?")
                }
            case .initial:
                Text("Please confirm that you want to delete your data.\nAre you sure?")
            }
        }
    }
}

#if DEBUG
#Preview {
    Keep1Phrase(ownerState: .constant(.ready(API.OwnerState.Ready(policy: .sample, vault: .sample, authType: .facetec, subscriptionStatus: .none, timelockSetting: .sample, subscriptionRequired: true, onboarded: true))), session: .sample)
}
#endif
