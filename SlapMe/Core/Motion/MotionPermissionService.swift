import Foundation
import CoreMotion

/// README'deki MotionPermissionService.
/// iOS'ta akselerometre için kullanıcı izni gerekmez (CMMotionActivityManager'dan farklı).
/// Bu servis cihaz uyumluluğunu kontrol eder ve simulator tespiti yapar.
final class MotionPermissionService {
    static let shared = MotionPermissionService()
    private let motionManager = CMMotionManager()

    private init() {}

    var isAccelerometerAvailable: Bool {
        motionManager.isAccelerometerAvailable
    }

    var isRunningOnSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }

    /// Sensör kullanılabilir ve gerçek cihazda mı çalışıyor
    var isReadyForDetection: Bool {
        isAccelerometerAvailable && !isRunningOnSimulator
    }
}
