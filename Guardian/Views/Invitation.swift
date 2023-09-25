//
//  Invitation.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI

struct Invitation: View {
    @Binding var inviteCode: String
    var onValidateCode: () -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            Image(systemName: "person.line.dotted.person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(50)

            Text("Please enter your invite code")
                .font(.title)

            TextField("Type here", text: $inviteCode)
                .font(.title2)

            Spacer()

            HStack {
                Button {
                    onValidateCode()
                } label: {
                    Text("Proceed")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
            }
            .buttonStyle(.borderedProminent)
            .disabled(inviteCode.isEmpty)
        }
        .padding()
    }
}

#if DEBUG
struct Invitation_Previews: PreviewProvider {
    static var previews: some View {
        Invitation(inviteCode: .constant(""), onValidateCode: {})
    }
}
#endif
