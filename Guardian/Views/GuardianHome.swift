//
//  Invitation.swift
//  Guardian
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI

enum  GuardianRoute {
    case initial
    case onboard
    case recovery
    case unknown
}


struct GuardianHome: View {
    @Binding var identifier: String
    var onValidateIdentifier: (GuardianRoute) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()

            Image(systemName: "person.line.dotted.person.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(50)

            Text("Please enter your identifier")
                .font(.title)

            TextField("Type here", text: $identifier)
                .font(.title2)

            Spacer()

            HStack {
                Button {
                    onValidateIdentifier(.recovery)
                } label: {
                    Text("Recover")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
                Button {
                    onValidateIdentifier(.onboard)
                } label: {
                    Text("Onboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButtonStyle())
            }
            .buttonStyle(.borderedProminent)
            .disabled(identifier.isEmpty)
        }
        .padding()
    }
}

#if DEBUG
struct Invitation_Previews: PreviewProvider {
    static var previews: some View {
        GuardianHome(identifier: .constant(""), onValidateIdentifier: {_ in})
    }
}
#endif
