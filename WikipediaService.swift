// WikipediaService.swift
//
// Handles all network requests to Wikipedia and Wikimedia APIs.
//
// KEY CONCEPTS IN THIS FILE:
//   - actor: Like a class, but Swift guarantees only ONE piece of code runs inside it
//     at a time. This prevents bugs where two simultaneous network calls corrupt
//     shared data. Think of it as a thread-safe class.
//
//   - async/await: Modern Swift concurrency. `async` marks a function that can pause
//     (while waiting for a network response, for example). `await` is where it pauses.
//     The calling code resumes automatically when the result is ready — no callbacks needed.
//
//   - URLSession: Apple's built-in HTTP networking library. `.data(from: url)` downloads
//     the raw bytes at a URL. We then parse those bytes into our Decodable structs.

import Foundation

// Private helper: splits an array into sub-arrays of a given size.
// Defined here (not as an Array extension) to avoid actor-isolation issues
// that arise when extending stdlib types in a file used across concurrency domains.
private func chunked<T>(_ array: [T], into size: Int) -> [[T]] {
    stride(from: 0, to: array.count, by: size).map {
        Array(array[$0..<Swift.min($0 + size, array.count)])
    }
}

actor WikipediaService {

    // MARK: - Animal Catalog
    //
    // A hand-picked list of animals that have great Wikipedia articles with photos.
    // Each entry is a tuple: (Wikipedia article title slug, display name for the UI).
    // Tuples are lightweight, unnamed structs — great for small grouped values.

    static let animalPool: [(title: String, name: String)] = [
        ("Lion",                       "Lion"),
        ("Tiger",                      "Tiger"),
        ("African_bush_elephant",      "African Elephant"),
        ("Giraffe",                    "Giraffe"),
        ("Emperor_penguin",            "Emperor Penguin"),
        ("Common_bottlenose_dolphin",  "Bottlenose Dolphin"),
        ("Gray_wolf",                  "Gray Wolf"),
        ("Brown_bear",                 "Brown Bear"),
        ("Bald_eagle",                 "Bald Eagle"),
        ("Giant_Pacific_octopus",      "Giant Octopus"),
        ("Cheetah",                    "Cheetah"),
        ("Western_gorilla",            "Gorilla"),
        ("Polar_bear",                 "Polar Bear"),
        ("Snow_leopard",               "Snow Leopard"),
        ("Red_fox",                    "Red Fox"),
        ("Giant_panda",                "Giant Panda"),
        ("Blue_whale",                 "Blue Whale"),
        ("African_wild_dog",           "African Wild Dog"),
        ("Komodo_dragon",              "Komodo Dragon"),
        ("Mantis_shrimp",              "Mantis Shrimp"),
        ("Axolotl",                    "Axolotl"),
        ("Narwhal",                    "Narwhal"),
        ("Fennec_fox",                 "Fennec Fox"),
        ("Meerkat",                    "Meerkat"),
        ("Capybara",                   "Capybara"),
        ("Platypus",                   "Platypus"),
        ("Cassowary",                  "Cassowary"),
        ("Jaguar",                     "Jaguar"),
        ("Ring-tailed_lemur",          "Ring-Tailed Lemur"),
        ("Mandrill",                   "Mandrill"),
        ("Ocelot",                     "Ocelot"),
        ("Serval",                     "Serval"),
        ("Clouded_leopard",            "Clouded Leopard"),
        ("Okapi",                      "Okapi"),
        ("Tapir",                      "Tapir"),
        ("Binturong",                  "Binturong"),
        ("Fossa_(animal)",             "Fossa"),
        ("Caracal",                    "Caracal"),
        ("Quokka",                     "Quokka"),
        ("Pangolin",                   "Pangolin"),
    ]

    // MARK: - Fetch Single Main Photo
    //
    // Uses the Wikipedia REST summary API — one simple call that returns a page's
    // title, summary text, and main image. Perfect for our random feed.
    //
    // Example URL: https://en.wikipedia.org/api/rest_v1/page/summary/Snow_leopard

    func fetchMainImage(articleTitle: String, displayName: String) async -> AnimalPhoto? {
        // Percent-encode the title so spaces/special chars work in the URL path.
        // "Snow leopard" → "Snow%20leopard", "Fossa_(animal)" stays as-is since
        // .urlPathAllowed keeps underscores and parentheses.
        guard
            let encoded = articleTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        else { return nil }

        do {
            // `try await` — this line pauses until the download completes or throws an error
            let (data, response) = try await URLSession.shared.data(from: url)

            // Cast to HTTPURLResponse to check the status code
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

            // JSONDecoder maps the raw JSON bytes into our WikiSummaryResponse struct
            let summary = try JSONDecoder().decode(WikiSummaryResponse.self, from: data)

            // Prefer the original high-res image; fall back to the smaller thumbnail
            guard let imageURL = summary.originalimage?.source ?? summary.thumbnail?.source
            else { return nil }

            return AnimalPhoto(
                imageURL: imageURL,
                animalName: displayName,
                articleTitle: articleTitle
            )
        } catch {
            // `error.localizedDescription` gives a human-readable error string
            print("⚠️ fetchMainImage failed for \(articleTitle): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Fetch Multiple Photos for One Animal
    //
    // This is a two-step process because the Wikipedia API separates
    // "what files are in this article?" from "what are the download URLs for those files?".
    //
    // Step 1 → get a list of File: titles from the article (e.g. "File:Snow leopard.jpg")
    // Step 2 → get the actual https://upload.wikimedia.org/... URL for each file
    //
    // We only fetch up to `limit` photos and filter out non-photo files (maps, icons, etc.)

    func fetchArticlePhotos(
        articleTitle: String,
        displayName: String,
        limit: Int = 10
    ) async -> [AnimalPhoto] {

        // Build Step 1 URL
        guard
            let encodedTitle = articleTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let listURL = URL(string: "https://en.wikipedia.org/w/api.php?action=query&titles=\(encodedTitle)&prop=images&imlimit=50&format=json")
        else { return [] }

        do {
            // ── Step 1: Get image file names ───────────────────────────────────

            let (listData, _) = try await URLSession.shared.data(from: listURL)
            let listResponse = try JSONDecoder().decode(ArticleImagesResponse.self, from: listData)

            // `.values` gives us the dict's values without caring about keys
            // `.first` picks the only page result (we only queried one article)
            guard let allImages = listResponse.query.pages.values.first?.images else {
                return []
            }

            // Filter: keep only JPEG/PNG photos, skip icons, maps, range maps, flags, logos
            let photoTitles: [String] = allImages
                .map { $0.title }
                .filter { title in
                    let t = title.lowercased()
                    let isPhoto = t.hasSuffix(".jpg") || t.hasSuffix(".jpeg") || t.hasSuffix(".png")
                    let notJunk = !t.contains("flag") && !t.contains("icon") &&
                                  !t.contains("logo") && !t.contains("map") &&
                                  !t.contains("range") && !t.contains("symbol") &&
                                  !t.contains("silhouette") && !t.contains("distribution") &&
                                  !t.contains("taxonomy")
                    return isPhoto && notJunk
                }

            guard !photoTitles.isEmpty else { return [] }

            // ── Step 2: Fetch download URLs in batches of 10 ──────────────────
            //
            // The MediaWiki API accepts up to 10 titles per request when
            // using `prop=imageinfo`. We use our `chunked(into:)` extension
            // to split the list and make one request per chunk.

            var photos: [AnimalPhoto] = []

            for chunk in chunked(photoTitles, into: 10) {
                guard photos.count < limit else { break }

                // Join titles with | as the MediaWiki API expects
                let titlesParam = chunk.joined(separator: "|")
                guard
                    let encodedTitles = titlesParam.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let infoURL = URL(string:
                        "https://en.wikipedia.org/w/api.php"
                        + "?action=query"
                        + "&titles=\(encodedTitles)"
                        + "&prop=imageinfo"
                        + "&iiprop=url"          // include URL in the response
                        + "&iiurlwidth=1200"     // also provide a 1200px-wide thumbnail URL
                        + "&format=json"
                    )
                else { continue }

                let (infoData, _) = try await URLSession.shared.data(from: infoURL)
                let infoResponse = try JSONDecoder().decode(ImageInfoResponse.self, from: infoData)

                for page in infoResponse.query.pages.values {
                    // thumburl = the 1200px thumbnail; url = original (could be 50MB+)
                    // We strongly prefer the thumbnail for performance on iPad
                    if let imageURL = page.imageinfo?.first?.thumburl
                                   ?? page.imageinfo?.first?.url {
                        photos.append(AnimalPhoto(
                            imageURL: imageURL,
                            animalName: displayName,
                            articleTitle: articleTitle
                        ))
                    }
                }
            }

            // Shuffle so we see photos in a random order each time, then cap at limit
            return Array(photos.shuffled().prefix(limit))

        } catch {
            print("⚠️ fetchArticlePhotos failed for \(articleTitle): \(error.localizedDescription)")
            return []
        }
    }
}
