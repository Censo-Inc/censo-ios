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
            Text("Optional: Increase security")
                .font(.system(size: 18))
                .padding([.bottom], 1)
                .padding([.leading, .trailing], 32)
                .bold()
            Text("Invite trusted approvers")
                .font(.system(size: 24))
                .bold()
                .padding([.leading, .trailing], 32)
                .padding([.bottom], 12)
        
            Text("Invite up to two trusted approvers for an additional layer of security")
                .font(.system(size: 14))
                .padding([.bottom], 1)
                .padding([.leading, .trailing], 32)
            
            Text("You can use either your primary or your backup approver along with your face scan to access your seed phrases. They help you keep the key but can never unlock the door.")
                .font(.system(size: 14))
                .padding([.leading, .trailing], 32)
                .padding([.bottom], 12)
            
            
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
                Text("Skip this step")
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

#if DEBUG
#Preview {
    NavigationView {
        @State var ownerState1 = API.OwnerState.ready(.init(policy: .sample, vault: .sample, unlockedForSeconds: try! UnlockedDuration(value: 600)))
        ApproversIntro(ownerState: $ownerState1, onSkipped: { })
    }
}
#endif

