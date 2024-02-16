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
    
    func toDisplayDurationWithDays() -> String {
        return formatTimelockDisplay(timeRemaining: self.timeIntervalSinceNow, showInDays: true)
    }
}

extension Int {
    func toDisplayDuration() -> String {
        return formatTimelockDisplay(timeRemaining: Double(self))
    }
}

extension UInt64 {
    func millisToDisplayDuration() -> String {
        return formatTimelockDisplay(timeRemaining: Double(self) / 1000)
    }
}

func formatTimelockDisplay(timeRemaining: TimeInterval, showInDays: Bool = false) -> String {
    let formatter = DateComponentsFormatter()
    formatter.unitsStyle = .full
    
    var adjustment = TimeInterval(59)
    if timeRemaining >= 86400 && showInDays {
        formatter.allowedUnits = [.day]
        adjustment = 86399
    } else if timeRemaining >= 3600 {
        formatter.allowedUnits = [.hour]
        adjustment = 3599
    } else if timeRemaining > 60 {
        formatter.allowedUnits = [.minute]
    }
    let formattedTime = formatter.string(from: timeRemaining + adjustment)
    return formattedTime != nil ? "\(timeRemaining < 60 ? "less than 1 minute" : formattedTime!)" : ""
}
