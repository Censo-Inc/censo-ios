//
//  InfoBoard.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-25.
//

import SwiftUI

struct InfoBoard<Content>: View where Content : View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            content()
                .frame(maxWidth: .infinity)
                .padding(30)
        }
        .background {
            RoundedRectangle(cornerRadius: 4)
                .stroke(style: .init(lineWidth: 1))
                .foregroundColor(.Censo.lightGray)
                .shadow(color: .black, radius: 4, x: 0, y: 2)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .foregroundColor(.white)
                }
        }
        .foregroundColor(.Censo.gray)
        .padding()
    }
}
