import Foundation

final class ClipSelector {
    static func select(for event: ImpactEvent, from pack: SoundPack) -> String? {
        let pool: [String]
        switch event.level {
        case .soft:   pool = pack.softClips
        case .medium: pool = pack.mediumClips
        case .hard:   pool = pack.hardClips
        case .combo:  pool = pack.comboClips.isEmpty ? pack.hardClips : pack.comboClips
        }
        return pool.randomElement()
    }
}
