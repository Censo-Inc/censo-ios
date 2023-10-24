//
//  WordEntry.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct WordEntry: View {
    @Environment(\.dismiss) var dismiss

    var number: Int
    var onSubmit: (String) -> Void

    @State private var word = ""

    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            VStack {
                TextField(text: $word) {
                    Text("Type here...")
                }
                .padding()
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit {
                    onSubmit(word)
                }

                let filteredList = BIP39.wordlists[.english]!.filter {
                    $0.starts(with: word.lowercased())
                }

                List {
                    ForEach(filteredList, id:\.self) { word in
                        Button {
                            onSubmit(word)
                        } label: {
                            Text(word)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(Text(NumberFormatter.ordinal.string(from: NSNumber(value: number)) ?? "") + Text(" word"))
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.black)
                    }
                }
            })
            .onAppear(perform: {
                focused = true
            })
        }
    }
}

#if DEBUG
struct WordEntry_Previews: PreviewProvider {
    static var previews: some View {
        WordEntry(number: 2) { _ in

        }
    }
}
#endif
