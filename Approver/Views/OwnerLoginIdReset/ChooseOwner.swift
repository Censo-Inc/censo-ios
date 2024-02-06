//
//  ChooseOwner.swift
//  Approver
//
//  Created by Anton Onyshchenko on 04.01.24.
//

import Foundation
import SwiftUI

struct ChooseOwner: View {
    @Environment(\.dismiss) var dismiss
    var owners: [Owner]
    @State private var selectedOwner: Owner?
    var onContinue: (Owner) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Please select the person that has contacted you:")
                .font(.subheadline)
                .padding(.vertical)
                .fixedSize(horizontal: false, vertical: true)
            
            List {
                VStack(spacing: 30) {
                    ForEach(Array(owners.enumerated()), id: \.offset) { i, owner in
                        Button {
                            selectedOwner = owner
                        } label: {
                            OwnerPill(
                                participantId: owner.participantId,
                                label: owner.label,
                                isSelected: selectedOwner?.participantId == owner.participantId
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .listRowSeparator(.hidden)
                .padding()
            }
            .listStyle(.plain)
            .scrollIndicators(ScrollIndicatorVisibility.hidden)
            
            Divider()
            
            Button {
                if let selectedOwner {
                    onContinue(selectedOwner)
                }
            } label: {
                Text("Continue")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(RoundedButtonStyle())
            .disabled(selectedOwner == nil)
            .padding(.vertical)
        }
        .padding(.top)
        .padding(.horizontal, 32)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
            }
        }
    }
}

