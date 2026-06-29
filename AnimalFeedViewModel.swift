// AnimalFeedViewModel.swift

import SwiftUI
import Combine

@MainActor
class AnimalFeedViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentPhoto: AnimalPhoto?
    @Published var isLoading: Bool = true
    @Published var photoInterval: Double = 10.0 {
        didSet { startAutoAdvance() }
    }

    // MARK: - Private State

    private var randomQueue: [AnimalPhoto] = []
    private var advanceTask: Task<Void, Never>?
    private let service = WikipediaService()

    // titlePool starts with the starter animals and grows as categories load.
    private var titlePool: [(title: String, name: String)] = WikipediaService.starterPool
    private var seenTitles: Set<String> = Set(WikipediaService.starterPool.map { $0.title.lowercased() })

    // Set to true the moment the first Wikipedia category finishes loading.
    // Prevents loadRandomFeed() from overwriting a category-based queue
    // if it happens to finish after the category swap.
    private var categoryQueueReady = false

    // MARK: - Init

    init() {
        Task { await loadRandomFeed() }
        startAutoAdvance()
        Task { await loadCategoryTitles() }
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
            Task { await loadRandomFeed() }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhoto = randomQueue.removeFirst()
            }
            if randomQueue.count < 3 {
                Task { await replenishRandomQueue() }
            }
        }
    }

    // MARK: - Initial Feed
    //
    // Only loads 5 starter photos (not 20) so the queue empties quickly
    // and category photos take over sooner. If categories have already
    // loaded by the time this finishes, we don't overwrite that queue.

    func loadRandomFeed() async {
        isLoading = true
        let animals = Array(titlePool.shuffled().prefix(5))
        let service = self.service
        var loaded: [AnimalPhoto] = []

        await withTaskGroup(of: AnimalPhoto?.self) { group in
            for (title, name) in animals {
                group.addTask { await service.fetchMainImage(articleTitle: title, displayName: name) }
            }
            for await photo in group {
                if let photo { loaded.append(photo) }
            }
        }

        // Don't overwrite the queue if the category swap already happened
        // while we were waiting for these image fetches to complete.
        if !categoryQueueReady {
            randomQueue = loaded.shuffled()
        }

        // Always show a photo if nothing is on screen yet
        if currentPhoto == nil {
            withAnimation(.easeInOut(duration: 0.5)) {
                currentPhoto = randomQueue.isEmpty ? loaded.first : randomQueue.removeFirst()
            }
        }

        isLoading = false
    }

    // MARK: - Background Category Title Loading
    //
    // Fetches titles from each Wikipedia category sequentially.
    // As soon as the FIRST category returns titles, we:
    //   1. Set categoryQueueReady so loadRandomFeed won't overwrite the queue
    //   2. Clear whatever starter photos are queued up
    //   3. Immediately fetch fresh category photos into the queue
    // The current on-screen photo is untouched throughout.

    private func loadCategoryTitles() async {
        let service = self.service
        var swappedToCategories = false

        for category in WikipediaService.animalCategories {
            let titles = await service.fetchCategoryTitles(category: category, limit: 500)

            let newTitles = titles.filter { !seenTitles.contains($0.title.lowercased()) }
            for pair in newTitles { seenTitles.insert(pair.title.lowercased()) }
            titlePool.append(contentsOf: newTitles)

            if !swappedToCategories && !newTitles.isEmpty {
                swappedToCategories = true
                // Flag BEFORE the await so loadRandomFeed sees it even if it
                // resumes from suspension between this line and replenishRandomQueue.
                categoryQueueReady = true
                randomQueue.removeAll()
                await replenishRandomQueue()

                // If nothing is on screen yet (edge case where loadRandomFeed
                // lost the race entirely), kick off display now.
                if currentPhoto == nil, let first = randomQueue.first {
                    randomQueue.removeFirst()
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentPhoto = first
                    }
                }
            }
        }
        print("✅ Title pool: \(titlePool.count) animals")
    }

    // MARK: - Queue Replenishment

    private func replenishRandomQueue() async {
        let animals = Array(titlePool.shuffled().prefix(10))
        let service = self.service
        var loaded: [AnimalPhoto] = []

        await withTaskGroup(of: AnimalPhoto?.self) { group in
            for (title, name) in animals {
                group.addTask { await service.fetchMainImage(articleTitle: title, displayName: name) }
            }
            for await photo in group {
                if let photo { loaded.append(photo) }
            }
        }
        randomQueue.append(contentsOf: loaded.shuffled())
    }
}
