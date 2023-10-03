//
//  RotatingTotpPinView.swift
//  Vault
//
//  Created by Brendan Flood on 10/2/23.
//

import SwiftUI

struct RotatingTotpPinView: View {
    
    var session: Session
    var currentDate: Date
    var deviceEncryptedTotpSecret: Base64EncodedString
    
    var body: some View {
        if let totpSecret = try? session.deviceKey.decrypt(data: deviceEncryptedTotpSecret.data) {
            HStack {
                Spacer()
                Text(TotpUtils.getOTP(date: currentDate, secret: totpSecret)).bold()
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(
                            Color.gray.opacity(0.5),
                            lineWidth: 5
                        )
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: TotpUtils.getPercentDone(date: currentDate))
                        .stroke(
                            Color.blue,
                            style: StrokeStyle(
                                lineWidth: 5,
                                lineCap: .round
                            )
                        )
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(TotpUtils.getRemainingSeconds(date: currentDate))")
                }
            }
        } else {
            EmptyView()
        }
    }
}

//#Preview {
//    RotatingTotpPinView(session:)
//}
