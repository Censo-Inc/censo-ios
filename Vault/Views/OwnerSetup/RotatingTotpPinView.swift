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
                Text(TotpUtils.getOTP(date: currentDate, secret: totpSecret).addDashToTotpCode()).bold()
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.Censo.lightGray)
                        .frame(width: 30, height: 30)
                    
                    ForEach(0...30, id: \.self) { num in
                        Circle()
                            .trim(from: 0, to: TotpUtils.getPercentDone(date: currentDate))
                            .stroke(
                                Color.white,
                                style: StrokeStyle(
                                    lineWidth: 1,
                                    lineCap: .round
                                )
                            )
                            .frame(width: 30-CGFloat(num), height: 30-CGFloat(num))
                            .rotationEffect(.degrees(-90))
                    }
                }
            }
        }
    }
}


