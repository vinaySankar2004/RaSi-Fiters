import Foundation

extension APIClient {

    struct TokenRefreshResponse: Decodable {
        let token: String
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case token
            case refreshToken = "refresh_token"
        }
    }

    struct RegisterResponse: Decodable {
        let message: String?
        let memberId: String?
        let username: String?
        let memberName: String?

        enum CodingKeys: String, CodingKey {
            case message
            case memberId = "member_id"
            case username
            case memberName = "member_name"
        }
    }

    struct ChangePasswordResponse: Decodable {
        let message: String
    }

    struct DeleteAccountResponse: Decodable {
        let message: String
    }

    // Legacy login (kept if needed elsewhere)
    func login(username: String, password: String) async throws -> AuthResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/login"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["username": username, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    // New global-role-aware login
    func loginGlobal(identifier: String, password: String) async throws -> AuthResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/login/global"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["identifier": identifier, "password": password]
        request.httpBody = try JSONEncoder().encode(body)

        let data = try await data(for: request)
        return try JSONDecoder().decode(AuthResponse.self, from: data)
    }

    func registerAccount(
        firstName: String,
        lastName: String,
        username: String,
        email: String,
        password: String,
        gender: String?
    ) async throws -> RegisterResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: String] = [
            "first_name": firstName,
            "last_name": lastName,
            "username": username,
            "email": email,
            "password": password
        ]
        if let gender, !gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body["gender"] = gender
        }

        request.httpBody = try JSONEncoder().encode(body)

        let data = try await data(for: request)
        return try JSONDecoder().decode(RegisterResponse.self, from: data)
    }

    func refreshSession(refreshToken: String) async throws -> TokenRefreshResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/refresh"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await rawData(for: request)
        guard 200..<300 ~= response.statusCode else {
            let message = extractErrorMessage(from: data) ?? "Request failed (\(response.statusCode))"
            throw APIHTTPError(statusCode: response.statusCode, message: message)
        }
        return try JSONDecoder().decode(TokenRefreshResponse.self, from: data)
    }

    func logout(refreshToken: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/logout"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await rawData(for: request)
        guard 200..<300 ~= response.statusCode else {
            let message = extractErrorMessage(from: data) ?? "Request failed (\(response.statusCode))"
            throw APIError(message: message)
        }
    }

    /// Changes the password for the authenticated user
    func changePassword(token: String, newPassword: String) async throws -> ChangePasswordResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/change-password"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["new_password": newPassword]
        request.httpBody = try JSONEncoder().encode(body)
        let data = try await data(for: request)
        return try JSONDecoder().decode(ChangePasswordResponse.self, from: data)
    }

    /// Permanently deletes the authenticated user's account and all associated data
    func deleteAccount(token: String) async throws -> DeleteAccountResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("auth/account"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(DeleteAccountResponse.self, from: data)
    }
}
