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
            
            TabView {
                ForEach(0..<3, id: \.self) { i in
                    switch i {
                    case 0:
                        VStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 16.0)
                                .inset(by: 1)
                                .stroke(Color.Censo.gray95, lineWidth: 1)
                                .background(Color.Censo.gray252)
                                .frame(maxWidth: 322, minHeight: 160, maxHeight: 240)
                                .padding()

                            Text("Welcome, approvers")
                                .font(.system(size: 24, weight: .semibold))
                                .padding([.horizontal, .bottom])
                            
                            
                            Text("This app is for those who have been selected to approve another person’s seed phrase.")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal)
                        }
                    case 1:
                        VStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 16.0)
                                .inset(by: 1)
                                .stroke(Color.Censo.gray95, lineWidth: 1)
                                .background(Color.Censo.gray252)
                                .frame(maxWidth: 322, minHeight: 160, maxHeight: 240)
                                .padding()

                            Text("How it works")
                                .font(.system(size: 24, weight: .semibold))
                                .padding([.horizontal, .bottom])
                            
                            
                            Text("You will be given a link & six-digit code to enter to secure the phrase.")
                                .font(.system(size: 14, weight: .medium))
                                .padding(.horizontal)
                        }
                        
                    case 2:
                        VStack(alignment: .leading) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16.0)
                                    .inset(by: 1)
                                    .stroke(Color.Censo.gray95, lineWidth: 1)
                                    .background(Color.Censo.gray252)
                                    .frame(maxWidth: 322, minHeight: 160, maxHeight: 240)
                                    .padding()
                                HStack {
                                    Spacer()
                                    imageAndTextView(imageWithOverlay(imageName: "Censo"), "Censo", "")
                                    Spacer()
                                    imageAndTextView(Image("Plus"), "", "")
                                    Spacer()
                                    imageAndTextView(imageWithOverlay(imageName: "Censo"), "Censo", "Approver")
                                    Spacer()
                                }.frame(maxWidth: 322)
                            }

                            Text("Looking for Censo?")
                                .font(.system(size: 24, weight: .semibold))
                                .padding([.horizontal, .bottom])
                            
                            
                            Text("If you would like to secure your own seed phrase, download the main Censo app **here**.")
                                .font(.system(size: 14))
                                .padding(.horizontal)
                                .onTapGesture {
                                        UIApplication.shared.open(URL(string: "https://censo.co")!)
                                }
                        }
                    default:
                        EmptyView()
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
            .onAppear {
                setupAppearance()
            }
            
            VStack {
                AppleSignIn(onSuccess: onSuccess)
                
                Text("By tapping Sign in, you agree to our terms of use.")
                    .font(.system(size: 12, weight: .medium))
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
                .font(.system(size: 10, weight: .regular))
            Text(textLine2)
                .font(.system(size: 10, weight: .regular))
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

