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
    @State private var secondsRemaining: Int = 0

    var body: some View {
        if let totpSecret = try? session.deviceKey.decrypt(data: deviceEncryptedTotpSecret.data) {
            let pin = TotpUtils.getOTP(date: Date(), secret: totpSecret)

            HStack {
                Text(pin.splittingCharacters(by: " "))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.black)
                    .padding()
                
                ZStack {
                    Circle()
                        .stroke(
                            Color.Censo.countdownColor.opacity(0.2),
                            lineWidth: 5
                        )
                        .frame(width: 36, height: 36)

                    Circle()
                        .trim(from: 0, to: percentDone)
                        .stroke(
                            Color.Censo.countdownColor,
                            style: StrokeStyle(
                                lineWidth: 5,
                                lineCap: .round
                            )
                        )
                        .frame(width: 36, height: 36)
                        .rotationEffect(.degrees(-90))

                    Text("\(secondsRemaining)")
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.Censo.countdownColor)
                }
            }
            .onReceive(timerPublisher) { _ in
                withAnimation {
                    let date = Date()
                    percentDone = TotpUtils.getPercentDone(date: date)
                    secondsRemaining = TotpUtils.getRemainingSeconds(date: date)
                }
            }

        } else {
            Text("Error") // this can be handled somewhere else I believe, this is almost an unrecoverable error
        }
    }
}

extension String {
    fileprivate func splittingCharacters(by char: Character) -> String {
        var returnString = self
        returnString.insert(char, at: index(startIndex, offsetBy: count / 2))
        return returnString
    }
}
