import Foundation
import CoreMotion
import Combine
import UIKit

final class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    private let operationQueue = OperationQueue()
    private let updateInterval: TimeInterval = 1.0 / 100.0 // 100 Hz

    let magnitudePublisher = PassthroughSubject<Double, Never>()

    private(set) var isAvailable: Bool = false
    private var appStateObservers: [Any] = []

    init() {
        isAvailable = motionManager.isAccelerometerAvailable
        operationQueue.maxConcurrentOperationCount = 1
        operationQueue.qualityOfService = .userInteractive
        observeAppState()
    }

    deinit {
        appStateObservers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    func startMonitoring() {
        guard motionManager.isAccelerometerAvailable,
              !motionManager.isAccelerometerActive else { return }

        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: operationQueue) { [weak self] data, _ in
            guard let self, let data else { return }
            let magnitude = Self.highPassMagnitude(data.acceleration)
            self.magnitudePublisher.send(magnitude)
        }
    }

    func stopMonitoring() {
        motionManager.stopAccelerometerUpdates()
    }

    // MARK: - App State — arka plana geçince motion devam eder, foreground'a dönünce de

    private func observeAppState() {
        let bg = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            // Arka planda da devam et — audio session canlı tuttuğu için iOS izin verir
            if self?.motionManager.isAccelerometerActive == false {
                self?.startMonitoring()
            }
        }

        let fg = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            if self?.motionManager.isAccelerometerActive == false {
                self?.startMonitoring()
            }
        }

        appStateObservers = [bg, fg]
    }

    // MARK: - High-Pass Filter (yerçekimi bileşenini siler)
    private static var filterX: Double = 0
    private static var filterY: Double = 0
    private static var filterZ: Double = 0
    private static let kFilterFactor: Double = 0.1

    private static func highPassMagnitude(_ a: CMAcceleration) -> Double {
        filterX = a.x - (a.x * kFilterFactor + filterX * (1 - kFilterFactor))
        filterY = a.y - (a.y * kFilterFactor + filterY * (1 - kFilterFactor))
        filterZ = a.z - (a.z * kFilterFactor + filterZ * (1 - kFilterFactor))
        return sqrt(filterX * filterX + filterY * filterY + filterZ * filterZ)
    }
}
