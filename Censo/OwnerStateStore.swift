//
//  OwnerStateStore.swift
//  Censo
//
//  Created by Anton Onyshchenko on 29.01.24.
//

import Foundation

final class OwnerStateStore : ObservableObject {
    private var ownerRepository: OwnerRepository
    private var session: Session
    
    enum LoadingState {
        case idle
        case loading
        case success(API.OwnerState)
        case failure(Error)
    }

    @Published private(set) var loadingState: LoadingState = .idle
    
    init(_ ownerRepository: OwnerRepository, _ session: Session) {
        self.ownerRepository = ownerRepository
        self.session = session
    }
   
    func replace(_ newState: API.OwnerState) {
        loadingState = .success(newState)
    }
    
    func reload() {
        ownerRepository.getUser { result in
            switch result {
            case .success(let result):
                self.loadingState = .success(result.ownerState)
            case .failure(let error):
                self.loadingState = .failure(error)
            }
        }
    }
    
    func controller() -> OwnerStateStoreController {
        return OwnerStateStoreController(replace: self.replace, reload: self.reload)
    }
}

final class OwnerStateStoreController : ObservableObject {
    private(set) var replace: (API.OwnerState) -> Void
    private(set) var reload: () -> Void
    
    init(replace: @escaping (API.OwnerState) -> Void, reload: @escaping () -> Void) {
        self.replace = replace
        self.reload = reload
    }
}
