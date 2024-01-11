//
//  Deeplink.swift
//  Censo
//
//  Created by imykolenko on 1/11/24.
//

import Foundation

class DeeplinkState: ObservableObject {
    static let shared = DeeplinkState()
    @Published var url: URL?

    func reset() {
        url = nil
    }
}
