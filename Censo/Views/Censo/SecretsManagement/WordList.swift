//
//  WordList.swift
//  Censo
//
//  Created by Brendan Flood on 10/27/23.
//

import SwiftUI

struct WordList: View {
    var words: [String]
    
    var body: some View {
        TabView {
            ForEach(0..<words.count, id: \.self) { i in
                VStack {
                    Group {
                        Text(NumberFormatter.ordinal.string(from: NSNumber(value: i + 1)) ?? "") + Text(" word")
                    }
                    .font(.title2)
                    .padding()

                    Text(words[i])
                        .padding()
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(lineWidth: 1)
                }
                .padding(20)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
    }
}

#Preview {
    WordList(words: ["sample", "word"])
}
