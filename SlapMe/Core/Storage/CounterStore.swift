import Foundation

final class CounterStore: ObservableObject {
    private let key = "lifetime_slap_count"

    @Published private(set) var count: Int

    init() {
        count = UserDefaults.standard.integer(forKey: key)
    }

    func increment() {
        count += 1
        UserDefaults.standard.set(count, forKey: key)
    }

    func reset() {
        count = 0
        UserDefaults.standard.set(0, forKey: key)
    }
}
