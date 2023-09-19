//
//  MoyaProvider+Session.swift
//  Vault
//
//  Created by Ata Namvari on 2023-09-19.
//

import Moya

extension MoyaProvider where Target == API {
    func request(with session: Session, endpoint: API.Endpoint, completion: @escaping Moya.Completion) {
        request(session.target(for: endpoint), completion: completion)
    }

    func decodableRequest<T: Decodable>(with session: Session, endpoint: API.Endpoint, completion: @escaping (Result<T, MoyaError>) -> Void) {
        decodableRequest(session.target(for: endpoint), completion: completion)
    }
}

extension Session {
    func target(for endpoint: API.Endpoint) -> API {
        API(deviceKey: deviceKey, endpoint: endpoint)
    }
}
