//
//  PieSegment.swift
//  Vault
//
//  Created by Ata Namvari on 2023-10-05.
//

import SwiftUI

struct PieSegment: Shape {
    var value: CGFloat

    var animatableData: Double {
        get {
            value
        }
        set {
            value = newValue
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.midX, startAngle: .degrees(-90), endAngle: .degrees(value * 360 - 90), clockwise: true)
        return path
    }
}
