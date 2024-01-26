//
//  PaywallGatedScreen.swift
//  Censo
//
//  Created by Anton Onyshchenko on 14.11.23.
//

import Foundation
import SwiftUI
import StoreKit
import Moya
import Sentry
import CryptoKit

struct PaywallGatedScreen<Content: View>: View {
    @Environment(\.apiProvider) var apiProvider
    
    var session: Session
    @Binding var ownerState: API.OwnerState
    var ignoreSubscriptionRequired = false
    var onCancel: () -> Void
    @ViewBuilder var content: () -> Content
    
    private let productIds = [
        Configuration.appStoreMonthlyProductId,
        Configuration.appStoreYearlyProductId
    ]
    
    @State private var monthlyOffer: Product?
    @State private var yearlyOffer: Product?

    enum ActionInProgress {
        case loadingProduct
        case purchase(Product)
        case restorePurchases
    }
    
    @State private var actionInProgress: ActionInProgress?
    @State private var error: Error?
    
    @State private var appStoreTransactionUpdatesTask: _Concurrency.Task<Void, Never>? = nil
    
    var body: some View {
        Group {
            if ownerState.subscriptionStatus == .active || (ownerState.subscriptionStatus == .none && !ownerState.subscriptionRequired && !ignoreSubscriptionRequired) {
                content()
            } else {
                if let actionInProgress {
                    if let error {
                        RetryView(error: error, action: {
                            self.error = nil
                            switch (actionInProgress) {
                            case .loadingProduct: loadProduct()
                            case .purchase(let product): purchase(product)
                            case .restorePurchases: restorePurchases()
                            }
                        })
                    } else {
                        switch (actionInProgress) {
                        case .loadingProduct:
                            ProgressView()
                        case .purchase:
                            ProgressView("Processing your subscription")
                        case .restorePurchases:
                            ProgressView("Restoring your subscription")
                        }
                    }
                } else if let monthlyOffer, let yearlyOffer {
                    Paywall(monthlyOffer: monthlyOffer,
                            yearlyOffer: yearlyOffer,
                            purchase: purchase,
                            restorePurchases: restorePurchases,
                            codeRedeemed: {}
                    )
                    .onboardingCancelNavBar(onboarding: ownerState.onboarding, onCancel: onCancel)
                } else {
                    ProgressView()
                        .onAppear() { loadProduct() }
                }
            }
        }
        .onAppear {
            self.appStoreTransactionUpdatesTask = observeAppStoreTransactionUpdates()
        }
        .onDisappear {
            self.appStoreTransactionUpdatesTask?.cancel()
        }
    }
    
    private func loadProduct() {
        actionInProgress = .loadingProduct
        _Concurrency.Task {
            do {
                let products = try await Product.products(for: productIds)
                guard let monthlyProduct = products.first(where: { product in product.subscription?.subscriptionPeriod.unit == .month &&
                       product.subscription?.subscriptionPeriod.value == 1}),
                      let yearlyProduct = products.first(where: { product in
                          product.subscription?.subscriptionPeriod.unit == .year &&
                          product.subscription?.subscriptionPeriod.value == 1
                      }) else {
                    throw CensoError.productNotFound
                }
                monthlyOffer = monthlyProduct
                yearlyOffer = yearlyProduct
                actionInProgress = .none
            } catch {
                showError(error)
            }
        }
    }
    
    private func purchase(_ product: Product) {
        actionInProgress = .purchase(product)
        _Concurrency.Task {
#if INTEGRATION
            do {
                let fakeTransactionId = "app_\(session.userCredentials.userIdentifierHash())_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
                try await submitPurchaseToBackend(
                    session,
                    fakeTransactionId,
                    AppStore.Environment.sandbox
                )
                actionInProgress = nil
            } catch {
                showError(error)
            }
#else
            do {
                let result = try await product.purchase()
                
                switch result {
                case let .success(.verified(transaction)):
                    try await submitPurchaseToBackend(session, String(transaction.originalID), transaction.environment)
                    await transaction.finish()
                    actionInProgress = nil
                case .success(.unverified):
                    throw CensoError.purchaseFailed
                case .pending:
                    break
                case .userCancelled:
                    actionInProgress = nil
                @unknown default:
                    actionInProgress = nil
                }
            } catch {
                showError(error)
            }
#endif
        }
    }
    
    private func showError(_ error: Error) {
        self.error = error
    }
    
    private func observeAppStoreTransactionUpdates() -> _Concurrency.Task<Void, Never> {
        _Concurrency.Task(priority: .background) {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else {
                    continue
                }

#if INTEGRATION
                await transaction.finish()
#else
                do {
                    try await submitPurchaseToBackend(session, String(transaction.originalID), transaction.environment)
                    await transaction.finish()
                } catch {
                    showError(error)
                }
#endif
            }
        }
    }
    
    private func submitPurchaseToBackend(_ session: Session, _ originalId: String, _ environment: AppStore.Environment) async throws {
        ownerState = try await withCheckedThrowingContinuation { continuation in
            apiProvider.decodableRequest(
                with: session,
                endpoint: .submitPurchase(API.SubmitPurchaseApiRequest(
                    purchase: API.SubmitPurchaseApiRequest.Purchase(
                        originalTransactionId: originalId,
                        environment: environment.rawValue
                    )
                ))
            ) { (result: Result<API.SubmitPurchaseApiResponse, MoyaError>) in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response.ownerState)
                case .failure(let error):
                    SentrySDK.captureWithTag(error: error, tagValue: "Submit Purchase")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func restorePurchases() {
        actionInProgress = .restorePurchases
        _Concurrency.Task {
            do {
                try await AppStore.sync()
                actionInProgress = nil
            } catch {
                showError(error)
            }
        }
    }
}

struct Paywall: View {
    var monthlyOffer: Product
    var yearlyOffer: Product
    var purchase: (Product) -> Void
    var restorePurchases: () -> Void
    var codeRedeemed: () -> Void
    @State private var displayRedemptionSheet = false
    @State private var displayError = false
    @State private var error = ""

    func monthFormatter() -> DateComponentsFormatter {
        let monthFormatter = DateComponentsFormatter()
        monthFormatter.allowedUnits = [.month]
        monthFormatter.unitsStyle = .full
        return monthFormatter
    }

    func priceFormatter(locale: Locale) -> NumberFormatter {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = locale
        return priceFormatter
    }

    func percentChange(yearlyPrice: Decimal, monthlyPrice: Decimal) -> String? {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 0
        return formatter.string(for: (100.0 * ((monthlyPrice * 12) - yearlyPrice) / (monthlyPrice * 12)))
    }

    func localizedMonth() -> String {
        let oneMonthText = monthFormatter().string(from: DateComponents(month: 1))
        if let r = try? Regex("\\s*1\\s*") {
            return oneMonthText?.replacing(r, with: "") ?? "month"
        } else {
            return "month"
        }
    }
    
    var body: some View {
        VStack {
            Spacer().frame(maxHeight: 75)
            ZStack(alignment: .top) {
                Color("AquaBackground")
                Image("CensoLogo")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .offset(x: 0, y: -50)
                VStack {
                    Spacer().frame(maxHeight: 75)
                    HStack {
                        Text("Secure all your Seed Phrases for good.\nAccess and retrieval anytime.")
                            .font(.title)
                            .fontWeight(.medium)
                            .padding([.horizontal], 20)
                            .padding(.bottom)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }

                    Spacer()
                    
                    Button {
                        purchase(yearlyOffer)
                    } label: {
                        VStack {
                            Text("\(yearlyOffer.displayPrice) / \(yearlyOffer.subscription!.subscriptionPeriod.formatted())")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .accessibilityIdentifier("purchaseButton")
                    .padding([.horizontal], 20)

                    
                    if let monthsText = monthFormatter().string(from: DateComponents(month: 12)),
                       let monthlyPrice = priceFormatter(locale: yearlyOffer.priceFormatStyle.locale).string(from: yearlyOffer.price / 12 as NSNumber)
                    {
                        
                        if let pctChange = percentChange(yearlyPrice: yearlyOffer.price, monthlyPrice: monthlyOffer.price) {
                            Text("\(monthsText) **at \(monthlyPrice) / \(localizedMonth())** - save \(pctChange)%")
                                .font(.subheadline)
                        } else {
                            Text("\(monthsText) **at \(monthlyPrice) / \(localizedMonth())**")
                                .font(.subheadline)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        purchase(monthlyOffer)
                    } label: {
                        VStack {
                            Text("\(monthlyOffer.displayPrice) / \(monthlyOffer.subscription!.subscriptionPeriod.formatted())")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(RoundedButtonStyle())
                    .accessibilityIdentifier("purchaseButton")
                    .padding([.horizontal], 20)

                    Button {
                        displayRedemptionSheet = true
                    } label: {
                        Text("Redeem Code")
                            .fontWeight(.semibold)
                    }
                    .padding()
                }
                .padding()

            }

            Spacer().frame(maxHeight: 50)

            HStack {
                Link(destination: Configuration.termsOfServiceURL, label: {
                    Text("Terms")
                        .font(.headline)
                        .fontWeight(.semibold)
                })
                
                Text("|")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Link(destination: Configuration.privacyPolicyURL, label: {
                    Text("Privacy")
                        .fontWeight(.semibold)
                })
                
                Text("|")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Button {
                    restorePurchases()
                } label: {
                    Text("Restore Purchases")
                        .fontWeight(.semibold)

                }
            }
        }
        .offerCodeRedemption(isPresented: $displayRedemptionSheet) { result in
            switch (result) {
            case .success:
                codeRedeemed()
            case .failure(let err):
                SentrySDK.captureWithTag(error: err, tagValue: "Redeem Code")
                displayError = true
                error = err.localizedDescription
            }
        }
        .alert("Error", isPresented: $displayError) {
            Button {
                displayError = false
                error = ""
            } label: { Text("OK") }
        } message: {
            Text(error)
        }
    }
}

private extension Product.SubscriptionInfo {
    func trialPeriod() -> Product.SubscriptionPeriod? {
        guard let introductoryOffer,
              introductoryOffer.paymentMode == Product.SubscriptionOffer.PaymentMode.freeTrial
        else {
            return nil
        }
        
        return introductoryOffer.period
    }
}

private extension Product.SubscriptionPeriod {
    func formatted() -> String {
        switch (self.unit) {
        case .day:
            if value == 1 {
                return "day"
            } else {
                return "\(self.value) days"
            }
        case .week:
            if value == 1 {
                return "7 days"
            } else {
                return "\(self.value) weeks"
            }
        case .month:
            if value == 1 {
                return "month"
            } else {
                return "\(self.value) months"
            }
        case .year:
            if value == 1 {
                return "year"
            } else {
                return "\(self.value) years"
            }
        @unknown default:
            fatalError()
        }
    }
}

#if DEBUG
import Moya

#Preview {
    @State var ownerState = API.OwnerState.initial(.init(authType: .facetec, entropy: .sample, subscriptionStatus: .none, subscriptionRequired: true))
    
    return PaywallGatedScreen(
        session: .sample,
        ownerState: $ownerState,
        onCancel: {}
    ) {
        Text("Behind the paywall")
    }.foregroundColor(.Censo.primaryForeground)
}
#endif
