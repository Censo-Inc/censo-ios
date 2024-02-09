//
//  LimitedLengthString.swift
//  Censo
//
//  Created by Anton Onyshchenko on 06.11.23.
//

import Foundation

class LimitedLengthString: ObservableObject {
    var limit: Int
    @Published var value: String
    
    init(_ value: String, limit: Int) {
        self.value = value
        self.limit = limit
    }

    var isEmpty: Bool {
        get {
            return value.trimmingCharacters(in: .whitespaces).isEmpty
        }
    }
    
    var isTooLong: Bool {
        get {
            return value.count > limit
        }
    }
    
    var isValid: Bool {
        get {
            return !isEmpty && !isTooLong
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

class BeneficiaryNickname: LimitedLengthString {
    init(_ value: String = "") {
        super.init(value, limit: 20)
    }
}

class OwnerLabel: LimitedLengthString {
    init(_ value: String = "") {
        super.init(value, limit: 20)
    }
}
