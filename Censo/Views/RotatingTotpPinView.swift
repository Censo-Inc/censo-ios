//
//  RotatingTotpPinView.swift
//  Censo
//
//  Created by Brendan Flood on 10/2/23.
//

import SwiftUI
import Base32

struct RotatingTotpPinView: View {
    var totpSecret: Data
    var style: Style
    
    enum Style {
        case owner
        case approver
        
        var pinFontSize: CGFloat {
            get {
                switch (self) {
                case .owner: return 28
                case .approver: return 48
                }
            }
        }
    }

    @State private var pin: String = ""
    @State private var timerPublisher = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    @State private var percentDone: Double = 0
    @State private var secondsRemaining: Int = 0
    
    private func detectColor() -> Color {
        switch (secondsRemaining) {
        case 0...20:
            return Color.Censo.countdownRed
        case 21...40:
            return Color.Censo.countdownYellow
        default:
            return Color.Censo.countdownGreen
        }
    }
    
    private func setProgress() {
        let date = Date()
        percentDone = TotpUtils.getPercentDone(date: date)
        secondsRemaining = TotpUtils.getRemainingSeconds(date: date)
    }
    
    struct Stack<Content: View>: View {
        let style: Style
        let content: () -> Content
        
        init(_ style: Style, @ViewBuilder _ content: @escaping () -> Content) {
            self.style = style
            self.content = content
        }
        
        var body: some View {
            switch (style) {
            case .owner: HStack(content: content)
            case .approver: VStack(content: content)
            }
        }
    }
        
    var body: some View {
        let pin = TotpUtils.getOTP(date: Date(), secret: totpSecret)
        let color = detectColor()
        
        Stack(style) {
            Text(pin.splittingCharacters(by: " "))
                .font(.system(size: style.pinFontSize, weight: .semibold))
                .padding(.horizontal)
            
            ZStack {
                Circle()
                    .stroke(
                        color.opacity(0.2),
                        lineWidth: 5
                    )
                    .frame(width: 36, height: 36)
                
                Circle()
                    .trim(from: 0, to: percentDone)
                    .stroke(
                        color,
                        style: StrokeStyle(
                            lineWidth: 5,
                            lineCap: .round
                        )
                    )
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                
                Text("\(secondsRemaining)")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(color)
            }
        }
        .onAppear {
            setProgress()
        }
        .onReceive(timerPublisher) { _ in
            withAnimation {
                setProgress()
            }
        }
    }
}

extension String {
    fileprivate func splittingCharacters(by char: Character) -> String {
        var returnString = self
        returnString.insert(char, at: index(startIndex, offsetBy: count / 2))
        returnString.insert(char, at: index(startIndex, offsetBy: count / 2))
        return returnString
    }
}

#if DEBUG
#Preview("owner style") {
    NavigationView {
        RotatingTotpPinView(
            totpSecret: base32DecodeToData(generateBase32())!,
            style: .owner
        )
    }
    .foregroundColor(Color.Censo.primaryForeground)
}

#Preview("approver style") {
    NavigationView {
        RotatingTotpPinView(
            totpSecret: base32DecodeToData(generateBase32())!,
            style: .approver
        )
    }
    .foregroundColor(Color.Censo.primaryForeground)
}
#endif
