//
//  PhraseView.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

struct PhraseView: View {
    @State private var page = 0
    @State private var pagesVisited: Set<Int> = [0]

    var name: String
    var createdAt: Date
    var phrase: [String]

    var startIndex: Int {
        page * 3
    }

    var endIndex: Int {
        (page + 1) * 3
    }

    var allPagesVisited: Bool {
        pagesVisited.count == phrase.count / 3
    }

    var body: some View {
        VStack (alignment: .leading){
            Text("Added on \(DateFormatter.mediumFormatter.string(from: createdAt))")
                .padding(20)
                .foregroundColor(.gray)

            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 30) {
                        ForEach(startIndex..<endIndex, id: \.self) { i in
                            HStack(alignment: .center, spacing: 30) {
                                Text("\(i + 1)")
                                    .font(.system(size: 16, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: 20)

                                HStack {
                                    Text(phrase[i])
                                        .font(.system(size: 22, design: .monospaced))
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding(25)
                .padding([.leading, .trailing], 20)
                .background(Color.black.opacity(0.5).border(Color(white: 0.1), width: 1))
                .padding([.leading, .trailing], 50)
                .padding([.bottom, .top], 30)

                Text("Showing \(startIndex + 1)-\(endIndex) of \(phrase.count)")
                    .foregroundColor(.init(white: 0.5))
                    .padding()
            }

            HStack {
                Button {
                    if page == 0 {
                        page = (phrase.count / 3) - 1
                    } else {
                        page = (page - 1) % (phrase.count / 3)
                    }

                    pagesVisited.insert(page)
                } label: {
                    HStack {
                        Image(systemName: "arrowtriangle.left.fill")

                        Text("Previous")
                    }
                }
                .accessibilityIdentifier("previousWordSetButton")

                Spacer()

                Button {
                    page = (page + 1) % (phrase.count / 3)

                    pagesVisited.insert(page)
                } label: {
                    HStack {
                        Text("Next")

                        Image(systemName: "arrowtriangle.right.fill")
                    }
                }
                .accessibilityIdentifier("nextWordSetButton")
            }
            .buttonStyle(PlainButtonStyle())
            .padding(20)

            Spacer()
        }
        .navigationTitle(Text(name))
        .buttonStyle(FilledButtonStyle())
        .foregroundColor(.Censo.primaryForeground)
    }
}

#if DEBUG
struct PhraseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PhraseView(name: "Test", createdAt: Date(), phrase: ["these", "are", "test", "words", "they", "go", "on", "and", "on", "until", "there", "is", "no", "more", "these", "are", "test", "words", "they", "go", "on", "and", "on", "until"])
        }
    }
}
#endif
