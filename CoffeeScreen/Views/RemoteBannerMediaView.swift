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

/// 원격 및 로컬 Lottie(.json / .lottie) 애니메이션 뷰
struct RemoteLottieView: NSViewRepresentable {
    let url: URL
    var loopMode: LottieLoopMode = .loop

    final class Coordinator {
        var loadedURL: URL?
        var task: URLSessionDataTask?
        weak var animationView: LottieAnimationView?

        deinit {
            task?.cancel()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let container = NSView(frame: .zero)
        let animationView = LottieAnimationView()
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = loopMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: container.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])

        context.coordinator.animationView = animationView
        loadIfNeeded(coordinator: context.coordinator)
        return container
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.animationView?.loopMode = loopMode
        loadIfNeeded(coordinator: context.coordinator)
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
                              let animView = coordinator.animationView else { return }
                        animView.loadAnimation(from: dotLottie)
                        animView.loopMode = loopMode
                        animView.play()
                    }
                }
            }
        } else if let animation = try? JSONDecoder().decode(LottieAnimation.self, from: data) {
            DispatchQueue.main.async {
                guard coordinator.loadedURL == targetURL,
                      let animView = coordinator.animationView else { return }
                animView.animation = animation
                animView.loopMode = loopMode
                animView.play()
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
