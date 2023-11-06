//
//  LimitedLengthString.swift
//  Censo
//
//  Created by Anton Onyshchenko on 06.11.23.
//

import Foundation

class LimitedLengthString: ObservableObject {
    private var limit: Int
    @Published var value: String {
        didSet {
            if value.count > limit {
                value = String(value.prefix(limit))
            }
        }
    }
    
    init(_ value: String, limit: Int) {
        self.value = value
        self.limit = limit
    }

    var isEmpty: Bool {
        get {
            return value.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
}

class PhraseLabel: LimitedLengthString {
    init(_ value: String = "") {
        super.init(value, limit: 50)
    }
}

class ApproverNickname: LimitedLengthString {
    init(_ value: String = "") {
        super.init(value, limit: 20)
    }
}
