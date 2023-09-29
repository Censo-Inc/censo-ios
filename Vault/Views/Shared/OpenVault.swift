//
//  OpenVault.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-29.
//

import SwiftUI

struct OpenVault<Content>: View where Content : View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geometry in
            VStack {
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Spacer()

                        Rectangle()
                            .frame(height: 4)
                            .foregroundColor(.black)

                        Rectangle()
                            .frame(height: 65)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 0) {
                        Spacer()

                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(lineWidth: 4)
                            }
                            .frame(width: geometry.size.width / 3)
                    }
                }
                .frame(height: 150 + 40)
                .frame(maxWidth: .infinity)
                .background(Color.Censo.darkBlue)

                content()
            }
            .frame(maxWidth: .infinity)
        }
    }
}
