import AVFoundation
import Foundation

final class AudioManager: ObservableObject {
    // Engine hiçbir zaman yeniden oluşturulmaz — sadece node'lar değişir.
    private let engine = AVAudioEngine()
    private var playerNodes: [String: AVAudioPlayerNode] = [:]
    private var audioBuffers: [String: AVAudioPCMBuffer] = [:]

    // Arka planda iOS'un uygulamayı öldürmemesi için sessiz loop
    private let silentNode = AVAudioPlayerNode()
    private var silentBuffer: AVAudioPCMBuffer?
    private var silentLoopAttached = false

    var masterVolume: Float = 1.0
    var dynamicVolume: Bool = true

    // MARK: - Audio Session

    func configureSession() {
        let session = AVAudioSession.sharedInstance()
        // .playback: silent switch bypass eder + arka planda ses çalar
        try? session.setCategory(.playback, mode: .default, options: [])
        try? session.setActive(true)

        // Kesintilerden (telefon, Siri) sonra engine'i yeniden başlat
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: session
        )
    }

    @objc private func handleInterruption(_ notification: Notification) {
        guard let info = notification.userInfo,
              let typeValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue)
        else { return }

        if type == .ended {
            try? AVAudioSession.sharedInstance().setActive(true)
            ensureEngineRunning()
            if silentLoopAttached && !silentNode.isPlaying {
                scheduleSilentLoop()
            }
        }
    }

    private(set) var currentPackID: String?

    // MARK: - Pack Yükleme

    func loadPack(_ pack: SoundPack) {
        // Aynı pack zaten yüklüyse tekrar yükleme
        if currentPackID == pack.id && !playerNodes.isEmpty { return }
        currentPackID = pack.id

        // Engine'i durdur — dururken node attach/detach güvenilir şekilde yapılır
        engine.stop()

        // Eski player node'larını ayır (silentNode'a dokunma!)
        playerNodes.values.forEach { engine.detach($0) }
        playerNodes.removeAll()
        audioBuffers.removeAll()

        // Yeni clip'leri yükle
        var seen = Set<String>()
        let clips = (pack.softClips + pack.mediumClips + pack.hardClips + pack.comboClips + [pack.previewClip])
            .filter { seen.insert($0).inserted }
        for clip in clips {
            preload(clip: clip, soundFolder: pack.soundFolder)
        }

        // Session aktif et ve engine'i yeniden başlat
        try? AVAudioSession.sharedInstance().setActive(true)
        do {
            try engine.start()
        } catch {
            print("[AudioManager] Engine başlatılamadı: \(error)")
        }

        // Silent loop devam ettir — engine.stop() node'u durdurmuş olabilir
        if silentLoopAttached {
            scheduleSilentLoop()
        }
    }

    private func detachPlayerNodes() {
        playerNodes.values.forEach {
            $0.stop()
            engine.disconnectNodeOutput($0)
            engine.detach($0)
        }
        playerNodes.removeAll()
        audioBuffers.removeAll()
    }

    private func preload(clip: String, soundFolder: String) {
        let name = (clip as NSString).deletingPathExtension
        let ext  = (clip as NSString).pathExtension.isEmpty ? "mp3" : (clip as NSString).pathExtension

        let url: URL?
        if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Sounds/\(soundFolder)") {
            url = u
        } else if let u = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: soundFolder) {
            url = u
        } else {
            url = Bundle.main.url(forResource: name, withExtension: ext)
        }

        guard let resolvedURL = url,
              let file = try? AVAudioFile(forReading: resolvedURL),
              let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat,
                                            frameCapacity: AVAudioFrameCount(file.length)),
              (try? file.read(into: buffer)) != nil
        else {
            print("[AudioManager] YÜKLENEMEDI: \(clip) (folder: \(soundFolder))")
            return
        }

        let node = AVAudioPlayerNode()
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: file.processingFormat)

        audioBuffers[clip] = buffer
        playerNodes[clip] = node
    }

    private func ensureEngineRunning() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("[AudioManager] Engine başlatılamadı: \(error)")
        }
    }

    // MARK: - Çalma

    func play(event: ImpactEvent, pack: SoundPack) {
        guard let clipName = ClipSelector.select(for: event, from: pack) else { return }

        // Node yüklü değilse pack'i yeniden yükle (self-healing)
        if playerNodes[clipName] == nil {
            currentPackID = nil  // force reload
            loadPack(pack)
        }

        guard let node = playerNodes[clipName],
              let buffer = audioBuffers[clipName]
        else { return }

        if !engine.isRunning {
            try? AVAudioSession.sharedInstance().setActive(true)
            try? engine.start()
            if silentLoopAttached && !silentNode.isPlaying { scheduleSilentLoop() }
        }

        if node.isPlaying { node.stop() }
        let volume: Float = dynamicVolume
            ? masterVolume * Float(0.3 + event.intensity * 0.7)
            : masterVolume
        node.volume = volume
        node.scheduleBuffer(buffer, completionHandler: nil)
        node.play()
    }

    func playPreview(pack: SoundPack) {
        guard let node = playerNodes[pack.previewClip],
              let buffer = audioBuffers[pack.previewClip]
        else { return }
        if node.isPlaying { node.stop() }
        node.volume = masterVolume
        node.scheduleBuffer(buffer, completionHandler: nil)
        node.play()
    }

    // MARK: - One-shot (mevcut paketi bozmadan tek bir dosya çal)

    /// Şarj takılınca seçili paketten rastgele bir ses çalar.
    /// Engine player node'larını değiştirmez; ayrı AVAudioPlayer kullanır.
    private var oneShotPlayer: AVAudioPlayer?

    func playChargerSound(from pack: SoundPack, isTrial: Bool = false) {
        let allClips = pack.softClips + pack.mediumClips + pack.hardClips
        guard !allClips.isEmpty else { return }

        // Trial mode: sadece ilk clip (deneme); full: rastgele
        let clip = isTrial ? allClips[0] : allClips.randomElement()!

        let name = (clip as NSString).deletingPathExtension
        let ext  = (clip as NSString).pathExtension.isEmpty ? "mp3" : (clip as NSString).pathExtension

        guard let url = Bundle.main.url(forResource: name, withExtension: ext,
                                        subdirectory: "Sounds/\(pack.soundFolder)")
               ?? Bundle.main.url(forResource: name, withExtension: ext)
        else {
            print("[AudioManager] Charger sound bulunamadı: \(clip)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = masterVolume
            player.prepareToPlay()
            player.play()
            oneShotPlayer = player
        } catch {
            print("[AudioManager] Charger sound çalınamadı: \(error)")
        }
    }

    // MARK: - Arka Plan Keep-Alive

    /// Engine'i başlatır ve tamamen sessiz bir loop çalışmaya bırakır.
    /// Bu sayede iOS, arka planda uygulamayı öldürmez; CoreMotion aktif kalır.
    func startSilentLoop() {
        guard !silentLoopAttached else {
            ensureEngineRunning()
            if !silentNode.isPlaying { scheduleSilentLoop() }
            return
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        let frameCount: AVAudioFrameCount = 4096

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        // Sıfır PCM — tamamen sessiz
        if let ch0 = buffer.floatChannelData?[0] {
            for i in 0..<Int(frameCount) { ch0[i] = 0 }
        }

        silentBuffer = buffer
        engine.attach(silentNode)
        engine.connect(silentNode, to: engine.mainMixerNode, format: format)
        silentNode.volume = 0.0
        silentLoopAttached = true

        ensureEngineRunning()
        scheduleSilentLoop()
    }

    private func scheduleSilentLoop() {
        guard let buffer = silentBuffer else { return }
        silentNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        if !silentNode.isPlaying { silentNode.play() }
    }
}
