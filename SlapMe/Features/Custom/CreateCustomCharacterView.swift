import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

struct CreateCustomCharacterView: View {
    @ObservedObject var customPackManager: CustomPackManager
    /// Dolu gelirse edit modu; nil ise yeni karakter oluşturma modu
    var editingPackID: String? = nil
    @Environment(\.dismiss) private var dismiss

    @State private var characterName = ""
    @State private var currentPackID: String? = nil
    @State private var showDocPicker = false
    @State private var errorMessage: String? = nil
    @State private var previewPlayer: AVAudioPlayer? = nil
    @State private var playingClip: String? = nil
    @State private var showDeleteConfirm = false

    private var isEditMode: Bool { editingPackID != nil }

    private var currentPack: CustomPack? {
        guard let id = currentPackID else { return nil }
        return customPackManager.packs.first { $0.id == id }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Karakter ikonu + isim alanı
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.12))
                            .frame(width: 88, height: 88)
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.purple)
                    }
                    .padding(.top, 24)

                    TextField("Karakter adı", text: $characterName)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .submitLabel(.done)
                }
                .padding(.bottom, 20)

                Divider()

                // Ses listesi
                if let pack = currentPack, !pack.clips.isEmpty {
                    List {
                        ForEach(Array(pack.clips.enumerated()), id: \.element) { index, clip in
                            HStack(spacing: 12) {
                                Button {
                                    togglePlay(clip: clip, pack: pack)
                                } label: {
                                    Image(
                                        systemName: playingClip == clip
                                            ? "stop.circle.fill" : "play.circle.fill"
                                    )
                                    .font(.system(size: 30))
                                    .foregroundStyle(
                                        playingClip == clip ? Color.red : Color.purple)
                                }
                                .buttonStyle(.plain)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ses \(index + 1)")
                                        .font(.system(size: 15, weight: .semibold))
                                    Text(fileSizeLabel(clip: clip, packID: pack.id))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Image(systemName: "waveform")
                                    .foregroundStyle(Color.purple.opacity(0.4))
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete { indexSet in
                            guard let pack = currentPack else { return }
                            for i in indexSet {
                                customPackManager.removeClip(
                                    filename: pack.clips[i], from: pack.id)
                            }
                        }
                    }
                    .listStyle(.plain)
                } else {
                    // Boş durum
                    VStack(spacing: 12) {
                        Image(systemName: "waveform.badge.plus")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.secondary)
                        Text("Henüz ses eklenmedi")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Text("MP3, WAV, M4A formatları desteklenir")
                            .font(.caption)
                            .foregroundStyle(Color.secondary.opacity(0.7))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                VStack(spacing: 8) {
                    if let err = errorMessage {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    // Ses ekle butonu
                    Button {
                        ensurePackExists()
                        showDocPicker = true
                    } label: {
                        Label("Ses Ekle", systemImage: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.purple, in: RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 20)

                    // Edit modunda Paketi Sil butonu
                    if isEditMode {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            Label("Paketi Sil", systemImage: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(
                                    Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer().frame(height: 8)
                }
            }
            .navigationTitle(isEditMode ? "Paketi Düzenle" : "Yeni Karakter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditMode ? "Kapat" : "İptal") {
                        previewPlayer?.stop()
                        if !isEditMode, let id = currentPackID {
                            // Yeni oluşturma iptal → geçici paketi sil
                            customPackManager.deletePack(id: id)
                        }
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(
                        characterName.trimmingCharacters(in: .whitespaces).isEmpty
                            || (currentPack?.clips.isEmpty ?? true)
                    )
                    .font(.body.weight(.semibold))
                }
            }
            .sheet(isPresented: $showDocPicker) {
                AudioDocumentPicker { url in
                    importAudio(from: url)
                }
            }
            .confirmationDialog(
                "Bu paketi silmek istediğinden emin misin?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Paketi Sil", role: .destructive) {
                    previewPlayer?.stop()
                    if let id = currentPackID {
                        customPackManager.deletePack(id: id)
                    }
                    dismiss()
                }
                Button("Vazgeç", role: .cancel) {}
            }
            .onAppear {
                if let id = editingPackID,
                    let pack = customPackManager.packs.first(where: { $0.id == id })
                {
                    currentPackID = id
                    characterName = pack.name
                }
            }
        }
    }

    // MARK: - Actions

    private func ensurePackExists() {
        guard currentPackID == nil else { return }
        let name = characterName.trimmingCharacters(in: .whitespaces)
        let pack = customPackManager.createPack(name: name.isEmpty ? "Karakterim" : name)
        currentPackID = pack.id
    }

    private func save() {
        guard let id = currentPackID else { return }
        let name = characterName.trimmingCharacters(in: .whitespaces)
        customPackManager.updateName(name.isEmpty ? "Karakterim" : name, for: id)
        previewPlayer?.stop()
        dismiss()
    }

    private func importAudio(from url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }

        ensurePackExists()
        guard let id = currentPackID else { return }

        do {
            try customPackManager.addClip(from: url, to: id)
            errorMessage = nil
        } catch {
            errorMessage = "Ses eklenemedi: \(error.localizedDescription)"
        }
    }

    private func togglePlay(clip: String, pack: CustomPack) {
        if playingClip == clip {
            previewPlayer?.stop()
            playingClip = nil
            return
        }
        previewPlayer?.stop()
        let url = customPackManager.clipURL(filename: clip, packID: pack.id)
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        previewPlayer = player
        player.play()
        playingClip = clip
        DispatchQueue.main.asyncAfter(deadline: .now() + player.duration) {
            if self.playingClip == clip { self.playingClip = nil }
        }
    }

    private func fileSizeLabel(clip: String, packID: String) -> String {
        guard let id = currentPackID else { return "" }
        let url = customPackManager.clipURL(filename: clip, packID: id)
        let bytes =
            (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        let kb = bytes / 1024
        return kb > 1024 ? String(format: "%.1f MB", Double(kb) / 1024) : "\(kb) KB"
    }
}

// MARK: - Document Picker (ses dosyası seçici)

private struct AudioDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let types: [UTType] = [.audio].compactMap { $0 }
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: types)
        picker.allowsMultipleSelection = true
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(
        _ uiViewController: UIDocumentPickerViewController,
        context: Context
    ) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(
            _ controller: UIDocumentPickerViewController,
            didPickDocumentsAt urls: [URL]
        ) {
            urls.forEach { onPick($0) }
        }
    }
}
