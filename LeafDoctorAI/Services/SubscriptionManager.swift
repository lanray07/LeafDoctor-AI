import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var plan: SubscriptionPlan = .free
    @Published var isActive = false
    @Published var renewsAt: Date?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let monthlyProductID = "leafdoctor.pro.monthly"
    let yearlyProductID = "leafdoctor.pro.yearly"
    let lifetimeProductID = "leafdoctor.premium.lifetime"

    var productIDs: [String] {
        [monthlyProductID, yearlyProductID]
    }

    var statusText: String {
        isActive ? "\(plan.rawValue) active" : "Free plan"
    }

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
            await refreshEntitlements()
        } catch {
            errorMessage = "Unable to load subscription products. Please try again later."
        }
    }

    func purchase(_ product: Product, using purchaseAction: (Product) async throws -> Product.PurchaseResult) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await purchaseAction(product)
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                apply(transaction: transaction)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlements()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshEntitlements() async {
        var foundActiveEntitlement = false

        for await result in Transaction.currentEntitlements {
            guard let transaction = try? checkVerified(result) else { continue }
            apply(transaction: transaction)
            foundActiveEntitlement = true
        }

        if !foundActiveEntitlement {
            plan = .free
            isActive = false
            renewsAt = nil
        }
    }

    private func apply(transaction: Transaction) {
        isActive = transaction.revocationDate == nil
        renewsAt = transaction.expirationDate

        switch transaction.productID {
        case monthlyProductID, yearlyProductID:
            plan = .pro
        case lifetimeProductID:
            plan = .lifetime
        default:
            plan = .free
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

private enum SubscriptionError: Error {
    case failedVerification
}
