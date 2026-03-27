import Foundation

enum APIError: Error {
    case invalidURL
    case decodingFailed
    case requestFailed(Error)
}

private struct ServersResponse: Codable {
    let servers: [VPNServer]
}

final class APIClient {
    static func fetchServers(from url: URL, completion: @escaping (Result<[VPNServer], Error>) -> Void) {
        let task = URLSession.shared.dataTask(with: url) { data, _, error in
            if let error {
                completion(.failure(APIError.requestFailed(error)))
                return
            }

            guard let data else {
                completion(.failure(APIError.invalidURL))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(ServersResponse.self, from: data)
                completion(.success(decoded.servers))
            } catch {
                completion(.failure(APIError.decodingFailed))
            }
        }

        task.resume()
    }

    static func loadServersFromBundle() -> [VPNServer] {
        guard
            let url = Bundle.main.url(forResource: "servers", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode(ServersResponse.self, from: data)
        else {
            return []
        }

        return decoded.servers
    }
}
