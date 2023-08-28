//
//  AsyncResult.swift
//  Vault
//
//  Created by Ata Namvari on 2023-08-15.
//

import SwiftUI

protocol Loadable {
    associatedtype Value
    func load(_ completion: @escaping (Result<Value, Error>) -> ())
}

@propertyWrapper
struct AsyncResult<Value>: DynamicProperty {
    @State var content: Content = .idle

    var wrappedValue: Value? {
        switch content {
        case .success(let value):
            return value
        default:
            return nil
        }
    }

    var projectedValue: Content {
        content
    }

    enum Content {
        case idle
        case loading
        case success(Value)
        case failure(Error)
    }

    func reload<L>(using loader: L) where L : Loadable, L.Value == Value {
        self.content = .loading

        loader.load { result in
            switch result {
            case .success(let value):
                self.content = .success(value)
            case .failure(let error):
                self.content = .failure(error)
            }
        }
    }
}
