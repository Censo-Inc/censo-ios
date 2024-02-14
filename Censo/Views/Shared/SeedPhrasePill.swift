//
//  Approver.swift
//  Censo
//
//  Created by Ben Holzman on 10/26/23.
//

import SwiftUI

struct SeedPhrasePill: View {
    var seedPhrase: API.SeedPhrase
    var index: Int?
    var isSelected: Bool?
    var showSelectedCheckmark: Bool = false
    var strikeThrough: Bool = false
    var isDisabled: Bool = false
    var onEdit: (() -> Void)?

    func iconName() -> String {
        return switch seedPhrase.type {
        case .binary:
            "character.textbox"
        case .photo:
            "photo"
        }
    }
    
    var body: some View {
        HStack {
            Image(systemName: iconName())
                .resizable()
                .scaledToFit()
                .frame(height: 42)
                .foregroundColor(isDisabled ? .Censo.gray : isSelected == true ? .Censo.green : .Censo.primaryForeground)
                .padding(.leading)
            
            VStack(alignment: .leading) {
                Text(seedPhrase.label)
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.leading)
                    .foregroundColor(isDisabled ? .Censo.gray : isSelected == true ? .Censo.green : .Censo.primaryForeground)
                    .padding(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .strikethrough(strikeThrough)
            }
            
            if (onEdit != nil) {
                Button {
                    onEdit?()
                } label: {
                    HStack {
                        Spacer()
                        Image("Pencil")
                            .renderingMode(.template)
                            .foregroundColor(isDisabled ? .Censo.gray : isSelected == true ? .Censo.green : .Censo.primaryForeground)
                    }
                }
                .accessibilityIdentifier("seedPhraseEdit\(index ?? 0)Button")
                .padding([.trailing], 10)
                .fixedSize()
            }
            if (showSelectedCheckmark) {
                if (isSelected == true) {
                    Image(systemName: "checkmark")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.Censo.green)
                        .font(.system(size: 20))
                        .padding([.trailing], 10)
                } else {
                    Spacer()
                        .padding([.trailing], 10)
                        .fixedSize()
                }
            }
            
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets())
        .frame(maxWidth: .infinity, minHeight: 100, maxHeight: 100)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected == true ? Color.Censo.primaryForeground : Color.gray, lineWidth: 1)
                .opacity(isDisabled ? 0.5 : 1.0)
        )
    }
}

#if DEBUG
#Preview {
    VStack {
        SeedPhrasePill(seedPhrase: API.SeedPhrase(guid: "", seedPhraseHash: .sample, label: "Editable", type: .binary, createdAt: Date()), onEdit: {})
        SeedPhrasePill(seedPhrase: API.SeedPhrase(guid: "", seedPhraseHash: .sample, label: "Editable", type: .binary, createdAt: Date()), isDisabled: true, onEdit: {})
        SeedPhrasePill(seedPhrase: API.SeedPhrase(guid: "", seedPhraseHash: .sample, label: "Not editable", type: .photo, createdAt: Date()), isSelected: true, showSelectedCheckmark: true)
        SeedPhrasePill(seedPhrase: API.SeedPhrase(guid: "", seedPhraseHash: .sample, label: "A VERY LONG LABEL WITH EXACTLY FIFTY CHARACTERS!!!", type: .binary, createdAt: Date()), isSelected: true, showSelectedCheckmark: true, isDisabled: true, onEdit: {})
    }
    .padding()
    .foregroundColor(Color.Censo.primaryForeground)
}
#endif
    
