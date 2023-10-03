//
//  RotatingTotpPinView.swift
//  Vault
//
//  Created by Brendan Flood on 10/2/23.
//

import SwiftUI

struct RotatingTotpPinView: View {
    var session: Session
    var deviceEncryptedTotpSecret: Base64EncodedString

    @State private var pin: String = ""
    @State private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var percentDone: Double = 0

    var body: some View {
        if let totpSecret = try? session.deviceKey.decrypt(data: deviceEncryptedTotpSecret.data) {
            let pin = TotpUtils.getOTP(date: Date(), secret: totpSecret)

            HStack {
                Text(pin.splitingCharacters(by: "-"))
                    .font(.title)
                    .foregroundColor(.Censo.darkBlue)

                PieSegment(value: percentDone)
                    .frame(width: 16)
                    .foregroundColor(.Censo.lightGray)
                    .animation(.linear(duration: 1), value: percentDone)
            }
            .onReceive(timerPublisher) { _ in
                withAnimation {
                    percentDone = TotpUtils.getPercentDone(date: Date())
                }
            }

        } else {
            Text("Error") // this can be handled somewhere else I believe, this is almost an unrecoverable error
        }
    }
}

extension String {
    fileprivate func splitingCharacters(by char: Character) -> String {
        var returnString = self
        returnString.insert("-", at: index(startIndex, offsetBy: count / 2))
        return returnString
    }
}
