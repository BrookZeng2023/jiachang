import XCTest
@testable import jiachang

final class MealieFailureTests: XCTestCase {
    func testUnauthorizedBecomesReadableAuthenticationError() async {
        let client = MealieAPIClient(
            baseURL: URL(string: "https://example.test")!,
            transport: StubTransport(status: 401)
        )

        do {
            _ = try await client.raw("/api/recipes")
            XCTFail("Expected unauthorized")
        } catch let error as MealieAPIError {
            XCTAssertEqual(error, .unauthorized)
            XCTAssertEqual(error.localizedDescription, "用户名或密码不对")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testServerFailureKeepsStatusCode() async {
        let client = MealieAPIClient(
            baseURL: URL(string: "https://example.test")!,
            transport: StubTransport(status: 503)
        )

        do {
            _ = try await client.raw("/api/recipes")
            XCTFail("Expected server error")
        } catch let error as MealieAPIError {
            XCTAssertEqual(error, .server(503, "failure"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

private struct StubTransport: HTTPTransport {
    let status: Int

    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data("failure".utf8), response)
    }
}
