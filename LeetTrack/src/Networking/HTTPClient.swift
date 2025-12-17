import Foundation

enum HTTPError: Error, LocalizedError {
    case invalidResponse
    case badStatus(code: Int, body: Data)
    case decoding(Error)
    case transport(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid HTTP response."
        case .badStatus(let code, let body):
            // Try to show a readable error message if backend returns JSON error
            if let str = String(data: body, encoding: .utf8), !str.isEmpty {
                return "HTTP \(code): \(str)"
            }
            return "HTTP \(code)"
        case .decoding(let err):
            return "Failed to decode JSON: \(err.localizedDescription)"
        case .transport(let err):
            return "Network error: \(err.localizedDescription)"
        }
    }
}

final class HTTPClient {
    private let session: URLSession
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
    }
    
    func get<T: Decodable>(_ url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let http = response as? HTTPURLResponse else {
                throw HTTPError.invalidResponse
            }
            
            guard (200...299).contains(http.statusCode) else {
                throw HTTPError.badStatus(code: http.statusCode, body: data)
            }
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw HTTPError.decoding(error)
            }
        } catch let err as HTTPError {
            throw err
        } catch {
            throw HTTPError.transport(error)
        }
    }
    
}
