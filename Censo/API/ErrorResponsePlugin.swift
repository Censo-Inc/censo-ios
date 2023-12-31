//
//  ErrorResponsePlugin.swift
//  Censo
//
//  Created by Brendan Flood on 9/28/23.
//

import Foundation
import Moya

struct ErrorResponsePlugin: Moya.PluginType {

    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Moya.Response, MoyaError> {
        switch (result, target) {
        case (.success(let response), _)  where response.statusCode == 422:
            debugPrint(response)
            return .failure(self.parseValidationError(response: response))
        case (.success(let response), _)  where response.statusCode == 418:
            debugPrint(response)
            return .failure(MoyaError.underlying(CensoError.underMaintenance, nil))
        case (.success(let response), _) where response.statusCode == 403:
            return .failure(MoyaError.underlying(CensoError.unauthorized, nil))
        case (.success(let response), _) where response.statusCode == 404:
            return .failure(MoyaError.underlying(CensoError.resourceNotFound, nil))
        case (.success(let response), _) where response.statusCode == 401:
            return result
        case (.success(let response), _) where response.statusCode == 426:
            return .failure(MoyaError.underlying(CensoError.upgradeRequired, nil))
        case (.success(let response), _) where response.statusCode >= 400:
            return .failure(MoyaError.statusCode(response))
        default:
            return result
        }
    }
                            
    private func parseValidationError(response: Response) -> MoyaError {
        let validationError = (try? JSONDecoder().decode(API.ResponseErrors.self, from: response.data))?.errors.first
        if let scanResultBlob = validationError?.scanResultBlob {
            return MoyaError.underlying(
                CensoError.biometricValidation(
                    message: validationError?.message ?? "Biometric Validation Error",
                    scanResultBlob: scanResultBlob
                ),
                response
            )
        }
        return MoyaError.underlying(
            CensoError.validation(
                validationError?.message ?? "Validation Error"
            ),
            response
        )
    }
}
