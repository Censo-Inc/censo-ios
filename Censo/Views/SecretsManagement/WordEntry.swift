//
//  WordEntry.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct WordEntry: View {
    @Environment(\.dismiss) var dismiss

    var number: Int
    var onSubmit: (String) -> Void
    var language: WordListLanguage
    var wordList: [String]
    
    init(number: Int, language: WordListLanguage, onSubmit: @escaping (String) -> Void) {
        self.number = number
        self.language = language
        self.onSubmit = onSubmit
        self.wordList = BIP39.wordlists(language)
    }
    
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
                    if wordList.contains(word) {
                        onSubmit(word)
                    } else {
                        focused = true // prevent keyboard from hiding
                    }
                }

                let filteredList = wordList.filter {
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
        WordEntry(number: 2, language: .english) { _ in

        }
    }
}
#endif
