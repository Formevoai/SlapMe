import Combine
import SwiftUI
import UIKit

@main
struct SlapMeApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

// MARK: - RootView (Onboarding / Home yönlendirmesi)

struct RootView: View {
    @StateObject private var settingsStore = SettingsStore()
    @StateObject private var motionManager = MotionManager()
    @StateObject private var audioManager = AudioManager()
    @StateObject private var storeManager = StoreManager()

    private let impactDetector = ImpactDetector()
    private let hapticManager = HapticManager()

    @AppStorage("onboarding_done") private var onboardingDone = false
    @State private var onboardingStep = 0
    @State private var showSplash = true

    private let categories: [SoundCategory] = SoundCategoryLoader.loadAll()
    private var allPacks: [SoundPack] { categories.flatMap { $0.packs } }

    var body: some View {
        ZStack {
            if onboardingDone {
                HomeView(
                    settingsStore: settingsStore,
                    motionManager: motionManager,
                    audioManager: audioManager,
                    storeManager: storeManager,
                    impactDetector: impactDetector,
                    hapticManager: hapticManager,
                    packs: allPacks,
                    categories: categories
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                onboardingFlow
            }

            if showSplash {
                SplashView {
                    showSplash = false
                }
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboardingDone)
        .animation(.easeInOut(duration: 0.35), value: onboardingStep)
        .onChange(of: onboardingDone) { done in
            if !done { onboardingStep = 0 }
        }
        .onAppear {
            audioManager.configureSession()
            audioManager.startSilentLoop()
            syncDetector()
            connectDetector()
            motionManager.startMonitoring()
            startBatteryMonitoring()
            // İlk pack yükle
            if let pack = allPacks.first(where: { $0.id == settingsStore.settings.selectedPackID })
            {
                audioManager.loadPack(pack)
            }
        }
        .onChange(of: settingsStore.settings) { newSettings in
            syncDetector()
            // Pack sadece ID değişince yüklenir — slider/toggle fiddle etmesin
            if audioManager.currentPackID != newSettings.selectedPackID,
                let pack = allPacks.first(where: { $0.id == newSettings.selectedPackID })
            {
                audioManager.loadPack(pack)
            }
        }
    }

    // MARK: - Onboarding Akışı

    @ViewBuilder
    private var onboardingFlow: some View {
        switch onboardingStep {
        case 0:
            WelcomeView(onContinue: {
                withAnimation(.easeInOut(duration: 0.35)) { onboardingStep = 1 }
            })
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .id("welcome")

        case 1:
            SensorCheckView(onContinue: {
                withAnimation(.easeInOut(duration: 0.35)) { onboardingStep = 2 }
            })
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .id("sensor")

        case 2:
            ReactionTestView(
                onContinue: {
                    withAnimation(.easeInOut(duration: 0.35)) { onboardingStep = 3 }
                },
                motionManager: motionManager,
                impactDetector: impactDetector,
                audioManager: audioManager,
                categories: categories
            )
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .id("reaction")
            .onAppear { syncDetector() }

        default:
            PackSelectionView(
                onFinish: { selectedID in
                    settingsStore.settings.selectedPackID = selectedID
                    if let pack = allPacks.first(where: { $0.id == selectedID }) {
                        audioManager.loadPack(pack)
                    }
                    withAnimation(.easeInOut(duration: 0.35)) { onboardingDone = true }
                },
                categories: categories,
                audioManager: audioManager
            )
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .id("packSelection")
        }
    }

    // MARK: - ImpactDetector Senkronizasyonu

    private func syncDetector() {
        let s = settingsStore.settings
        impactDetector.configure(
            sensitivity: s.sensitivity,
            cooldown: s.cooldown,
            safeMode: s.safeModeEnabled
        )
        // connect sadece onAppear'dan çağrılır, settings değişiminde tekrar bağlanma
        hapticManager.isEnabled = s.hapticsEnabled
        audioManager.masterVolume = Float(s.masterVolume)
        audioManager.dynamicVolume = s.dynamicVolume
    }

    private func connectDetector() {
        impactDetector.connect(to: motionManager)
    }

    // MARK: - Şarj Tespiti

    private func startBatteryMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [self] in
                self.handleChargerEvent()
            }
        }
    }

    @MainActor
    private func handleChargerEvent() {
        let state = UIDevice.current.batteryState
        guard state == .charging || state == .full,
            settingsStore.settings.chargerSoundEnabled
        else { return }

        let chargerPackID = settingsStore.settings.selectedPackID
        guard let pack = allPacks.first(where: { $0.id == chargerPackID }) else { return }

        let userIsPremium = storeManager.isPremium

        // Yamete tamamen PRO — PRO değilse çalma
        if pack.categoryID == "yamete" && !userIsPremium { return }

        // Sexy: sadece ilk görünür karakter free (trial 1 ses), geri kalanlar locked
        if pack.categoryID == "sexy" && !userIsPremium {
            let sexyCategory = categories.first(where: { $0.id == "sexy" })
            let freeCharacterID = sexyCategory?.packs.first(where: { !$0.comingSoon })?.id
            if pack.id == freeCharacterID {
                audioManager.playChargerSound(from: pack, isTrial: true)
            }
            return
        }

        // Free kategoriler — full erişim
        audioManager.playChargerSound(from: pack, isTrial: false)
    }
}
