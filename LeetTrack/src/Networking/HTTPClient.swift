import Foundation

/// Lightweight HTTP client with ETag/Last-Modified and time-based caching support.
final class HTTPClient {
    struct CachedEntry<T: Decodable> {
        let value: T
        let timestamp: Date
        let etag: String?
        let lastModified: String?
    }

    enum HTTPClientError: Error {
        case invalidURL
        case badResponse(statusCode: Int)
        case rateLimited
        case tooManyRequests
    }

    private let session: URLSession
    private let jsonDecoder: JSONDecoder

    /// Simple in-memory cache scoped to process lifetime
    private var cache: [String: Any] = [:]
    private let cacheTTLSeconds: TimeInterval

    init(session: URLSession = .shared, cacheTTLSeconds: TimeInterval = 300) {
        self.session = session
        self.cacheTTLSeconds = cacheTTLSeconds
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.jsonDecoder = decoder
    }

    func get<T: Decodable>(_ url: URL, responseType: T.Type) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        // Attach conditional headers if cached
        if let cached: CachedEntry<T> = cachedEntry(for: url) {
            if let etag = cached.etag {
                request.addValue(etag, forHTTPHeaderField: "If-None-Match")
            }
            if let lastModified = cached.lastModified {
                request.addValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
            }

            // Time-based cache short-circuit
            if Date().timeIntervalSince(cached.timestamp) < cacheTTLSeconds {
                return cached.value
            }
        }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw HTTPClientError.badResponse(statusCode: -1) }

        if http.statusCode == 304, let cached: CachedEntry<T> = cachedEntry(for: url) {
            return cached.value
        }

        guard (200..<300).contains(http.statusCode) else {
            if http.statusCode == 429 {
                throw HTTPClientError.rateLimited
            } else if http.statusCode == 403 {
                throw HTTPClientError.tooManyRequests
            } else {
                throw HTTPClientError.badResponse(statusCode: http.statusCode)
            }
        }

        let decoded = try jsonDecoder.decode(T.self, from: data)
        let etag = http.value(forHTTPHeaderField: "ETag")
        let lastModified = http.value(forHTTPHeaderField: "Last-Modified")
        setCache(value: decoded, url: url, etag: etag, lastModified: lastModified)
        return decoded
    }

    private func cacheKey(for url: URL) -> String { url.absoluteString }

    private func cachedEntry<T: Decodable>(for url: URL) -> CachedEntry<T>? {
        cache[cacheKey(for: url)] as? CachedEntry<T>
    }

    private func setCache<T: Decodable>(value: T, url: URL, etag: String?, lastModified: String?) {
        let entry = CachedEntry(value: value, timestamp: Date(), etag: etag, lastModified: lastModified)
        cache[cacheKey(for: url)] = entry
    }
}


