//
//  AuthEnrollmentView.swift
//  Censo
//
//  Created by Brendan Flood on 2/7/24.
//

import SwiftUI

struct AuthEnrollmentView: View {
    @Environment(\.dismiss) var dismiss
    
    @State var usePasswordAuth: Bool = false
    @State private var showLearnMore = false
    @State private var readyToStartEnrollment: Bool = false
    
    var onStartEnrollment: (() -> Void)?
    var onPasswordReady: (Base64EncodedString) -> Void
    var onFaceScanReady: FaceScanReadyCallback<API.AuthEnrollmentApiResponse>
    var onFaceScanSuccess: (API.OwnerState) -> Void
    var onBiometryCanceled: (() -> Void)?
    var onCancel: () -> Void
    var showAsBack = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if readyToStartEnrollment {
                if (usePasswordAuth) {
                    NavigationStack {
                        CreatePassword { cryptedPassword in
                            onPasswordReady(cryptedPassword)
                        }
                        .navigationInlineTitle("Create a password")
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                DismissButton(icon: .back, action: {
                                    onBiometryCanceled?()
                                    self.readyToStartEnrollment = false
                                    self.usePasswordAuth = false
                                })
                            }
                        }
                    }
                } else {
                    FacetecAuth<API.AuthEnrollmentApiResponse>(
                        onFaceScanReady: { facetecBiometry, completion in
                            onFaceScanReady(facetecBiometry, completion)
                        },
                        onSuccess: { response in
                            onFaceScanSuccess(response.ownerState)
                        },
                        onCancelled: {
                            onBiometryCanceled?()
                            dismiss()
                            self.readyToStartEnrollment = false
                        }
                    )
                }
            } else {
                GeometryReader { geometry in
                    ZStack(alignment: .bottomTrailing) {
                        VStack(alignment: .trailing) {
                            Image("FaceScanHandWithPhone")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: geometry.size.height * 0.9)
                                .padding(.top)
                            Spacer()
                        }
                        
                        VStack(spacing: 0) {
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text(try! AttributedString(markdown: "[To use the Censo App without biometric authentication, tap here to use a password instead.](#)"))
                                    .font(.subheadline)
                                    .tint(Color.Censo.primaryForeground)
                                    .multilineTextAlignment(.leading)
                                    .padding([.top])
                                    .fixedSize(horizontal: false, vertical: true)
                                    .environment(\.openURL, OpenURLAction { url in
                                        onStartEnrollment?()
                                        usePasswordAuth = true
                                        readyToStartEnrollment = true
                                        return .handled
                                    })
                                    .padding(.bottom)
                                    .accessibilityIdentifier("usePasswordLink")
                                
                                BeginFaceScanButton {
                                    onStartEnrollment?()
                                    readyToStartEnrollment = true
                                }
                                
                                Button {
                                    showLearnMore = true
                                } label: {
                                    HStack {
                                        Image(systemName: "info.circle")
                                        Text("Learn more")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.horizontal)
                            .padding(.horizontal)
                        }
                    }
                }
                .onboardingCancelNavBar(
                    navigationTitle: "Anonymously scan your face",
                    onCancel: onCancel,
                    showAsBack: showAsBack
                )
                .sheet(isPresented: $showLearnMore) {
                    LearnMore(title: "Face Scan & Privacy", showLearnMore: $showLearnMore) {
                        VStack {
                            Text("""
                        Censo uses a face scan to ensure your security and protect your privacy.  Any security actions you take with Censo require a face scan as one of the sources of authentication.
                        
                        Censo utilizes face technology built by facetec.com. Facetec’s certified liveness plus 3D face matching ensures that you and only you can access your seed phrases and make changes to your security.  Facetec provides over 2 billion 3D liveness checks annually.
                        
                        By utilizing Facetec rather than the biometrics on your mobile device, we can assure that you’ll never lose access to your seed phrases, even in the event you lose your mobile device or change the biometry on your phone.
                        
                        Censo maintains only an encrypted version of your face scan that can never be used to identify you or tied to your identity, although it does allow Censo to positively identify you as a user.
                        """
                            )
                            .padding()
                            
                        }
                    }
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    LoggedInOwnerPreviewContainer {
        NavigationView {
            AuthEnrollmentView(
                onStartEnrollment: {},
                onPasswordReady: {_ in},
                onFaceScanReady: {_, _ in},
                onFaceScanSuccess: {_ in},
                onBiometryCanceled: {},
                onCancel: {}                
            )
        }
    }
}
#endif
