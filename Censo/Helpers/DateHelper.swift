//
//  DateHelper.swift
//  Censo
//
//  Created by Brendan Flood on 1/5/24.
//

import Foundation

extension Date {
    func toDisplayDuration() -> String {
        return formatTimelockDisplay(timeRemaining: self.timeIntervalSinceNow)
    }
}

extension Int {
    func toDisplayDuration() -> String {
        return formatTimelockDisplay(timeRemaining: Double(self))
    }
}

func formatTimelockDisplay(timeRemaining: TimeInterval) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    
    if timeRemaining >= 3600 {
        formatter.allowedUnits = [.hour]
    } else if timeRemaining > 60 {
        formatter.allowedUnits = [.minute]
    }
    let formattedTime = formatter.string(from: timeRemaining + TimeInterval(59))
    return formattedTime != nil ? "\(timeRemaining < 60 ? "less than 1 minute" : formattedTime!)" : ""
}
