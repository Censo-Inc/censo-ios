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
    
    @State var labellingOwner: API.ApproverState?
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Owners")
                    .font(.title2)
                    .bold()
                    .padding(.vertical)
                
                Text("You are helping these people keep their crypto safe:")
                    .font(.subheadline)
                    .padding(.vertical)
                    .fixedSize(horizontal: false, vertical: true)
                
                ScrollView {
                    VStack(spacing: 30) {
                        ForEach(Array(user.approverStates.enumerated()), id: \.offset) { i, approverState in
                            OwnerPill(
                                participantId: approverState.participantId,
                                label: approverState.ownerLabel,
                                onEdit: {
                                    labellingOwner = approverState
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
        .sheet(item: $labellingOwner) { approverState in
            NavigationView {
                LabelOwner(
                    session: session,
                    participantId: approverState.participantId,
                    label: approverState.ownerLabel,
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

struct OwnerPill: View {
    var participantId: ParticipantId
    var label: String?
    var onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                Text(label ?? "-")
                    .font(.system(size: 24))
                    .bold()
            }
            
            Spacer()
            
            Button {
                onEdit()
            } label: {
                Image("Pencil")
                    .renderingMode(.template)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .overlay(
            RoundedRectangle(cornerRadius: 16.0)
                .stroke(Color.Censo.primaryForeground, lineWidth: 1)
        )
    }
}

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
