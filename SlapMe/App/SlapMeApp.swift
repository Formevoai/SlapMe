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
    @StateObject private var customPackManager = CustomPackManager()

    private let impactDetector = ImpactDetector()
    private let hapticManager = HapticManager()

    @AppStorage("onboarding_done") private var onboardingDone = false
    @State private var onboardingStep = 0
    @State private var showSplash = true
    @State private var prankData: PrankLaunchData? = nil
    @State private var pendingPrankData: PrankLaunchData? = nil

    private let categories: [SoundCategory] = SoundCategoryLoader.loadAll()
    private var allPacks: [SoundPack] { categories.flatMap { $0.packs } }

    private func findPack(id: String) -> SoundPack? {
        allPacks.first { $0.id == id }
            ?? customPackManager.packs.first(where: { $0.id == id })
            .map { customPackManager.toSoundPack($0) }
    }

    var body: some View {
        ZStack {
            if onboardingDone {
                HomeView(
                    settingsStore: settingsStore,
                    motionManager: motionManager,
                    audioManager: audioManager,
                    storeManager: storeManager,
                    customPackManager: customPackManager,
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
                    // Eğer splash açılırken prank linki geldiyse şimdi göster
                    if let pending = pendingPrankData {
                        pendingPrankData = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            prankData = pending
                        }
                    }
                }
                .zIndex(10)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: onboardingDone)
        .animation(.easeInOut(duration: 0.35), value: onboardingStep)
        .onChange(of: onboardingDone) { done in
            if !done { onboardingStep = 0 }
        }
        .onOpenURL { url in
            handlePrankURL(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            handleUniversalPrankURL(url)
        }
        .fullScreenCover(item: $prankData) { data in
            PrankLandingView(pack: data.pack, delay: data.delay, audioManager: audioManager) {
                prankData = nil
            }
        }
        .onAppear {
            audioManager.configureSession()
            audioManager.startSilentLoop()
            syncDetector()
            connectDetector()
            motionManager.startMonitoring()
            startBatteryMonitoring()
            // İlk pack yükle
            if let pack = findPack(id: settingsStore.settings.selectedPackID) {
                audioManager.loadPack(pack)
            }
        }
        .onChange(of: settingsStore.settings) { newSettings in
            syncDetector()
            // Pack sadece ID değişince yüklenir — slider/toggle fiddle etmesin
            if audioManager.currentPackID != newSettings.selectedPackID,
                let pack = findPack(id: newSettings.selectedPackID)
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
        guard let pack = findPack(id: chargerPackID) else { return }

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

    // MARK: - Prank URL Handling

    private func handlePrankURL(_ url: URL) {
        guard url.scheme == "slapme", url.host == "prank" else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let packID = comps?.queryItems?.first(where: { $0.name == "pack" })?.value ?? ""
        let delay = Int(comps?.queryItems?.first(where: { $0.name == "delay" })?.value ?? "5") ?? 5
        openPrank(packID: packID, delay: delay)
    }

    private func handleUniversalPrankURL(_ url: URL) {
        guard url.host == "formevoai.github.io",
            url.path.hasPrefix("/SlapMe/prank")
        else { return }
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let packID = comps?.queryItems?.first(where: { $0.name == "pack" })?.value ?? ""
        let delay = Int(comps?.queryItems?.first(where: { $0.name == "delay" })?.value ?? "5") ?? 5
        openPrank(packID: packID, delay: delay)
    }

    private func openPrank(packID: String, delay: Int) {
        guard let pack = findPack(id: packID) ?? allPacks.first else { return }
        let data = PrankLaunchData(
            id: "\(packID)_\(delay)_\(Date().timeIntervalSince1970)",
            pack: pack,
            delay: delay
        )
        if showSplash {
            // Splash hâlâ açık — kapandıktan sonra göster
            pendingPrankData = data
        } else {
            prankData = data
        }
    }
}

// MARK: - Prank Data Model

struct PrankLaunchData: Identifiable {
    let id: String
    let pack: SoundPack
    let delay: Int
}
