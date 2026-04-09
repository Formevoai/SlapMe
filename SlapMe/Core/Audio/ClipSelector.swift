import Foundation

final class ClipSelector {
    static func select(for event: ImpactEvent, from pack: SoundPack) -> String? {
        return pack.clips.randomElement()
    }
}
