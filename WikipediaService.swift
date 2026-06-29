// WikipediaService.swift

import Foundation

// MARK: - Private JSON Response Types
// Defined here (not in Models.swift) so they stay out of @MainActor inferred contexts.

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

// Response from the category members API
private struct CategoryMembersResponse: Decodable {
    let query: QueryBody?
    struct QueryBody: Decodable {
        let categorymembers: [Member]
    }
    struct Member: Decodable {
        let title: String   // Human-readable title with spaces, e.g. "Snow leopard"
    }
}

actor WikipediaService {

    // MARK: - Starter Pool (used immediately on launch before categories load)

    static let starterPool: [(title: String, name: String)] = [
        ("Lion", "Lion"), ("Tiger", "Tiger"), ("African bush elephant", "African Elephant"),
        ("Giraffe", "Giraffe"), ("Emperor penguin", "Emperor Penguin"),
        ("Common bottlenose dolphin", "Bottlenose Dolphin"), ("Gray wolf", "Gray Wolf"),
        ("Brown bear", "Brown Bear"), ("Bald eagle", "Bald Eagle"),
        ("Giant Pacific octopus", "Giant Octopus"), ("Cheetah", "Cheetah"),
        ("Western gorilla", "Gorilla"), ("Polar bear", "Polar Bear"),
        ("Snow leopard", "Snow Leopard"), ("Red fox", "Red Fox"),
        ("Giant panda", "Giant Panda"), ("Blue whale", "Blue Whale"),
        ("African wild dog", "African Wild Dog"), ("Komodo dragon", "Komodo Dragon"),
        ("Mantis shrimp", "Mantis Shrimp"), ("Axolotl", "Axolotl"),
        ("Narwhal", "Narwhal"), ("Fennec fox", "Fennec Fox"), ("Meerkat", "Meerkat"),
        ("Capybara", "Capybara"), ("Platypus", "Platypus"), ("Cassowary", "Cassowary"),
        ("Jaguar", "Jaguar"), ("Ring-tailed lemur", "Ring-Tailed Lemur"),
        ("Mandrill", "Mandrill"), ("Ocelot", "Ocelot"), ("Serval", "Serval"),
        ("Clouded leopard", "Clouded Leopard"), ("Okapi", "Okapi"),
        ("Tapir", "Tapir"), ("Binturong", "Binturong"), ("Fossa (animal)", "Fossa"),
        ("Caracal", "Caracal"), ("Quokka", "Quokka"), ("Pangolin", "Pangolin"),
    ]

    // MARK: - Animal Categories
    //
    // Wikipedia categories that contain species articles with good photos.
    // Each category can have hundreds to thousands of articles.
    // We fetch up to 500 titles per category using the MediaWiki API.

    static let animalCategories: [String] = [
        "Mammals",
        "Birds",
        "Reptiles",
        "Amphibians",
        "Sharks",
        "Cetaceans",
        "Primates",
        "Marsupials",
        "Felidae",
        "Canidae",
        "Bears",
        "Deer",
        "Bovidae",
        "Eagles",
        "Owls",
        "Penguins",
        "Parrots",
        "Kingfishers",
        "Hummingbirds",
        "Flamingos",
        "Crocodilians",
        "Monitor lizards",
        "Chameleons",
        "Vipers",
        "Frogs",
        "Salamanders",
        "Butterflies",
        "Beetles",
        "Dragonflies",
        "Spiders",
        "Scorpions",
        "Octopuses",
        "Nudibranchs",
        "Sea anemones",
        "Jellyfish",
        "Starfish",
    ]

    // MARK: - Fetch Titles from a Wikipedia Category
    //
    // Calls the MediaWiki "categorymembers" list API to get article titles
    // in a given category. Returns up to `limit` (title, name) pairs.
    //
    // Wikipedia article titles use spaces (e.g. "Snow leopard"), not underscores.
    // Both the REST summary API and MediaWiki API accept titles with spaces,
    // so we use the title directly as both the article key and display name.

    nonisolated func fetchCategoryTitles(
        category: String,
        limit: Int = 500
    ) async -> [(title: String, name: String)] {

        guard
            let encodedCategory = "Category:\(category)"
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string:
                "https://en.wikipedia.org/w/api.php"
                + "?action=query"
                + "&list=categorymembers"
                + "&cmtitle=\(encodedCategory)"
                + "&cmlimit=\(limit)"
                + "&cmtype=page"      // pages only, not subcategories or files
                + "&cmnamespace=0"    // main article namespace only
                + "&format=json"
            )
        else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(CategoryMembersResponse.self, from: data)
            let members = response.query?.categorymembers ?? []

            return members
                .map { $0.title }
                .filter { isLikelyAnimalArticle($0) }
                .map { title in (title: title, name: title) }  // title is already human-readable

        } catch {
            print("⚠️ fetchCategoryTitles failed for \(category): \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Fetch Single Main Photo

    nonisolated func fetchMainImage(articleTitle: String, displayName: String) async -> AnimalPhoto? {
        guard
            let encoded = articleTitle.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
            let url = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)")
        else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
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
            let listURL = URL(string: "https://en.wikipedia.org/w/api.php?action=query&titles=\(encodedTitle)&prop=images&imlimit=50&format=json")
        else { return [] }

        do {
            let (listData, _) = try await URLSession.shared.data(from: listURL)
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
                    let encodedTitles = titlesParam.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                    let infoURL = URL(string:
                        "https://en.wikipedia.org/w/api.php"
                        + "?action=query&titles=\(encodedTitles)"
                        + "&prop=imageinfo&iiprop=url&iiurlwidth=1200&format=json"
                    )
                else { continue }

                let (infoData, _) = try await URLSession.shared.data(from: infoURL)
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
}

// MARK: - Title Filter
//
// Quick check to skip obvious non-species articles that appear in animal categories.
// e.g. "List of mammals of Australia", "Mammalogy", "Conservation biology".
// Not exhaustive — fetchMainImage handles the rest by returning nil for articles
// without a species photo.

private func isLikelyAnimalArticle(_ title: String) -> Bool {
    let t = title.lowercased()
    let skipPrefixes = ["list of", "lists of", "index of", "outline of", "history of",
                        "evolution of", "conservation of", "ecology of", "taxonomy of"]
    let skipSuffixes = ["ology", "ography", "onomy", "istry", "etics"]
    let skipWords = ["anatomy", "behavior", "behaviour", "distribution", "fossil",
                     "prehistoric", "extinct", "classification", "phylogen"]

    if skipPrefixes.contains(where: { t.hasPrefix($0) }) { return false }
    if skipSuffixes.contains(where: { t.hasSuffix($0) }) { return false }
    if skipWords.contains(where: { t.contains($0) }) { return false }
    if title.count < 3 { return false }

    return true
}
