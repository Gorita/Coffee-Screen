import AppKit
import Lottie
import SwiftUI

/// 원격 URL / 레포 상대경로 기반 통합 배너 미디어 뷰 (Lottie / GIF / 정지 이미지 / SF Symbol / Emoji)
struct RemoteBannerMediaView: View {
    let item: AffiliateAdItem

    var body: some View {
        if let url = item.validImageURL {
            switch item.mediaFormat {
            case .lottie:
                RemoteLottieView(url: url, loopMode: .loop)
                    .clipped()
            case .gif:
                RemoteAnimatedGIFView(url: url)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            case .image:
                staticImageView(url: url)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        } else if let symbol = item.trimmedSFSymbol {
            ZStack {
                Circle()
                    .fill(item.accentSwiftUIColor.opacity(0.18))
                    .overlay(
                        Circle()
                            .strokeBorder(item.accentSwiftUIColor.opacity(0.35), lineWidth: 0.75)
                    )
                Image(systemName: symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(item.accentSwiftUIColor)
            }
        } else if let emoji = item.trimmedEmoji {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                Text(emoji)
                    .font(.system(size: 34))
            }
        }
    }

    @ViewBuilder
    private func staticImageView(url: URL) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.6)
                    )
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                fallbackThumbnail
            @unknown default:
                fallbackThumbnail
            }
        }
    }

    private var fallbackThumbnail: some View {
        Rectangle()
            .fill(Color(red: 0.15, green: 0.17, blue: 0.22))
            .overlay(
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(item.accentSwiftUIColor)
            )
    }
}

/// Lottie intrinsicContentSize(240x240 등)가 SwiftUI 프레임을 덮어쓰지 않도록 격리하는 컨테이너 뷰
final class LottieContainerNSView: NSView {
    let animationView = LottieAnimationView(configuration: LottieConfiguration(renderingEngine: .mainThread))

    override var isFlipped: Bool { true }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = true

        animationView.contentMode = .scaleAspectFit
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.autoresizingMask = [.width, .height]
        animationView.frame = bounds
        animationView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        animationView.setContentHuggingPriority(.defaultLow, for: .vertical)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        animationView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        addSubview(animationView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        animationView.frame = bounds
        animationView.needsLayout = true
        animationView.layoutSubtreeIfNeeded()
    }
}

/// 원격 및 로컬 Lottie(.json / .lottie) 애니메이션 뷰
struct RemoteLottieView: NSViewRepresentable {
    let url: URL
    var loopMode: LottieLoopMode = .loop

    final class Coordinator {
        var loadedURL: URL?
        var task: URLSessionDataTask?
        weak var containerView: LottieContainerNSView?

        deinit {
            task?.cancel()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> LottieContainerNSView {
        let container = LottieContainerNSView(frame: .zero)
        container.animationView.loopMode = loopMode
        context.coordinator.containerView = container
        loadIfNeeded(coordinator: context.coordinator)
        return container
    }

    func updateNSView(_ nsView: LottieContainerNSView, context: Context) {
        nsView.animationView.loopMode = loopMode
        loadIfNeeded(coordinator: context.coordinator)
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: LottieContainerNSView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 60, height: 60))
    }

    private func loadIfNeeded(coordinator: Coordinator) {
        guard coordinator.loadedURL != url else { return }
        coordinator.loadedURL = url
        coordinator.task?.cancel()

        if url.isFileURL {
            loadLocalURL(url, coordinator: coordinator)
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let targetURL = url
        let task = URLSession.shared.dataTask(with: request) { data, _, error in
            guard error == nil, let data = data else { return }
            applyLoadedData(data, for: targetURL, coordinator: coordinator)
        }
        coordinator.task = task
        task.resume()
    }

    private func loadLocalURL(_ fileURL: URL, coordinator: Coordinator) {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        applyLoadedData(data, for: fileURL, coordinator: coordinator)
    }

    private func applyLoadedData(_ data: Data, for targetURL: URL, coordinator: Coordinator) {
        if targetURL.pathExtension.lowercased() == "lottie" {
            let filename = targetURL.deletingPathExtension().lastPathComponent
            DotLottieFile.loadedFrom(data: data, filename: filename) { result in
                if case .success(let dotLottie) = result {
                    DispatchQueue.main.async {
                        guard coordinator.loadedURL == targetURL,
                              let container = coordinator.containerView else { return }
                        container.animationView.loadAnimation(from: dotLottie)
                        container.animationView.loopMode = loopMode
                        container.needsLayout = true
                        container.layoutSubtreeIfNeeded()
                        container.animationView.play()
                    }
                }
            }
        } else if let animation = try? JSONDecoder().decode(LottieAnimation.self, from: data) {
            DispatchQueue.main.async {
                guard coordinator.loadedURL == targetURL,
                      let container = coordinator.containerView else { return }
                container.animationView.animation = animation
                container.animationView.loopMode = loopMode
                container.needsLayout = true
                container.layoutSubtreeIfNeeded()
                container.animationView.forceDisplayUpdate()
                container.animationView.play()
            }
        }
    }
}

/// 원격 및 로컬 GIF 애니메이션 뷰
struct RemoteAnimatedGIFView: NSViewRepresentable {
    let url: URL

    final class Coordinator {
        var loadedURL: URL?
        var task: URLSessionDataTask?

        deinit {
            task?.cancel()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSImageView {
        let imageView = NSImageView()
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignCenter
        imageView.animates = true
        imageView.canDrawSubviewsIntoLayer = true
        imageView.wantsLayer = true
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        imageView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        loadIfNeeded(into: imageView, coordinator: context.coordinator)
        return imageView
    }

    func updateNSView(_ nsView: NSImageView, context: Context) {
        loadIfNeeded(into: nsView, coordinator: context.coordinator)
    }

    private func loadIfNeeded(into imageView: NSImageView, coordinator: Coordinator) {
        guard coordinator.loadedURL != url else { return }
        coordinator.loadedURL = url
        coordinator.task?.cancel()

        if url.isFileURL {
            if let image = NSImage(contentsOf: url) {
                imageView.image = image
                imageView.animates = true
            }
            return
        }

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15

        let targetURL = url
        let task = URLSession.shared.dataTask(with: request) { [weak imageView] data, _, error in
            guard error == nil, let data = data, let image = NSImage(data: data) else { return }
            DispatchQueue.main.async {
                guard coordinator.loadedURL == targetURL, let imageView = imageView else { return }
                imageView.image = image
                imageView.animates = true
            }
        }
        coordinator.task = task
        task.resume()
    }
}
