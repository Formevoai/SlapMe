import Foundation
import Combine
import UIKit

final class ImpactDetector: ObservableObject {
    // Ayarlar — dışarıdan güncellenir
    var threshold: Double = 1.5       // g cinsinden minimum etki değeri
    var cooldown: TimeInterval = 0.8  // saniye
    var safeModeEnabled: Bool = false

    // Tespit edilen impact event'i yayınlar
    let impactPublisher = PassthroughSubject<ImpactEvent, Never>()

    private var cancellables = Set<AnyCancellable>()
    private var lastImpactTime: TimeInterval = 0
    private var peakBuffer: [Double] = []
    private let peakBufferSize = 5
    private let minJerk: Double = 0.3  // çok küçük titreşimleri filtreler

    // Bağlanılacak sensitivity (0.1...1.0) → threshold'a dönüşüm logaritmik
    func configure(sensitivity: Double, cooldown: TimeInterval, safeMode: Bool) {
        // sensitivity arttıkça threshold düşer (daha hassas)
        // range: sensitivity=0.1 → threshold=4.0g, sensitivity=1.0 → threshold=0.8g
        self.threshold = 4.0 - (sensitivity * 3.2)
        self.cooldown = cooldown
        self.safeModeEnabled = safeMode
    }

    func connect(to motionManager: MotionManager) {
        cancellables.removeAll()   // önceki subscription'ları iptal et
        motionManager.magnitudePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] magnitude in
                self?.process(magnitude: magnitude)
            }
            .store(in: &cancellables)
    }

    private func process(magnitude: Double) {
        // Safe mode: sadece foreground'da çalış (zaten uygulama önde olmalı)
        guard !safeModeEnabled || UIApplication.shared.applicationState == .active else { return }

        // Minimum jerk filtresi — çok küçük titreşimleri geç
        guard magnitude > minJerk else {
            peakBuffer.removeAll()
            return
        }

        // Peak buffer: lokal maksimum bul
        peakBuffer.append(magnitude)
        if peakBuffer.count > peakBufferSize {
            peakBuffer.removeFirst()
        }

        guard peakBuffer.count == peakBufferSize else { return }

        let midIndex = peakBufferSize / 2
        let midValue = peakBuffer[midIndex]

        // Lokal maksimum mu?
        let isLocalPeak = peakBuffer.prefix(midIndex).allSatisfy { $0 < midValue }
                       && peakBuffer.suffix(midIndex).allSatisfy { $0 < midValue }

        guard isLocalPeak else { return }
        guard midValue >= threshold else { return }

        // Cooldown kontrolü
        let now = Date().timeIntervalSince1970
        guard now - lastImpactTime >= cooldown else { return }
        lastImpactTime = now

        // Intensity hesapla: threshold ile maxG arasını 0...1'e normalize et
        let maxG: Double = 8.0
        let intensity = min((midValue - threshold) / (maxG - threshold), 1.0)
        let level = ImpactEvent.ImpactLevel.from(intensity: intensity)

        let event = ImpactEvent(
            timestamp: now,
            magnitude: midValue,
            intensity: intensity,
            level: level
        )

        peakBuffer.removeAll()
        impactPublisher.send(event)
    }
}

private extension ImpactEvent.ImpactLevel {
    static func from(intensity: Double) -> ImpactEvent.ImpactLevel {
        switch intensity {
        case 0.0 ..< 0.4:  return .soft
        case 0.4 ..< 0.75: return .medium
        default:            return .hard
        }
    }
}
