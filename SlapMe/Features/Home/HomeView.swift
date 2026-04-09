import SwiftUI

struct HomeView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var motionManager: MotionManager
    @ObservedObject var audioManager: AudioManager
    @ObservedObject var storeManager: StoreManager
    @ObservedObject var customPackManager: CustomPackManager
    @ObservedObject private var localizationManager = LocalizationManager.shared
    let impactDetector: ImpactDetector
    let hapticManager: HapticManager
    let packs: [SoundPack]
    let categories: [SoundCategory]

    @State private var isReacting = false
    @State private var lastIntensity: Double = 0
    @State private var screenFlash = false
    @State private var showSettings = false
    @State private var showPaywall = false
    @State private var showCreateCustom = false
    @AppStorage("onboarding_done") private var onboardingDone = true
    @State private var hasSlapped = false
    @State private var hintOpacity: Double = 0.6

    // Swipe state
    @State private var categoryIndex = 0
    @State private var characterIndex = 0
    @State private var continuousOffsetY: CGFloat = 0

    private var visibleCategories: [SoundCategory] {
        var result = categories.map { cat in
            SoundCategory(
                id: cat.id,
                title: cat.title,
                icon: cat.icon,
                isPremium: cat.isPremium,
                packs: cat.packs.filter { !$0.comingSoon }
            )
        }.filter { !$0.packs.isEmpty }
        result.append(customPackManager.toSoundCategory)
        return result
    }

    private var currentCategory: SoundCategory? {
        guard !visibleCategories.isEmpty, categoryIndex < visibleCategories.count else {
            return nil
        }
        return visibleCategories[categoryIndex]
    }

    private var currentPack: SoundPack? {
        guard let cat = currentCategory,
            !cat.packs.isEmpty,
            characterIndex < cat.packs.count
        else { return nil }
        return cat.packs[characterIndex]
    }

    private var isCurrentLocked: Bool {
        guard let pack = currentPack else { return false }
        return isPackLocked(pack)
    }

    private func isPackLocked(_ pack: SoundPack) -> Bool {
        guard !storeManager.isPremium else { return false }
        let cat = visibleCategories.first { $0.id == pack.categoryID }
        if pack.categoryID == "yamete" { return true }
        if pack.categoryID == "custom" { return true }  // tüm custom = pro
        if pack.categoryID == "sexy" { return pack.id != cat?.packs.first?.id }
        return false
    }

    private var flashColor: Color {
        switch currentCategory?.id ?? "" {
        case "sexy": return Color(red: 1, green: 0.4, blue: 0.7)
        case "yamete": return Color(red: 1, green: 0.6, blue: 0.8)
        case "goat": return .yellow
        case "funny": return .green
        default: return .white
        }
    }

    private var bgColor: Color { Color(white: 0.94) }
    private var textColor: Color { .black }
    private var secondaryTextColor: Color { .black.opacity(0.45) }
    private var cardBgColor: Color { .black.opacity(0.05) }
    private var borderColor: Color { .black.opacity(0.08) }
    private var pillBgColor: Color { .black.opacity(0.08) }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            // Impact flash
            if screenFlash {
                flashColor
                    .ignoresSafeArea()
                    .opacity(0.4)
                    .transition(.opacity)
            }

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 4)

                cardArea
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .padding(.vertical, 24)

                bottomSection
                    .padding(.bottom, 36)
            }
        }
        .preferredColorScheme(.light)
        .sheet(isPresented: $showSettings) {
            SettingsView(
                settingsStore: settingsStore, storeManager: storeManager, categories: categories)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(storeManager: storeManager)
        }
        .sheet(isPresented: $showCreateCustom) {
            CreateCustomCharacterView(customPackManager: customPackManager)
        }
        .onReceive(impactDetector.impactPublisher) { event in
            handleImpact(event)
        }
        .onAppear {
            // Find initial indices from selectedPackID
            syncIndicesFromSettings()
            if let pack = currentPack { audioManager.loadPack(pack) }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                hintOpacity = 0.25
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(spacing: 12) {
            // Action bar
            HStack(spacing: 0) {
                // PRO badge / buy button
                Button(action: { showPaywall = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: storeManager.isPremium ? "crown.fill" : "crown")
                            .font(.caption.weight(.bold))
                        if !storeManager.isPremium {
                            Text(L("pro_badge"))
                                .font(.system(size: 11, weight: .heavy))
                        }
                    }
                    .foregroundStyle(storeManager.isPremium ? .yellow : textColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(pillBgColor, in: Capsule())
                    .overlay(Capsule().stroke(borderColor, lineWidth: 1))
                }

                Spacer()

                // Help — reopen onboarding
                Button(action: { onboardingDone = false }) {
                    Image(systemName: "questionmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                        .padding(10)
                        .background(pillBgColor, in: Circle())
                        .overlay(Circle().stroke(borderColor, lineWidth: 1))
                }
                .padding(.trailing, 8)

                // Settings
                Button(action: { showSettings = true }) {
                    Image(systemName: "gearshape.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(textColor)
                        .padding(10)
                        .background(pillBgColor, in: Circle())
                        .overlay(Circle().stroke(borderColor, lineWidth: 1))
                }
            }

            // Logo
            HStack(spacing: 6) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [accentColor, accentColor.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .rotationEffect(.degrees(isReacting ? -30 : 12))
                    .scaleEffect(isReacting ? 1.15 : 1.0)
                    .animation(.interpolatingSpring(stiffness: 300, damping: 8), value: isReacting)

                Text("SlapMe")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [textColor, textColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
    }

    // MARK: - Card Area (modern carousel)

    private var accentColor: Color {
        switch currentCategory?.id ?? "" {
        case "sexy": return Color(red: 1, green: 0.35, blue: 0.65)
        case "yamete": return Color(red: 0.9, green: 0.4, blue: 0.7)
        case "goat": return Color(red: 1, green: 0.7, blue: 0.25)
        case "funny": return Color(red: 0.3, green: 0.85, blue: 0.4)
        default: return .blue
        }
    }

    // Continuous offsets drive both carousels smoothly
    @State private var continuousOffsetX: CGFloat = 0

    private var cardArea: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let cardWidth = width * 0.68
            let hSpacing = cardWidth + 14
            let vSpacing = height * 0.42

            ZStack {
                ForEach(0..<visibleCategories.count, id: \.self) { ci in
                    let isCurrent = ci == categoryIndex
                    let baseX = CGFloat(ci - categoryIndex) * hSpacing
                    let totalX = baseX + continuousOffsetX

                    // Only render if within visible range
                    if abs(CGFloat(ci - categoryIndex)) <= 2 {
                        let distFromCenter = abs(totalX) / hSpacing
                        let hScale = max(0.82, 1.0 - distFromCenter * 0.12)
                        let hOpacity = max(0.3, 1.0 - distFromCenter * 0.45)
                        let rotation = Double(totalX) * 0.012

                        let cat = visibleCategories[ci]
                        let totalChars = cat.packs.count

                        // Vertical character carousel (only for current category)
                        ZStack {
                            if isCurrent {
                                ForEach(0..<totalChars, id: \.self) { pi in
                                    let baseY = CGFloat(pi - characterIndex) * vSpacing
                                    let totalY = baseY + continuousOffsetY

                                    if abs(CGFloat(pi - characterIndex)) <= 2 {
                                        let vDist = abs(totalY) / vSpacing
                                        let vScale = max(0.85, 1.0 - vDist * 0.10)
                                        let vOpacity = max(0.3, 1.0 - vDist * 0.45)
                                        let vRotation = Double(totalY) * 0.015

                                        CharacterView(
                                            pack: cat.packs[pi],
                                            isReacting: pi == characterIndex ? isReacting : false,
                                            intensity: pi == characterIndex ? lastIntensity : 0,
                                            isLocked: isPackLocked(cat.packs[pi]),
                                            isBackground: pi != characterIndex,
                                            isComingSoon: cat.packs[pi].comingSoon,
                                            onLockTap: { showPaywall = true },
                                            onAddNewTap: { showCreateCustom = true }
                                        )
                                        .frame(width: cardWidth)
                                        .scaleEffect(vScale)
                                        .rotation3DEffect(
                                            .degrees(vRotation), axis: (x: 1, y: 0, z: 0),
                                            perspective: 0.4
                                        )
                                        .offset(y: totalY)
                                        .opacity(vOpacity)
                                        .zIndex(pi == characterIndex ? 1 : 0)
                                        .allowsHitTesting(pi == characterIndex)
                                    }
                                }
                            } else {
                                // Non-current categories: show first character only
                                CharacterView(
                                    pack: cat.packs[0],
                                    isReacting: false,
                                    intensity: 0,
                                    isLocked: isPackLocked(cat.packs[0]),
                                    isBackground: true,
                                    isComingSoon: cat.packs[0].comingSoon,
                                    onLockTap: { showPaywall = true },
                                    onAddNewTap: { showCreateCustom = true }
                                )
                                .frame(width: cardWidth)
                            }
                        }
                        .scaleEffect(hScale)
                        .rotation3DEffect(
                            .degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.4
                        )
                        .offset(x: totalX)
                        .opacity(hOpacity)
                        .zIndex(isCurrent ? 1 : 0)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        let h = value.translation.width
                        let v = value.translation.height

                        if abs(h) > abs(v) * 0.6 {
                            // Horizontal — category carousel
                            let raw = h
                            if (categoryIndex == 0 && raw > 0)
                                || (categoryIndex == visibleCategories.count - 1 && raw < 0)
                            {
                                continuousOffsetX = raw * 0.2
                            } else {
                                continuousOffsetX = raw
                            }
                            continuousOffsetY = 0
                        } else {
                            // Vertical — character carousel
                            let raw = v
                            let cat = visibleCategories[categoryIndex]
                            if (characterIndex == 0 && raw > 0)
                                || (characterIndex == cat.packs.count - 1 && raw < 0)
                            {
                                continuousOffsetY = raw * 0.2
                            } else {
                                continuousOffsetY = raw
                            }
                            continuousOffsetX = 0
                        }
                    }
                    .onEnded { value in
                        let h = value.translation.width
                        let v = value.translation.height
                        let hVel = value.predictedEndTranslation.width - h
                        let vVel = value.predictedEndTranslation.height - v

                        if abs(h) > abs(v) * 0.6 {
                            // Horizontal snap
                            let threshold: CGFloat = 50
                            let velThreshold: CGFloat = 200
                            let shouldSwipe = abs(h) > threshold || abs(hVel) > velThreshold
                            let dir = (h + hVel * 0.3) < 0 ? 1 : -1

                            if shouldSwipe {
                                let target = categoryIndex + dir
                                if target >= 0, target < visibleCategories.count {
                                    withAnimation(
                                        .interpolatingSpring(
                                            mass: 0.8, stiffness: 180, damping: 22,
                                            initialVelocity: -Double(hVel) * 0.003)
                                    ) {
                                        categoryIndex = target
                                        characterIndex = 0
                                        continuousOffsetX = 0
                                        continuousOffsetY = 0
                                    }
                                    onPackChanged()
                                } else {
                                    withAnimation(
                                        .interpolatingSpring(mass: 0.6, stiffness: 200, damping: 18)
                                    ) {
                                        continuousOffsetX = 0
                                    }
                                }
                            } else {
                                withAnimation(
                                    .interpolatingSpring(mass: 0.6, stiffness: 200, damping: 18)
                                ) {
                                    continuousOffsetX = 0
                                }
                            }
                        } else {
                            // Vertical snap
                            let threshold: CGFloat = 50
                            let velThreshold: CGFloat = 200
                            let shouldSwipe = abs(v) > threshold || abs(vVel) > velThreshold
                            let dir = (v + vVel * 0.3) < 0 ? 1 : -1

                            if shouldSwipe {
                                let cat = visibleCategories[categoryIndex]
                                let target = characterIndex + dir
                                if target >= 0, target < cat.packs.count {
                                    withAnimation(
                                        .interpolatingSpring(
                                            mass: 0.8, stiffness: 180, damping: 22,
                                            initialVelocity: -Double(vVel) * 0.003)
                                    ) {
                                        characterIndex = target
                                        continuousOffsetY = 0
                                    }
                                    onPackChanged()
                                } else {
                                    withAnimation(
                                        .interpolatingSpring(mass: 0.6, stiffness: 200, damping: 18)
                                    ) {
                                        continuousOffsetY = 0
                                    }
                                }
                            } else {
                                withAnimation(
                                    .interpolatingSpring(mass: 0.6, stiffness: 200, damping: 18)
                                ) {
                                    continuousOffsetY = 0
                                }
                            }
                        }
                    }
            )
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 14) {
            if !hasSlapped {
                HStack(spacing: 6) {
                    Text("👋")
                        .font(.subheadline)
                    Text(L("home_slap_hint"))
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(textColor.opacity(hintOpacity))
                .transition(.opacity)
            }

            // Safe mode toggle
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                    settingsStore.settings.safeModeEnabled.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(
                        systemName: settingsStore.settings.safeModeEnabled
                            ? "shield.fill" : "shield"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(
                        settingsStore.settings.safeModeEnabled ? .green : textColor.opacity(0.5))

                    Text(
                        settingsStore.settings.safeModeEnabled
                            ? L("safe_mode_on") : L("safe_mode_off")
                    )
                    .font(.caption.weight(.medium))
                    .foregroundStyle(textColor.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(pillBgColor, in: Capsule())
                .overlay(Capsule().stroke(borderColor, lineWidth: 1))
            }

            if settingsStore.settings.safeModeEnabled {
                Text(L("safe_mode_description"))
                    .font(.caption2)
                    .foregroundStyle(textColor.opacity(0.4))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Logic

    private func syncIndicesFromSettings() {
        let selectedID = settingsStore.settings.selectedPackID
        for (ci, cat) in visibleCategories.enumerated() {
            for (pi, pack) in cat.packs.enumerated() {
                if pack.id == selectedID {
                    categoryIndex = ci
                    characterIndex = pi
                    return
                }
            }
        }
        // Fallback: reset to first
        categoryIndex = 0
        characterIndex = 0
    }

    private func onPackChanged() {
        guard let pack = currentPack else { return }
        guard pack.id != "custom_add_new" else { return }
        settingsStore.settings.selectedPackID = pack.id
        if !isCurrentLocked {
            audioManager.loadPack(pack)
        }
    }

    private func handleImpact(_ event: ImpactEvent) {
        guard let pack = currentPack else { return }

        // Coming soon characters — no interaction
        if pack.comingSoon { return }

        // Add-new slotu — ses yok
        if pack.id == "custom_add_new" { return }

        // Gate premium content — sexy ilk karakter free, yamete tamamen PRO
        if isCurrentLocked {
            showPaywall = true
            return
        }

        audioManager.play(event: event, pack: pack)
        hapticManager.play(for: event)

        withAnimation(.spring(response: 0.15)) {
            isReacting = true
            lastIntensity = event.intensity
        }

        if !hasSlapped {
            withAnimation(.easeOut(duration: 0.4)) { hasSlapped = true }
        }

        if settingsStore.settings.screenFlashEnabled {
            withAnimation(.easeIn(duration: 0.05)) { screenFlash = true }
            withAnimation(.easeOut(duration: 0.15).delay(0.05)) { screenFlash = false }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation { isReacting = false }
        }
    }
}
