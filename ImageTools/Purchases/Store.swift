import Foundation
import RevenueCat

/// Entitlement state, backed by RevenueCat. The paywall itself is configured in the
/// RevenueCat dashboard and rendered by RevenueCatUI — this type only answers
/// "is this user Pro" and keeps the answer fresh.
@MainActor
@Observable
final class Store {
    static let shared = Store()

    /// Apple **public** SDK key: RevenueCat → Project settings → API keys → App Store.
    /// It ships in the binary by design and is not a secret, unlike the v1 secret key.
    private static let apiKey = "appl_REPLACE_WITH_REVENUECAT_APPLE_KEY"

    /// Entitlement identifier as spelled in the RevenueCat dashboard.
    static let entitlement = "pro"

    private(set) var isPro = false

    /// False until the first customer info lands, so a subscriber never sees the paywall flash.
    private(set) var isLoaded = false

    /// The SDK runs only with a real key. Without one the app stays unlocked: a binary built
    /// with the placeholder is a build mistake, and failing open keeps it from being a brick
    /// (it also keeps the simulator usable before the key exists).
    private(set) var isConfigured = false

    var isLocked: Bool { isConfigured && isLoaded && !isPro }

    private init() {}

    func configure() {
        guard Self.apiKey.hasPrefix("appl_"), !Self.apiKey.contains("REPLACE") else {
            isLoaded = true
            return
        }
        Purchases.logLevel = .warn
        Purchases.configure(withAPIKey: Self.apiKey)
        isConfigured = true

        // The stream replays the cached info immediately, so subscribers unlock offline too.
        Task { [weak self] in
            for await info in Purchases.shared.customerInfoStream {
                self?.apply(info)
            }
        }
        // If the network is slow and nothing is cached, stop waiting and show the paywall.
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(3))
            self?.isLoaded = true
        }
    }

    private func apply(_ info: CustomerInfo) {
        isPro = info.entitlements[Self.entitlement]?.isActive == true
        isLoaded = true
    }
}
