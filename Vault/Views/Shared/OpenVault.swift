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
            ZStack {
                VStack {
                    ZStack(alignment: .bottom) {
                        VStack(spacing: 0) {
                            Spacer()

                            Rectangle()
                                .frame(height: 4)
                                .foregroundColor(.black)
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
                                .offset(y: 60)
                        }
                    }
                    .frame(height: 130)
                    .frame(maxWidth: .infinity)
                    .background(Color.Censo.darkBlue)

                    Spacer()
                }
                .zIndex(1)

                VStack {
                    Spacer()
                        .frame(height: 130)

                    content()
                        .safeAreaInset(edge: .top) {
                            Spacer()
                                .frame(height: 65)
                        }
                }
                .zIndex(0)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

