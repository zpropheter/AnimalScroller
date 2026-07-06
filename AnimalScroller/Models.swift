// Models.swift
//
// All data structures used by the app.
//
// KEY CONCEPTS IN THIS FILE:
//   - struct: A value type. When you pass a struct, Swift copies it. Great for data.
//   - Identifiable: A protocol (like an interface) that requires an `id` property.
//     SwiftUI uses `id` to track items in lists and animate changes.
//   - Decodable: Another protocol that lets Swift automatically parse JSON into a struct.
//     The property names must match the JSON keys exactly (or you provide a CodingKeys enum).

import Foundation

// MARK: - Core App Model

/// One animal photo and its metadata.
/// `Identifiable` is required for using this in SwiftUI's ForEach and lists.
// Sendable means "safe to pass across actor/concurrency boundaries".
// All our model types are pure value types (structs with String/URL/Int),
// so Sendable is trivially satisfied — Swift just needs us to declare it
// to suppress the actor-isolation warnings in Swift 6.

struct AnimalPhoto: Identifiable, Sendable {
    let id = UUID()              // UUID() generates a unique ID like "3B4F2C1A-..."
    let imageURL: URL            // Where to download the photo from
    let animalName: String       // Human-readable display name, e.g. "Snow Leopard"
    let articleTitle: String     // Wikipedia article slug, e.g. "Snow_leopard"
}

// MARK: - Attribution

/// Credit information for a Wikimedia image.
/// Displayed when the user taps the (i) button on a photo.
struct AttributionInfo: Sendable {
    let author: String      // Photographer or copyright holder, HTML-stripped
    let license: String     // e.g. "CC BY-SA 4.0" or "Public domain"
    let licenseURL: URL?    // Link to the full license text
    let filePageURL: URL?   // Link to the Wikimedia Commons file page
}

// Note: the JSON response structs (WikiSummaryResponse, ArticleImagesResponse,
// ImageInfoResponse) live inside WikipediaService.swift as private types.
// Keeping them there prevents Swift 6 from inferring @MainActor on their
// Decodable conformances, which would happen if they were defined here
// alongside SwiftUI-facing code.

