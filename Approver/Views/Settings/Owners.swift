//
//  Owners.swift
//  Approver
//
//  Created by Anton Onyshchenko on 19.12.23.
//

import Foundation
import SwiftUI

struct Owners: View {
    @Environment(\.dismiss) var dismiss
    var session: Session
    @Binding var user: API.ApproverUser
    
    @State var labellingOwner: Owner?
    
    var body: some View {
        let owners = user.approverStates.map({ $0.toOwner() })
        
        NavigationView {
            VStack {
                Text("Who I'm Helping")
                    .font(.title2)
                    .bold()
                    .padding(.vertical)
                
                Text("You are helping these people keep their crypto safe:")
                    .font(.subheadline)
                    .padding(.vertical)
                    .fixedSize(horizontal: false, vertical: true)
                
                ScrollView {
                    VStack(spacing: 30) {
                        ForEach(Array(owners.enumerated()), id: \.offset) { i, owner in
                            OwnerPill(
                                participantId: owner.participantId,
                                label: owner.label,
                                onEdit: {
                                    labellingOwner = owner
                                }
                            )
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle(Text(""))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            })
        }
        .sheet(item: $labellingOwner) { owner in
            NavigationView {
                LabelOwner(
                    session: session,
                    participantId: owner.participantId,
                    label: owner.label,
                    onComplete: {
                        self.user = $0
                        self.labellingOwner = nil
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            self.labellingOwner = nil
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                })
            }
        }
    }
}

#if DEBUG
#Preview {
    @State var user = API.ApproverUser(approverStates: [
        .init(
            participantId: .random(),
            phase: .complete,
            ownerLabel: nil
        ),
        .init(
            participantId: .random(),
            phase: .complete,
            ownerLabel: "John Doe"
        )
    ])
    
    return NavigationView {
        Owners(
            session: .sample,
            user: $user
        )
    }
    .foregroundColor(.Censo.primaryForeground)
}
#endif
