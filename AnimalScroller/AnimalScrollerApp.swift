// AnimalScrollerApp.swift
//
// This is the entry point for the app — the Swift equivalent of "main()".
// @main tells Xcode "start here". Every SwiftUI app has exactly one of these.
// The App protocol requires a `body` property that describes the app's scenes
// (on iPad, a scene is basically a window).

import SwiftUI

@main
struct AnimalScrollerApp: App {

    init() {
        // Configure a large persistent URL cache shared across the whole app.
        // AsyncImage and WikipediaService both benefit from this automatically.
        //
        // Memory: 100 MB  — fast, gone when the app quits
        // Disk:   1 GB    — survives between launches; photos work offline once seen
        //
        // iOS stores this in the app's Caches directory (backed up by the OS,
        // cleared only when the device is critically low on space).
        let cacheDirectory = FileManager.default
            .urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("AnimalScrollerImages")

        URLCache.shared = URLCache(
            memoryCapacity: 100 * 1024 * 1024,
            diskCapacity:  1_000 * 1024 * 1024,
            directory: cacheDirectory
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
