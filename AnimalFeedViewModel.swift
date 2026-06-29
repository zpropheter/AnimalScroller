// AnimalFeedViewModel.swift

import SwiftUI
import Combine

@MainActor
class AnimalFeedViewModel: ObservableObject {

    // MARK: - Published State

    @Published var currentPhoto: AnimalPhoto?
    @Published var isLoading: Bool = true

    /// Seconds between auto-advances. Uses `didSet` to restart the timer
    /// whenever the user changes it from the settings menu.
    @Published var photoInterval: Double = 10.0 {
        didSet { startAutoAdvance() }
    }

    // MARK: - Private State

    private var randomQueue: [AnimalPhoto] = []
    private var advanceTask: Task<Void, Never>?   // The self-driving timer task
    private let service = WikipediaService()

    // MARK: - Init

    init() {
        Task { await loadRandomFeed() }
        startAutoAdvance()
    }

    // MARK: - Auto-Advance Timer
    //
    // Instead of a SwiftUI Timer publisher (which can't change interval at runtime),
    // we use a Task with Task.sleep. When photoInterval changes, we cancel the old
    // task and start a new one with the updated interval. Task.sleep yields the
    // thread so the UI stays fully responsive while waiting.

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
            if randomQueue.count < 5 {
                Task { await replenishRandomQueue() }
            }
        }
    }

    // MARK: - Loading

    func loadRandomFeed() async {
        isLoading = true
        let animals = Array(WikipediaService.animalPool.shuffled().prefix(20))
        let service = self.service
        var loaded: [AnimalPhoto] = []

        await withTaskGroup(of: AnimalPhoto?.self) { group in
            for (title, name) in animals {
                group.addTask {
                    await service.fetchMainImage(articleTitle: title, displayName: name)
                }
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
    }

    private func replenishRandomQueue() async {
        let animals = Array(WikipediaService.animalPool.shuffled().prefix(10))
        let service = self.service
        var loaded: [AnimalPhoto] = []

        await withTaskGroup(of: AnimalPhoto?.self) { group in
            for (title, name) in animals {
                group.addTask {
                    await service.fetchMainImage(articleTitle: title, displayName: name)
                }
            }
            for await photo in group {
                if let photo { loaded.append(photo) }
            }
        }
        randomQueue.append(contentsOf: loaded.shuffled())
    }
}
