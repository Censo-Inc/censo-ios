//
//  SentrySDK+Extension.swift
//  Censo
//
//  Created by Brendan Flood on 1/3/24.
//

import Foundation
import Sentry

extension SentrySDK {
    static func captureWithTag(error: Error, tagValue: String) {
        Self.capture(error: error) {(scope) in
            scope.setTag(value: tagValue, key: "tag")
        }
    }
    
    static func addCrumb(category: String, message: String) {
        let crumb = Breadcrumb()
        crumb.level = SentryLevel.info
        crumb.category = category
        crumb.message = message
        Self.addBreadcrumb(crumb)
    }
}
