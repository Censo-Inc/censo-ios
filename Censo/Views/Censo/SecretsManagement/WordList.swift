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
        VStack {
            TabView {
                ForEach(0..<words.count, id: \.self) { i in
                    VStack {
                        VStack(spacing: 0) {
                            Group {
                                Text(NumberFormatter.ordinal.string(from: NSNumber(value: i + 1)) ?? "") + Text(" word")
                            }
                            .font(.title2)
                            .padding()
                            
                            Text(words[i])
                                .padding()
                                .multilineTextAlignment(.center)
                                .font(.title)
                                .padding([.horizontal])
                        }
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(lineWidth: 1)
                        }
                        .padding([.top, .leading, .trailing], 20)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            Spacer()
                .frame(height: 20)
            Text("swipe back and forth to review words")
            Spacer()
                .frame(height: 50)
        }
    }
}

#Preview {
    WordList(words: ["sample", "word"])
}
