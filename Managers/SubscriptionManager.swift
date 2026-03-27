import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    @Published var isPremiumUser: Bool = false
    private var updateListenerTask: Task<Void, Never>?

    init() {
        startListeningForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    func fetchProducts() async throws -> [Product] {
        let productIDs: Set<String> = [
            "com.example.vpnapp.premium.monthly",
            "com.example.vpnapp.premium.yearly"
        ]

        return try await Product.products(for: productIDs)
    }

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(_):
                isPremiumUser = true
            case .unverified(_, _):
                throw NSError(
                    domain: "IAP",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Purchase could not be verified."]
                )
            }

        case .userCancelled:
            break

        case .pending:
            break

        @unknown default:
            break
        }
    }

    private func startListeningForTransactions() {
        updateListenerTask = Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()

                    if [
                        "com.example.vpnapp.premium.monthly",
                        "com.example.vpnapp.premium.yearly"
                    ].contains(transaction.productID) {
                        isPremiumUser = true
                    }
                } catch {
                    print("Transaction update error: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
