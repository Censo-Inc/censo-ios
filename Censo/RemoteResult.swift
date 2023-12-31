//
//  RemoteResult.swift
//  Approver
//
//  Created by Ata Namvari on 2023-09-13.
//

import SwiftUI
import Moya

@propertyWrapper
struct RemoteResult<Model, Target>: DynamicProperty where Model : Decodable, Target : Moya.TargetType {
    enum LoadingState {
        case idle
        case loading
        case success(Model)
        case failure(Error)
    }

    @State private var loadingState: LoadingState = .idle

    var wrappedValue: LoadingState {
        loadingState
    }

    func reload(with apiProvider: MoyaProvider<Target>, target: Target) {
        apiProvider.decodableRequest(target) { (result: Result<Model, MoyaError>) in
            switch result {
            case .success(let model):
                loadingState = .success(model)
            case .failure(let error):
                loadingState = .failure(error)
            }
        }
    }
    
    func reload<ResponseModel : Decodable>(with apiProvider: MoyaProvider<Target>, target: Target, adaptSuccess: @escaping (ResponseModel) -> Model) {
        apiProvider.decodableRequest(target) { (result: Result<ResponseModel, MoyaError>) in
            switch result {
            case .success(let model):
                loadingState = .success(adaptSuccess(model))
            case .failure(let error):
                loadingState = .failure(error)
            }
        }
    }
    
    func replace(_ newState: Model) {
        loadingState = .success(newState)
    }
}
