//
//  ApproversIntro.swift
//  Vault
//
//  Created by Brendan Flood on 10/16/23.
//

import SwiftUI

struct ApproversIntro: View {
    @Binding var ownerState: API.OwnerState
    var onSkipped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            
            Spacer()
            VStack(alignment: .leading) {
                Text("Step 3")
                    .font(.system(size: 18))
                    .padding(.bottom, 1)
                    .bold()
                Text("Invite trusted approvers")
                    .font(.system(size: 24))
                    .bold()
            }
            .padding()
            
            VStack(alignment: .leading) {
                Text("Invite trusted approvers for an additional layer of security. They help you keep the key but can never unlock the door.")
                    .font(.system(size: 14))
                    .padding(.bottom, 1)
                
            }
            .padding()
            
            
            Button {
                
            } label: {
                HStack {
                    Spacer()
                    Image("TwoPeopleWhite")
                        .resizable()
                        .frame(width: 36, height: 36)
                    Text("Invite approvers")
                    Spacer()
                }
            }
            .buttonStyle(RoundedButtonStyle())
            .padding()
            .frame(maxWidth: .infinity)
            
            Button {
                onSkipped()
            } label: {
                HStack {
                    Spacer()
                    Text("Skip this step")
                    Image("SkipForward")
                        .resizable()
                        .frame(width: 36, height: 36)
                    Spacer()
                }
            }
            .buttonStyle(RoundedButtonStyle(tint: .gray95))
            .padding()
            .frame(maxWidth: .infinity)
            
            HStack {
                Image(systemName: "info.circle")
                Text("Learn more")
            }
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(Text(""))
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                BackButton()
            }
        }
    }
}

#Preview {
    NavigationView {
        @State var ownerState1 = API.OwnerState.guardianSetup(.init(guardians: [], threshold: 1, unlockedForSeconds: 180))
        ApproversIntro(ownerState: $ownerState1, onSkipped: { })
    }
}

