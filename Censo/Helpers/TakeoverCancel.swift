//
//  TakeoverCancel.swift
//  Censo
//
//  Created by Brendan Flood on 2/12/24.
//

import Foundation

func cancelTakeover(_ ownerRepository: OwnerRepository, _ ownerStateStoreController: OwnerStateStoreController, _ onFailure: @escaping (Error) -> Void) {
    ownerRepository.cancelTakeover() { result in
        switch result {
        case .success(let response):
            ownerStateStoreController.replace(response.ownerState)
        case .failure(let error):
            onFailure(error)
        }
    }
}
