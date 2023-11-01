//
//  AppSpecificError.swift
//  Censo
//
//  Created by Ben Holzman on 10/24/23.
//

import Foundation

extension Error {
    var appSpecificMessage: String {
        switch self as Error {
        case let facetecError as FacetecError:
            return facetecError.statusMessage
        default:
            return "Something went wrong"
        }
    }
}
