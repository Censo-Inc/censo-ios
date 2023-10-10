//
//  Welcome.swift
//  Vault
//
//  Created by Ben Holzman on 10/10/23.
//

import SwiftUI

struct Welcome: View {
    @Environment(\.apiProvider) var apiProvider

    @RemoteResult<API.OwnerState, API> private var ownerStateResource

    var session: Session

    var body: some View {
        NavigationStack {
            Spacer()
            VStack(alignment: .leading) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 66)
                Text("welcome to censo")
                    .font(.system(size: 24))
                    .padding()
                Text("We built Censo to be a secure way to safeguard your seed phrases.\n\nComplete setup in 2 steps:")
                    .font(.system(size: 18))
                    .padding()
                
                VStack(alignment: .leading) {
                    SetupStep(
                        logoName: "faceid", heading: "Scan your face", content: "Fortify your Censo account with a live, industry-leading face scan.")
                    SetupStep(
                        logoName: "rectangle.and.pencil.and.ellipsis", heading: "Enter your seed phrase", content: "Add your seed phrase; Censo will shard & encrypt it for your eyes only")
                }
                .padding()
                
                NavigationLink {
                    ApproversSetup(
                        session: session,
                        onComplete: replaceOwnerState
                    )
                } label: {
                    Text("Get started")
                }
                .buttonStyle(RoundedButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                
                HStack {
                    Image(systemName: "info.circle")
                    Text("Learn more")
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
        }
    }
    
    
    private func replaceOwnerState(newOwnerState: API.OwnerState) {
        _ownerStateResource.replace(newOwnerState)
    }
}

struct SetupStep: View {
    var logoName: String
    var heading: String
    var content: String
    var body: some View {
        HStack(alignment: .center) {
            ZStack {
                Rectangle()
                    .fill(.gray)
                    .opacity(0.3)
                    .frame(width: 64, height: 64)
                    .cornerRadius(18)
                Image(systemName: logoName)
                    .resizable()
                    .frame(width: 36, height: 36)
            }
            VStack(alignment: .leading) {
                Text(heading)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .padding(.horizontal)
                Text(content)
                    .font(.system(size: 14))
                    .padding(.leading)
                    .padding(.top, 1)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.vertical)
    }
}

#Preview {
    Welcome(session: .sample)
}
