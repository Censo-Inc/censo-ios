//
//  ReplaceAuthentication.swift
//  Censo
//
//  Created by Anton Onyshchenko on 25.01.24.
//

import Foundation
import SwiftUI
import Moya

struct ReplaceAuthentication : View {
    @EnvironmentObject var ownerRepository: OwnerRepository
    
    var authType: AuthType
    var onComplete: (API.OwnerState) -> Void
    var onCancel: () -> Void
    
    @State private var showingError = false
    @State private var error: Error?
    
    enum AuthType {
        case facetec
        case password
    }
    
    enum Step {
        case initial
        case replace(newAuthType: AuthType)
        case done(API.OwnerState)
    }
    @State private var step: Step = .initial
    
    var body : some View {
        switch (step) {
        case .initial:
            GeometryReader { geometry in
                ZStack(alignment: .bottomTrailing) {
                    VStack(alignment: .trailing) {
                        Image("FaceScanHandWithPhone")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: geometry.size.height * 0.7)
                            .padding(.top)
                        Spacer()
                    }
                    
                    VStack(spacing: 0) {
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text(authType == .password ? "Replace your password" : "Replace your face scan")
                                .fixedSize(horizontal: false, vertical: true)
                                .font(.title3)
                                .bold()
                            
                            if authType == .password {
                                Text("Consider replacing your forgotten password with biometric authentication")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical)
                                
                                BeginFaceScanButton {
                                    step = .replace(newAuthType: .facetec)
                                }
                                
                                Button {
                                    step = .replace(newAuthType: .password)
                                } label: {
                                    Text("I want to keep using passwords")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .padding(.vertical)
                                .frame(maxWidth: .infinity)
                            } else {
                                Text("Your face scan will be replaced and immediately available for accessing your seed phrases. The previous face scan will be permanently removed from our storage.")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.vertical)
                                
                                BeginFaceScanButton {
                                    step = .replace(newAuthType: .facetec)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        onCancel()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        case .replace(newAuthType: AuthType.password):
            CreatePassword { cryptedPassword in
                ownerRepository.replaceAuthentication(API.ReplaceAuthenticationApiRequest(
                    authentication: .password(.init(cryptedPassword: cryptedPassword))
                )) { result in
                    switch result {
                    case .success(let response):
                        step = .done(response.ownerState)
                    case .failure(let error):
                        showError(error)
                    }
                }
            }
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        step = .initial
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
            })
            .alert("Error", isPresented: $showingError, presenting: error) { _ in
                Button {
                    showingError = false
                    error = nil
                } label: {
                    Text("OK")
                }
            } message: { error in
                Text(error.localizedDescription)
            }
        case .replace(newAuthType: AuthType.facetec):
            FacetecAuth<API.ReplaceBiometryApiResponse>(
                onFaceScanReady: { facetecBiometry, completion in
                    ownerRepository.replaceAuthentication(
                        API.ReplaceAuthenticationApiRequest(
                            authentication: .facetecBiometry(facetecBiometry)
                        ),
                        completion
                    )
                },
                onSuccess: { response in
                    step = .done(response.ownerState)
                },
                onCancelled: {
                    step = .initial
                }
            )
        case .done(let ownerState):
            VStack {
                ZStack {
                    Image("AccessApproved")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .padding(.top)
                    
                    VStack(alignment: .center) {
                        Spacer()
                        Text("You are all set!")
                            .font(.system(size: UIFont.textStyleSize(.largeTitle) * 1.5, weight: .medium))
                        Spacer()
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    onComplete(ownerState)
                }
            })
        }
    }
    
    private func showError(_ error: Error) {
        self.showingError = true
        self.error = error
    }
}

#if DEBUG
#Preview("biometry") {
    LoggedInOwnerPreviewContainer {
        NavigationStack {
            ReplaceAuthentication(
                authType: .facetec,
                onComplete: { _ in },
                onCancel: {}
            )
            .navigationTitle("Biometry Reset")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}


#Preview("password") {
    LoggedInOwnerPreviewContainer {
        NavigationStack {
            ReplaceAuthentication(
                authType: .password,
                onComplete: { _ in },
                onCancel: {}
            )
            .navigationTitle("Password Reset")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}
#endif
