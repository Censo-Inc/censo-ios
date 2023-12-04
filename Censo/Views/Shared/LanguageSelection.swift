//
//  LanguageSelection.swift
//  Censo
//
//  Created by Brendan Flood on 12/1/23.
//

import SwiftUI

struct LanguageSelection: View {
    var text: Text
    @Binding var languageId: UInt8
    
    var body: some View {
        Menu {
            Picker(selection: $languageId, label: Text("Select Language")) {
                ForEach(WordListLanguage.allCases.sorted { $0.displayName() > $1.displayName() }, id: \.self) { language in
                    Text("\(language.localizedDisplayName())\n\(language.displayName())").tag(language.toId())
                }
            }
        } label: {
            text
            .multilineTextAlignment(.leading)
            .foregroundColor(.black)
        }
    }
}

#if DEBUG
#Preview {
    LanguageSelection(text: Text("Pick your language"), languageId: .constant(1))
}
#endif
