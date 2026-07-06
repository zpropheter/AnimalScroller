// AnimalFeedViewModel.swift

import SwiftUI
import Combine
import Network

@MainActor
class AnimalFeedViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentPhoto: AnimalPhoto?
    @Published var isLoading: Bool = true
    @Published var currentAttribution: AttributionInfo? = nil
    @Published var isLoadingAttribution = false
    @Published var photoInterval: Double {
        didSet {
            UserDefaults.standard.set(photoInterval, forKey: "photoInterval")
            startAutoAdvance()
        }
    }

    /// Which categories are currently enabled. Never empty — toggle guards against it.
    @Published var enabledCategories: Set<AnimalCategory> {
        didSet {
            let ids = enabledCategories.map { $0.rawValue }
            UserDefaults.standard.set(ids, forKey: "enabledCategories")
            randomQueue.removeAll()
            enrichedArticles.removeAll()
            sessionViewCounts.removeAll()
            Task { await replenishQueue() }
        }
    }

    // MARK: - Private State

    private var randomQueue: [AnimalPhoto] = []
    private var advanceTask: Task<Void, Never>?
    private let service = WikipediaService()

    // MARK: - Session View Tracking

    /// How many times each article has been shown this session.
    private var sessionViewCounts: [String: Int] = [:]
    /// Articles we've already background-fetched extra photos for.
    private var enrichedArticles: Set<String> = []

    // MARK: - Network Monitor

    private let networkMonitor = NWPathMonitor()
    private var isConnected = false

    // MARK: - Active Pool

    private var activeTitlePool: [(title: String, name: String)] {
        AnimalCategory.allCases
            .filter { enabledCategories.contains($0) }
            .flatMap { $0.animals }
            .shuffled()
    }

    // MARK: - Init

    init() {
        let savedInterval = UserDefaults.standard.double(forKey: "photoInterval")
        photoInterval = savedInterval > 0 ? savedInterval : 10.0

        if let saved = UserDefaults.standard.stringArray(forKey: "enabledCategories"),
           !saved.isEmpty {
            let restored = Set(saved.compactMap { AnimalCategory(rawValue: $0) })
            enabledCategories = restored.isEmpty ? Set(AnimalCategory.allCases) : restored
        } else {
            enabledCategories = Set(AnimalCategory.allCases)
        }

        // Monitor network connectivity. The handler fires on a background queue,
        // so we hop to MainActor before writing the flag.
        networkMonitor.pathUpdateHandler = { path in
            let connected = path.status == .satisfied
            Task { @MainActor [weak self] in
                self?.isConnected = connected
            }
        }
        networkMonitor.start(queue: DispatchQueue.global(qos: .background))

        startAutoAdvance()
        Task { await loadInitialPhoto() }
    }

    deinit {
        networkMonitor.cancel()
    }

    // MARK: - Category Toggle

    func toggleCategory(_ category: AnimalCategory) {
        if enabledCategories.contains(category) {
            guard enabledCategories.count > 1 else { return }
            enabledCategories.remove(category)
        } else {
            enabledCategories.insert(category)
        }
    }

    // MARK: - Auto-Advance Timer

    func startAutoAdvance() {
        advanceTask?.cancel()
        advanceTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(photoInterval))
                guard !Task.isCancelled else { return }
                advance()
            }
        }
    }

    // MARK: - Advancing

    func advance() {
        guard !isLoading else { return }

        if randomQueue.isEmpty {
            Task { await replenishQueue() }
        } else {
            let photo = randomQueue.removeFirst()
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhoto = photo
            }
            // Clear any open attribution when the photo changes
            currentAttribution = nil
            isLoadingAttribution = false
            trackAndMaybeEnrich(photo)
            if randomQueue.count < 5 {
                Task { await replenishQueue() }
            }
        }
    }

    // MARK: - Attribution

    func fetchAttribution() {
        guard let photo = currentPhoto else { return }
        isLoadingAttribution = true
        Task {
            let info = await service.fetchAttribution(for: photo.imageURL)
            currentAttribution = info
            isLoadingAttribution = false
        }
    }

    func clearAttribution() {
        currentAttribution = nil
        isLoadingAttribution = false
    }

    // MARK: - View Tracking & Background Enrichment
    //
    // The first time an animal appears we just serve the cached main photo.
    // The SECOND time it appears in the same session (meaning the pool has
    // cycled around), we treat it as a sign there aren't enough photos of
    // that species — so we fetch up to 5 extra article photos in the
    // background (only if we have a network connection) and inject them
    // near the front of the queue for variety.

    private func trackAndMaybeEnrich(_ photo: AnimalPhoto) {
        let title = photo.articleTitle
        sessionViewCounts[title, default: 0] += 1

        guard
            sessionViewCounts[title] == 2,      // second appearance this session
            !enrichedArticles.contains(title),   // haven't enriched this one yet
            isConnected                          // network is available
        else { return }

        enrichedArticles.insert(title)
        Task { await enrichQueue(with: photo) }
    }

    private func enrichQueue(with photo: AnimalPhoto) async {
        let extras = await service.fetchArticlePhotos(
            articleTitle: photo.articleTitle,
            displayName: photo.animalName,
            limit: 5
        )
        guard !extras.isEmpty else { return }

        // Insert near the front so the new variety shows up soon,
        // but not immediately (we don't want to interrupt the flow).
        let insertAt = min(4, randomQueue.count)
        randomQueue.insert(contentsOf: extras.shuffled(), at: insertAt)
        print("✅ Enriched queue with \(extras.count) extra photos of \(photo.animalName)")
    }

    // MARK: - Initial Load

    private func loadInitialPhoto() async {
        isLoading = true
        let pool = activeTitlePool
        guard !pool.isEmpty else { isLoading = false; return }

        let batch = Array(pool.prefix(8))
        var loaded: [AnimalPhoto] = []

        await withTaskGroup(of: AnimalPhoto?.self) { group in
            for (title, name) in batch {
                group.addTask { await self.service.fetchMainImage(articleTitle: title, displayName: name) }
            }
            for await photo in group {
                if let photo { loaded.append(photo) }
            }
        }

        randomQueue = loaded.shuffled()

        withAnimation(.easeInOut(duration: 0.5)) {
            currentPhoto = randomQueue.isEmpty ? nil : randomQueue.removeFirst()
        }
        isLoading = false

        await replenishQueue()
    }

    // MARK: - Queue Replenishment

    private func replenishQueue() async {
        let pool = activeTitlePool
        guard !pool.isEmpty else { return }
        let batch = Array(pool.prefix(12))

        var loaded: [AnimalPhoto] = []
        await withTaskGroup(of: AnimalPhoto?.self) { group in
            for (title, name) in batch {
                group.addTask { await self.service.fetchMainImage(articleTitle: title, displayName: name) }
            }
            for await photo in group {
                if let photo { loaded.append(photo) }
            }
        }
        randomQueue.append(contentsOf: loaded.shuffled())
    }
}
