//
//  Word.swift
//  Censo
//
//  Created by Ata Namvari on 2023-10-19.
//

import SwiftUI

struct Word: View {
    var number: Int

    @Binding var word: String

    var deleteWord: () -> Void

    @State private var showingEdit = false
    @State private var confirmDelete = false

    var body: some View {
        VStack {
            VStack {
                Group {
                    Text(NumberFormatter.ordinal.string(from: NSNumber(value: number)) ?? "") + Text(" word")
                }
                .font(.title2)
                .padding()

                Text(word)
                    .padding()
                    .multilineTextAlignment(.center)
                    .font(.title)
                    .padding()

                HStack {
                    Button {
                        showingEdit = true
                    } label: {
                        Image(systemName: "pencil")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25)
                            .foregroundColor(.gray)
                            .bold()
                    }
                    .padding()

                    Button {
                        confirmDelete = true
                    } label: {
                        Image(systemName: "trash")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25)
                            .foregroundColor(.gray)
                            .bold()
                    }
                    .padding()
                }
            }
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(lineWidth: 1)
            }
            .padding(20)
        }
        .sheet(isPresented: $showingEdit, content: {
            WordEntry(number: number) { newWord in
                showingEdit = false
                self.word = newWord
            }
        })
        .alert("Delete word", isPresented: $confirmDelete) {
            Button(role: .destructive, action: {
                deleteWord()
            }) {
                Text("Yes")
            }
        } message: {
            Text("Are you sure you want to delete this word?")
        }
    }
}

extension NumberFormatter {
    static var ordinal: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter
    }()
}

#if DEBUG
struct Word_Previews: PreviewProvider {
    static var previews: some View {
        Word(number: 3, word: .constant("sample"), deleteWord: {})
    }
}
#endif
