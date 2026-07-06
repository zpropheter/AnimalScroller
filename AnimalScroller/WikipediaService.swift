// WikipediaService.swift

import Foundation

// MARK: - Private JSON Response Types
//
// Kept private at file scope (before the actor) to minimise Swift 6
// @MainActor inference.  These produce "Main actor-isolated conformance
// to 'Decodable'" warnings in Swift 5 mode; they are harmless warnings
// today and will need a language-level fix (SE-0420 / SE-0434) when the
// project moves to Swift 6 mode.

private struct WikiSummaryResponse: Decodable {
    let title: String
    let thumbnail: WikiImage?
    let originalimage: WikiImage?
    struct WikiImage: Decodable {
        let source: URL
        let width: Int
        let height: Int
    }
}

private struct ArticleImagesResponse: Decodable {
    let query: QueryBody
    struct QueryBody: Decodable {
        let pages: [String: PageResult]
    }
    struct PageResult: Decodable {
        let images: [ImageEntry]?
    }
    struct ImageEntry: Decodable {
        let title: String
    }
}

private struct ImageInfoResponse: Decodable {
    let query: QueryBody
    struct QueryBody: Decodable {
        let pages: [String: PageResult]
    }
    struct PageResult: Decodable {
        let title: String
        let imageinfo: [ImageInfo]?
    }
    struct ImageInfo: Decodable {
        let url: URL
        let thumburl: URL?
    }
}

private struct ExtMetadataResponse: Decodable {
    let query: QueryBody
    struct QueryBody: Decodable {
        let pages: [String: PageResult]
    }
    struct PageResult: Decodable {
        let imageinfo: [ImageInfoExt]?
    }
    struct ImageInfoExt: Decodable {
        let extmetadata: ExtMetadata?
    }
    struct ExtMetadata: Decodable {
        let artist: MetaValue?
        let licenseShortName: MetaValue?
        let licenseUrl: MetaValue?
        struct MetaValue: Decodable {
            let value: String
        }
        // Wikipedia extmetadata uses PascalCase JSON keys
        enum CodingKeys: String, CodingKey {
            case artist           = "Artist"
            case licenseShortName = "LicenseShortName"
            case licenseUrl       = "LicenseUrl"
        }
    }
}

// MARK: - Service

actor WikipediaService {

    // MARK: - Shared HTTP Session

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.httpAdditionalHeaders = [
            "User-Agent": "AnimalScroller/1.0 (iOS; animal photo viewer; zpropheter@hotmail.com)"
        ]
        return URLSession(configuration: config)
    }()

    // MARK: - Fetch Single Main Photo

    nonisolated func fetchMainImage(articleTitle: String, displayName: String) async -> AnimalPhoto? {
        guard
            let encoded = articleTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        else { return nil }

        do {
            let (data, response) = try await WikipediaService.session.data(from: url)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }

            let summary = try JSONDecoder().decode(WikiSummaryResponse.self, from: data)
            guard let imageURL = summary.originalimage?.source ?? summary.thumbnail?.source
            else { return nil }

            return AnimalPhoto(imageURL: imageURL, animalName: displayName, articleTitle: articleTitle)
        } catch {
            print("⚠️ fetchMainImage failed for \(articleTitle): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Fetch Multiple Photos for One Animal

    nonisolated func fetchArticlePhotos(
        articleTitle: String,
        displayName: String,
        limit: Int = 10
    ) async -> [AnimalPhoto] {

        guard
            let encodedTitle = articleTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let listURL = URL(string:
                "https://en.wikipedia.org/w/api.php"
                + "?action=query&titles=\(encodedTitle)"
                + "&prop=images&imlimit=50&format=json"
            )
        else { return [] }

        do {
            let (listData, _) = try await WikipediaService.session.data(from: listURL)
            let listResponse = try JSONDecoder().decode(ArticleImagesResponse.self, from: listData)

            guard let allImages = listResponse.query.pages.values.first?.images else { return [] }

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

            var photos: [AnimalPhoto] = []

            for batchStart in stride(from: 0, to: photoTitles.count, by: 10) {
                guard photos.count < limit else { break }
                let batchEnd = Swift.min(batchStart + 10, photoTitles.count)
                let chunk = Array(photoTitles[batchStart..<batchEnd])
                let titlesParam = chunk.joined(separator: "|")

                guard
                    let encodedTitles = titlesParam.addingPercentEncoding(
                        withAllowedCharacters: .urlQueryAllowed),
                    let infoURL = URL(string:
                        "https://en.wikipedia.org/w/api.php"
                        + "?action=query&titles=\(encodedTitles)"
                        + "&prop=imageinfo&iiprop=url&iiurlwidth=1200&format=json"
                    )
                else { continue }

                let (infoData, _) = try await WikipediaService.session.data(from: infoURL)
                let infoResponse = try JSONDecoder().decode(ImageInfoResponse.self, from: infoData)

                for page in infoResponse.query.pages.values {
                    if let imageURL = page.imageinfo?.first?.thumburl ?? page.imageinfo?.first?.url {
                        photos.append(AnimalPhoto(
                            imageURL: imageURL,
                            animalName: displayName,
                            articleTitle: articleTitle
                        ))
                    }
                }
            }

            return Array(photos.shuffled().prefix(limit))

        } catch {
            print("⚠️ fetchArticlePhotos failed for \(articleTitle): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Fetch Image Attribution

    nonisolated func fetchAttribution(for imageURL: URL) async -> AttributionInfo? {
        guard let filename = wikimediaFilename(from: imageURL) else { return nil }

        let fileTitle = "File:\(filename)"
        guard
            let encoded = fileTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string:
                "https://en.wikipedia.org/w/api.php"
                + "?action=query&titles=\(encoded)"
                + "&prop=imageinfo"
                + "&iiprop=extmetadata"
                + "&iiextmetadatafilter=Artist|LicenseShortName|LicenseUrl"
                + "&format=json"
            )
        else { return nil }

        do {
            let (data, _) = try await WikipediaService.session.data(from: url)
            let response = try JSONDecoder().decode(ExtMetadataResponse.self, from: data)

            guard
                let page = response.query.pages.values.first,
                let meta = page.imageinfo?.first?.extmetadata
            else { return nil }

            let author     = meta.artist.map { wikimediaStripHTML($0.value) } ?? "Unknown"
            let license    = meta.licenseShortName?.value ?? "Unknown license"
            let licenseURL = meta.licenseUrl.flatMap { URL(string: $0.value) }

            let encodedTitle = fileTitle.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed) ?? fileTitle
            let filePageURL = URL(string: "https://commons.wikimedia.org/wiki/\(encodedTitle)")

            return AttributionInfo(
                author: author,
                license: license,
                licenseURL: licenseURL,
                filePageURL: filePageURL
            )
        } catch {
            print("⚠️ fetchAttribution failed for \(filename): \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - File-scope helpers
//
// Defined outside the actor so they aren't actor-isolated.
// (They do produce "Main actor-isolated global function" warnings in
// Swift 5 mode with strict concurrency — same category as the Decodable
// warnings above, harmless until Swift 6 mode is enabled.)

private func wikimediaFilename(from url: URL) -> String? {
    let parts = url.pathComponents
    guard parts.count >= 2 else { return nil }
    if parts.contains("thumb") {
        // .../thumb/X/XX/Filename.jpg/1280px-Filename.jpg — real name is second-to-last
        return parts[parts.count - 2]
    }
    return parts.last
}

private func wikimediaStripHTML(_ string: String) -> String {
    string
        .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}
