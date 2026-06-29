// AnimalScrollerApp.swift
//
// This is the entry point for the app — the Swift equivalent of "main()".
// @main tells Xcode "start here". Every SwiftUI app has exactly one of these.
// The App protocol requires a `body` property that describes the app's scenes
// (on iPad, a scene is basically a window).

import SwiftUI

@main
struct AnimalScrollerApp: App {
    var body: some Scene {
        WindowGroup {
            // ContentView is the root view — everything starts here
            ContentView()
        }
    }
}
