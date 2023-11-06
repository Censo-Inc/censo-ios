//
//  Login.swift
//  Censo
//
//  Created by Brendan Flood on 10/31/23.
//

import SwiftUI

struct Login: View {
    var onSuccess: () -> Void

    var body: some View {
        VStack {
            Spacer()

            HStack {
                Image("CensoText")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 104)
                    .padding([.top], 8)
                
                Text("approver")
                    .font(.system(size: 36, weight: .light))
                    .padding(.leading, 5)
            }

            Spacer()
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Welcome")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding([.horizontal, .bottom])
                
                
                Text("This app is for those who have been selected to assist someone in keeping their crypto safe using the Censo app.")
                    .font(.subheadline)
                    .padding(.horizontal)
            }
            .onAppear {
                setupAppearance()
            }
            
            VStack {
                AppleSignIn(onSuccess: onSuccess)
                
                Text("By tapping Sign in, you agree to our terms of use.")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.bottom)
                
                Divider()
                    .padding([.horizontal])
                
                LoginBottomLinks()
                
            }
        }
        
    }
    
    private func setupAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .black
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.black.withAlphaComponent(0.2)
        UIPageControl.appearance().backgroundStyle = UIPageControl.BackgroundStyle.minimal
    }
    
    private func imageWithOverlay(imageName: String) -> some View {
        ZStack {
            Rectangle()
                .fill(.gray)
                .opacity(0.3)
                .cornerRadius(18)
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 42, height: 42)
        }.frame(width: 64, height: 64)
    }
    
    private func imageAndTextView(_ imageView: some View, _ textLine1: String, _ textLine2: String) -> some View {
        VStack {
            imageView
            Text(textLine1)
                .font(.caption2)
                .fontWeight(.regular)
            Text(textLine2)
                .font(.caption2)
                .fontWeight(.regular)
        }
    }
}

#if DEBUG
struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login() {}
    }
}
#endif

