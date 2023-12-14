//
//  LockScreen.swift
//  Censo
//
//  Created by Brendan Flood on 10/20/23.
//

import SwiftUI

struct LockScreen: View {
    
    var onReadyToAuthenticate: () -> Void

    var body: some View {
        GeometryReader { geometry in
            
            ZStack {
                
                VStack {
                    Spacer()
                    Image("DogSleeping")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width,
                               height: geometry.size.height * 0.3)
                        .ignoresSafeArea()
                }
                
                VStack {
                    Image("CensoLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100)
                    
                    Text("Welcome back.")
                        .font(.largeTitle)
                        .padding(.bottom, 1)
                        .bold()
                    
                    Rectangle()
                        .fill(Color.Censo.aquaBlue)
                        .frame(width: 39, height: 6)
                        .padding(.vertical, 10)
                    
                    Text("The Seed Phrase Manager that lets you sleep at night.")
                        .font(.largeTitle)
                        .bold()
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom)
                    
                    Button {
                        onReadyToAuthenticate()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Continue")
                            Spacer()
                        }
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .frame(maxWidth: 220)
                    
                    Spacer()
                }
                .padding([.horizontal, .top])
                .multilineTextAlignment(.center)
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationView {
        LockScreen(onReadyToAuthenticate: {})
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
