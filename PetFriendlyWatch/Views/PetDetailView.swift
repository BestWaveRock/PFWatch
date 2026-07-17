import SwiftUI
import AVFoundation

struct PetDetailView: View {
    let pet: Pet

    @State private var showFullImage = false
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var audioError: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // MARK: 大头像（点击查看大图）
                ZStack(alignment: .bottomTrailing) {
                    if let url = pet.avatarUrl {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.accentColor.opacity(0.3), lineWidth: 2))
                            case .failure:
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                    .overlay(Image(systemName: "photo.badge.exclamationmark")
                                        .font(.title3).foregroundColor(.secondary))
                            case .empty:
                                Circle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(width: 120, height: 120)
                                    .overlay(ProgressView())
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .onTapGesture {
                            showFullImage = true
                        }
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                            .overlay(Image(systemName: "pawprint").font(.title))
                    }

                    // 放大镜图标
                    if pet.avatarUrl != nil {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .font(.caption)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.accentColor).frame(width: 18, height: 18))
                            .offset(x: -2, y: -2)
                    }
                }

                // MARK: 名称 + 品种
                Text(pet.displayName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                VStack(spacing: 4) {
                    DetailRow(label: "品种", value: pet.breedLabel)
                    DetailRow(label: "性别", value: pet.sexLabel)
                    DetailRow(label: "年龄", value: pet.ageString)
                }
                .padding(.horizontal)

                // MARK: 播放录音按钮
                if pet.voiceURL != nil {
                    Button(action: togglePlayback) {
                        HStack {
                            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                                .font(.title2)
                            Text(isPlaying ? "停止播放" : "听宠物录音")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isPlaying ? Color.red.opacity(0.15) : Color.accentColor.opacity(0.15))
                        )
                    }
                    .buttonStyle(.plain)

                    if let err = audioError {
                        Text(err)
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(pet.displayName)
        .navigationBarTitleDisplayMode(.inline)
        // 全屏大图
        .fullScreenCover(isPresented: $showFullImage) {
            FullImageView(url: pet.avatarUrl)
        }
    }

    // MARK: - 录音播放

    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.stop()
            isPlaying = false
            return
        }

        guard let url = pet.voiceURL else { return }

        // 配置音频会话
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            audioError = "音频初始化失败"
            return
        }

        // 下载音频文件并播放
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    do {
                        audioPlayer = try AVAudioPlayer(data: data)
                        audioPlayer?.delegate = makeDelegate()
                        audioPlayer?.prepareToPlay()
                        audioPlayer?.play()
                        isPlaying = true
                        audioError = nil
                    } catch {
                        audioError = "播放失败: \(error.localizedDescription)"
                    }
                }
            } catch {
                await MainActor.run {
                    audioError = "下载录音失败"
                }
            }
        }
    }

    /// 播放完成回调
    private func makeDelegate() -> AudioPlayerDelegate {
        let d = AudioPlayerDelegate()
        d.onFinish = { [self] in
            Task { @MainActor in
                self.isPlaying = false
            }
        }
        return d
    }
}

// MARK: - AVAudioPlayer 代理

private class AudioPlayerDelegate: NSObject, AVAudioPlayerDelegate {
    var onFinish: (() -> Void)?

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinish?()
    }
}

// MARK: - 详情行

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.body)
        }
    }
}

// MARK: - 全屏大图

struct FullImageView: View {
    let url: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                if let url = url {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(1.0)
                                .ignoresSafeArea()
                        case .failure:
                            VStack(spacing: 8) {
                                Image(systemName: "photo.badge.exclamationmark")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("图片加载失败")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        case .empty:
                            ProgressView()
                                .tint(.white)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
    }
}
