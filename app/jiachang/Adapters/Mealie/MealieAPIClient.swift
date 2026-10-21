import Foundation

enum MealieAPIError: LocalizedError, Equatable {
    case invalidServer
    case unauthorized
    case server(Int, String)
    case invalidResponse
    case decoding

    var errorDescription: String? {
        switch self {
        case .invalidServer: return "服务器地址无效"
        case .unauthorized: return "用户名或密码不对"
        case .server(let code, _): return "服务器暂时不可用（\(code)）"
        case .invalidResponse: return "服务器响应异常"
        case .decoding: return "菜谱数据格式不兼容"
        }
    }
}

protocol HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

struct URLSessionTransport: HTTPTransport {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw MealieAPIError.invalidResponse
        }
        return (data, http)
    }
}

struct MealieAPIClient {
    let baseURL: URL
    var token: String?
    var transport: any HTTPTransport = URLSessionTransport()

    func send<Response: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        contentType: String? = nil
    ) async throws -> Response {
        let data = try body.map { try JSONEncoder().encode(ErasedEncodable($0)) }
        let request = try makeRequest(
            path,
            method: method,
            data: data,
            contentType: contentType ?? (data == nil ? nil : "application/json")
        )
        let responseData = try await execute(request)
        do {
            return try JSONDecoder().decode(Response.self, from: responseData)
        } catch {
            throw MealieAPIError.decoding
        }
    }

    func sendVoid(_ path: String, method: String) async throws {
        let request = try makeRequest(path, method: method, data: nil, contentType: nil)
        _ = try await execute(request)
    }

    func raw(_ path: String) async throws -> Data {
        try await execute(makeRequest(path, method: "GET", data: nil, contentType: nil))
    }

    func login(username: String, password: String) async throws -> String {
        let form = "username=\(encode(username))&password=\(encode(password))"
        let request = try makeRequest(
            "/api/auth/token",
            method: "POST",
            data: form.data(using: .utf8),
            contentType: "application/x-www-form-urlencoded"
        )
        let data = try await execute(request)
        do {
            return try JSONDecoder().decode(MealieLoginDTO.self, from: data).access_token
        } catch {
            throw MealieAPIError.decoding
        }
    }

    func uploadImage(slug: String, jpeg: Data) async throws {
        let boundary = "jiachang-\(UUID().uuidString)"
        var data = Data()
        data.append(formField(name: "extension", value: "jpg", boundary: boundary))
        data.append(fileField(name: "image", filename: "photo.jpg", data: jpeg, boundary: boundary))
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        let request = try makeRequest(
            "/api/recipes/\(slug)/image",
            method: "PUT",
            data: data,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
        _ = try await execute(request)
    }

    private func makeRequest(_ path: String, method: String, data: Data?, contentType: String?) throws -> URLRequest {
        guard let url = URL(string: path, relativeTo: baseURL)?.absoluteURL else {
            throw MealieAPIError.invalidServer
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = data
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let contentType { request.setValue(contentType, forHTTPHeaderField: "Content-Type") }
        if let token { request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }
        return request
    }

    private func execute(_ request: URLRequest) async throws -> Data {
        let (data, response) = try await transport.data(for: request)
        if response.statusCode == 401 { throw MealieAPIError.unauthorized }
        guard (200..<300).contains(response.statusCode) else {
            throw MealieAPIError.server(response.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        return data
    }

    private func encode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
    }

    private func formField(name: String, value: String, boundary: String) -> Data {
        "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n\(value)\r\n".data(using: .utf8)!
    }

    private func fileField(name: String, filename: String, data: Data, boundary: String) -> Data {
        var value = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"; filename=\"\(filename)\"\r\nContent-Type: image/jpeg\r\n\r\n".data(using: .utf8)!
        value.append(data)
        value.append("\r\n".data(using: .utf8)!)
        return value
    }
}

private struct ErasedEncodable: Encodable {
    let encodeBody: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        encodeBody = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encodeBody(encoder)
    }
}
