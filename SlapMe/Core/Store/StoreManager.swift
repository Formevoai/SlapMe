import StoreKit
import SwiftUI

@MainActor
final class StoreManager: ObservableObject {

    static let productID = "com.slapme.premium"

    @Published private(set) var isPremium = false
    @Published private(set) var product: Product?
    @Published private(set) var isPurchasing = false

    private var updateTask: Task<Void, Never>?

    init() {
        updateTask = listenForTransactions()
        Task {
            await loadProduct()
            await refreshStatus()
        }
    }

    deinit { updateTask?.cancel() }

    // MARK: - Public

    var priceText: String {
        product?.displayPrice ?? "€1,99"
    }

    func purchase() async {
        guard let product = product, !isPurchasing else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let tx) = verification {
                    isPremium = true
                    await tx.finish()
                }
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            // Purchase failed silently
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshStatus()
    }

    // MARK: - Private

    private func loadProduct() async {
        guard let products = try? await Product.products(for: [Self.productID]),
              let p = products.first else { return }
        product = p
    }

    private func refreshStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == Self.productID {
                isPremium = true
                return
            }
        }
    }

    private func listenForTransactions() -> Task<Void, Never> {
        let pid = Self.productID
        return Task.detached { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let tx) = result,
                   tx.productID == pid {
                    await MainActor.run { self?.isPremium = true }
                    await tx.finish()
                }
            }
        }
    }
}
