//
//  CensoTheme.swift
//  Censo
//
//  Created by Ata Namvari on 2023-08-09.
//

import SwiftUI

extension Color {
    struct Censo {
        
        static let darkBlue = Color(red: 05/255, green: 47/255, blue: 105/255)
        static let aquaBlue = Color(red: 71/255, green: 247/255, blue: 247/255)
        static let gray = Color(red: 165/255, green: 178/255, blue: 180/255)
        
        static let gray95 = Color(red: 242/255, green: 242/255, blue: 242/255)
        static let gray224 = Color(red: 224/255, green: 224/255, blue: 224/255)
        static let gray252 = Color(red: 252/255, green: 252/255, blue: 252/255)
        
        static let countdownGreen = Color(red: 0/255, green: 216/255, blue: 144/255)
        static let countdownYellow = Color(red: 255/255, green: 191/255, blue: 0/255)
        static let countdownRed = Color(red: 230/255, green: 109/255, blue: 87/255)
        
        
        static let primaryBackground = Color("background")
        static let primaryForeground = darkBlue
        
        static let buttonTextColor = aquaBlue
        static let buttonBackgroundColor = darkBlue
        
        static let green = Color("buttonGreen")
        
        static let lightGray = Color(red: 235/255, green: 245/255, blue: 246/255) //Color("lightGray")
    }
}

extension UIColor {
    struct Censo {
        static let darkBlue = UIColor(Color.Censo.darkBlue)
        static let aquaBlue = UIColor(Color.Censo.aquaBlue)
        static let primaryForeground = UIColor(Color.Censo.primaryForeground)
        
        static let buttonTextColor = UIColor(Color.Censo.buttonTextColor)
        static let buttonBackgroundColor = UIColor(Color.Censo.buttonBackgroundColor)
    }
}
