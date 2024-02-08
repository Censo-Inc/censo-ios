//
//  OwnerPill.swift
//  Approver
//
//  Created by Anton Onyshchenko on 03.01.24.
//

import Foundation
import SwiftUI

struct OwnerPill: View {
    var participantId: ParticipantId
    var label: String?
    var isSelected: Bool?
    var onEdit: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 0) {
            if let isSelected {
                if isSelected {
                    Image(systemName: "checkmark")
                        .resizable()
                        .symbolRenderingMode(.palette)
                        .frame(width: 12, height: 12)
                        .padding([.trailing], 24)
                } else {
                    Text("")
                        .padding(.trailing, 36)
                }
            }
            
            VStack(alignment: .leading) {
                Text(label ?? "-")
                    .font(.headline)
            }
            
            Spacer()
            
            if (onEdit != nil) {
                Button {
                    onEdit?()
                } label: {
                    Image("Pencil")
                        .renderingMode(.template)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
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

