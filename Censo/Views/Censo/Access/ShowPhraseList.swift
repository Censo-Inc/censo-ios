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
    
    var body: some View {
        VStack {
            
            Spacer()
            
            Text("Which seed phrase would you like to access \(viewedPhrases.count == 0 ? "first" : "next")?")
                .font(.system(size: 24, weight: .semibold))
                .padding()
            
            ScrollView {
                ForEach(0..<ownerState.vault.secrets.count, id: \.self) { i in
                    Button {
                        onPhraseSelected(i)
                    } label: {
                        HStack {
                            Text(ownerState.vault.secrets[i].label)
                                .font(.system(size: 24, weight: .medium))
                                .padding([.leading])
                                .foregroundColor(viewedPhrases.contains(i) ? .green : .black)
                                .frame(maxWidth: 300, minHeight: 107, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1))
                                        .foregroundColor(.Censo.lightGray)
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
                                }
                            }.frame(minWidth: 40)
                            
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            Button {
                onFinished()
            } label: {
                Text("Finish")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
        }
        .padding()
    }
}



#if DEBUG
#Preview {
    NavigationView {
        ShowPhraseList(
            session: .sample,
            ownerState: API.OwnerState.Ready(policy: .sample, vault: .sample),
            onOwnerStateUpdated: {_ in },
            viewedPhrases: [1],
            onPhraseSelected: {_ in },
            onFinished: {}
        )
    }
}
#endif

