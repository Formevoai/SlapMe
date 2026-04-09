import Foundation

final class ClipSelector {
    static func select(for event: ImpactEvent, from pack: SoundPack) -> String? {
        let pool = (pack.softClips + pack.mediumClips + pack.hardClips + pack.comboClips)
            .uniqued()
        return pool.randomElement()
    }
}

extension Array where Element: Hashable {
    fileprivate func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
