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

// MARK: - Wikipedia REST API Response
//
// When we call https://en.wikipedia.org/api/rest_v1/page/summary/Lion
// Wikipedia sends back JSON that looks like:
//
//   {
//     "title": "Lion",
//     "thumbnail": { "source": "https://...", "width": 320, "height": 213 },
//     "originalimage": { "source": "https://...", "width": 4272, "height": 2848 }
//   }
//
// By making our struct `Decodable`, Swift will automatically map those JSON keys
// to the matching properties below.

struct WikiSummaryResponse: Decodable, Sendable {
    let title: String
    let thumbnail: WikiImage?       // Optional — some articles have no image
    let originalimage: WikiImage?   // Optional — higher-res version

    struct WikiImage: Decodable, Sendable {
        let source: URL   // Swift can decode a String into a URL automatically
        let width: Int
        let height: Int
    }
}

// MARK: - Wikipedia MediaWiki API: Article Image List
//
// When we call https://en.wikipedia.org/w/api.php?action=query&titles=Lion&prop=images
// the response looks like:
//
//   {
//     "query": {
//       "pages": {
//         "19758": {                          ← page ID as a string key
//           "images": [
//             { "title": "File:Lion.jpg" },
//             { "title": "File:Lion range.svg" }
//           ]
//         }
//       }
//     }
//   }
//
// Note: `pages` is a dictionary where the KEY is the page ID string.
// We don't care about the key — we just want `.values`.

struct ArticleImagesResponse: Decodable, Sendable {
    let query: QueryBody

    struct QueryBody: Decodable, Sendable {
        let pages: [String: PageResult]
    }

    struct PageResult: Decodable, Sendable {
        let images: [ImageEntry]?
    }

    struct ImageEntry: Decodable, Sendable {
        let title: String
    }
}

// MARK: - Wikipedia MediaWiki API: Image URLs
//
// After getting the file names above, we call the API again to get the actual download URLs.
// Response shape:
//
//   {
//     "query": {
//       "pages": {
//         "-1": {
//           "title": "File:Lion.jpg",
//           "imageinfo": [{ "url": "https://...", "thumburl": "https://..." }]
//         }
//       }
//     }
//   }
//
// `thumburl` is provided when we request a specific width with `iiurlwidth=1200`.
// It's the same image but scaled to 1200px wide — much faster to download than the original.

struct ImageInfoResponse: Decodable, Sendable {
    let query: QueryBody

    struct QueryBody: Decodable, Sendable {
        let pages: [String: PageResult]
    }

    struct PageResult: Decodable, Sendable {
        let title: String
        let imageinfo: [ImageInfo]?
    }

    struct ImageInfo: Decodable, Sendable {
        let url: URL        // Original full-resolution URL
        let thumburl: URL?  // Scaled thumbnail URL (present when iiurlwidth is set)
    }
}

