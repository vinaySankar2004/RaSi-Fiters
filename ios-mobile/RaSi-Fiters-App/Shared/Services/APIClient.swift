import Foundation

struct APIError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    var tokenUpdateHandler: ((String, String?) -> Void)?
    var authFailureHandler: (() -> Void)?

    init(baseURL: URL = APIConfig.activeBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // Quick connectivity check
    func healthCheck() async throws -> String {
        let request = URLRequest(url: baseURL.appendingPathComponent("test"))
        let data = try await data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["message"] as? String ?? "OK"
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

    struct TokenRefreshResponse: Decodable {
        let token: String
        let refreshToken: String?

        enum CodingKeys: String, CodingKey {
            case token
            case refreshToken = "refresh_token"
        }
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
            throw APIError(message: message)
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

    // Analytics summary (period: day | week | month | year)
    func fetchAnalyticsSummary(token: String, period: String, programId: String?) async throws -> AnalyticsSummary {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/summary"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "period", value: period)]
        if let programId {
            items.append(URLQueryItem(name: "programId", value: programId))
        }
        components.queryItems = items

        guard let url = components.url else {
            throw APIError(message: "Invalid analytics URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data = try await data(for: request)
        return try JSONDecoder().decode(AnalyticsSummary.self, from: data)
    }

    struct MemberDTO: Decodable, Identifiable {
        let id: String
        let member_name: String
        let username: String?
        let gender: String?
        let date_of_birth: String?
        let date_joined: String?
    }

    struct WorkoutDTO: Decodable {
        let workout_name: String
    }

    // Program-specific workout with source (global/custom) and visibility
    struct ProgramWorkoutDTO: Decodable, Identifiable {
        let id: String
        let workout_name: String
        let source: String  // "global" or "custom"
        let is_hidden: Bool
        let library_workout_id: String?

        var isGlobal: Bool { source == "global" }
        var isCustom: Bool { source == "custom" }
    }

    struct ProgramWorkoutResponse: Decodable {
        let id: String
        let workout_name: String
        let source: String
        let is_hidden: Bool
        let library_workout_id: String?
        let message: String?
    }

    struct ProgramDTO: Decodable, Identifiable, Hashable {
        let id: String
        let name: String
        let status: String?
        let start_date: String?
        let end_date: String?
        let active_members: Int?
        let total_members: Int?
        let progress_percent: Int?
        let enrollments_closed: Bool?
        let my_role: String?
        let my_status: String?
    }

    struct MTDParticipationDTO: Decodable {
        let total_members: Int
        let active_members: Int
        let participation_pct: Double
        let change_pct: Double
    }

    struct TotalWorkoutsMTDDTO: Decodable {
        let total_workouts: Int
        let change_pct: Double
    }

    struct TotalDurationMTDDTO: Decodable {
        let total_minutes: Int
        let change_pct: Double
    }

    struct AvgDurationMTDDTO: Decodable {
        let avg_minutes: Int
        let change_pct: Double
    }

    struct ActivityTimelinePoint: Decodable, Identifiable {
        let id = UUID()
        let date: String
        let label: String
        let workouts: Int
        let active_members: Int
    }

    struct ActivityTimelineResponse: Decodable {
        let mode: String
        let label: String
        let daily_average: Double
        let buckets: [ActivityTimelinePoint]
    }

    struct HealthTimelinePoint: Decodable, Identifiable {
        let id = UUID()
        let date: String
        let label: String
        let sleep_hours: Double
        let food_quality: Double
    }

    struct HealthTimelineResponse: Decodable {
        let mode: String
        let label: String
        let daily_average_sleep: Double
        let daily_average_food: Double
        let buckets: [HealthTimelinePoint]
        let start: String?
        let end: String?
    }

    struct DistributionByDayDTO: Decodable {
        let Sunday: Int
        let Monday: Int
        let Tuesday: Int
        let Wednesday: Int
        let Thursday: Int
        let Friday: Int
        let Saturday: Int
    }

    struct WorkoutTypeDTO: Decodable, Identifiable {
        let id = UUID()
        let workout_name: String
        let sessions: Int
        let total_duration: Int
        let avg_duration_minutes: Int
    }

    struct WorkoutTypesTotalDTO: Decodable {
        let total_types: Int
    }

    struct WorkoutTypeMostPopularDTO: Decodable {
        let workout_name: String?
        let sessions: Int
    }

    struct WorkoutTypeLongestDurationDTO: Decodable {
        let workout_name: String?
        let avg_minutes: Int
    }

    struct WorkoutTypeHighestParticipationDTO: Decodable {
        let workout_name: String?
        let participants: Int
        let participation_pct: Double
        let total_members: Int
    }

    func fetchMembers(token: String) async throws -> [MemberDTO] {
        var request = URLRequest(url: baseURL.appendingPathComponent("members"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([MemberDTO].self, from: data)
    }

    func fetchProgramMembers(token: String, programId: String) async throws -> [MemberDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent("program-memberships/members"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else { throw APIError(message: "Invalid program members URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([MemberDTO].self, from: data)
    }

    /// Fetches members NOT enrolled in the specified program (available for enrollment)
    func fetchAvailableMembers(token: String, programId: String) async throws -> [MemberDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent("program-memberships/available"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else { throw APIError(message: "Invalid available members URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([MemberDTO].self, from: data)
    }

    struct EnrollMemberResponse: Decodable {
        let member_id: String
        let member_name: String
        let username: String
        let gender: String?
        let date_of_birth: String?
        let date_joined: String?
        let program_id: String
        let message: String?
    }

    /// Enrolls an existing member into a program (creates ProgramMembership only)
    func enrollExistingMember(token: String, memberId: String, programId: String, joinedAt: String?) async throws -> EnrollMemberResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships/enroll"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "member_id": memberId,
            "program_id": programId
        ]
        if let joinedAt { body["joined_at"] = joinedAt }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(EnrollMemberResponse.self, from: data)
    }

    func fetchWorkouts(token: String) async throws -> [WorkoutDTO] {
        var request = URLRequest(url: baseURL.appendingPathComponent("workouts"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([WorkoutDTO].self, from: data)
    }

    // MARK: - Program Workouts (per-program workout management)

    func fetchProgramWorkouts(token: String, programId: String) async throws -> [ProgramWorkoutDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent("program-workouts"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else { throw APIError(message: "Invalid program workouts URL") }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([ProgramWorkoutDTO].self, from: data)
    }

    func toggleProgramWorkoutVisibility(token: String, programId: String, libraryWorkoutId: String) async throws -> ProgramWorkoutResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-workouts/toggle-visibility"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "program_id": programId,
            "library_workout_id": libraryWorkoutId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(ProgramWorkoutResponse.self, from: data)
    }

    func toggleCustomWorkoutVisibility(token: String, workoutId: String) async throws -> ProgramWorkoutResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-workouts/\(workoutId)/toggle-visibility"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(ProgramWorkoutResponse.self, from: data)
    }

    func addCustomProgramWorkout(token: String, programId: String, workoutName: String) async throws -> ProgramWorkoutResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-workouts/custom"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "program_id": programId,
            "workout_name": workoutName
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(ProgramWorkoutResponse.self, from: data)
    }

    func editCustomProgramWorkout(token: String, workoutId: String, workoutName: String) async throws -> ProgramWorkoutResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-workouts/\(workoutId)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body = ["workout_name": workoutName]
        request.httpBody = try JSONEncoder().encode(body)
        let data = try await data(for: request)
        return try JSONDecoder().decode(ProgramWorkoutResponse.self, from: data)
    }

    func deleteCustomProgramWorkout(token: String, workoutId: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-workouts/\(workoutId)"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await data(for: request)
    }

    func fetchPrograms(token: String) async throws -> [ProgramDTO] {
        var request = URLRequest(url: baseURL.appendingPathComponent("programs"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([ProgramDTO].self, from: data)
    }

    struct DeleteProgramResponse: Decodable {
        let id: String
        let message: String
    }

    func deleteProgram(token: String, programId: String) async throws -> DeleteProgramResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("programs/\(programId)"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(DeleteProgramResponse.self, from: data)
    }

    struct CreateProgramResponse: Decodable {
        let id: String
        let name: String
        let status: String
        let start_date: String?
        let end_date: String?
        let message: String?
    }

    func createProgram(token: String, name: String, status: String, startDate: String?, endDate: String?) async throws -> CreateProgramResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("programs"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "name": name,
            "status": status
        ]
        if let startDate { body["start_date"] = startDate }
        if let endDate { body["end_date"] = endDate }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(CreateProgramResponse.self, from: data)
    }

    func fetchMTDParticipation(token: String, programId: String) async throws -> MTDParticipationDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics-v2/participation/mtd"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else {
            throw APIError(message: "Invalid MTD participation URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(MTDParticipationDTO.self, from: data)
    }

    func fetchTotalWorkoutsMTD(token: String, programId: String) async throws -> TotalWorkoutsMTDDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/workouts/total"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else {
            throw APIError(message: "Invalid total workouts URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(TotalWorkoutsMTDDTO.self, from: data)
    }

    func fetchTotalDurationMTD(token: String, programId: String) async throws -> TotalDurationMTDDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/duration/total"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else {
            throw APIError(message: "Invalid total duration URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(TotalDurationMTDDTO.self, from: data)
    }

    func fetchAvgDurationMTD(token: String, programId: String) async throws -> AvgDurationMTDDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/duration/average"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else {
            throw APIError(message: "Invalid average duration URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(AvgDurationMTDDTO.self, from: data)
    }

    func fetchActivityTimeline(token: String, period: String, programId: String) async throws -> ActivityTimelineResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/timeline"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "programId", value: programId)
        ]
        guard let url = components.url else {
            throw APIError(message: "Invalid timeline URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(ActivityTimelineResponse.self, from: data)
    }

    func fetchHealthTimeline(
        token: String,
        period: String,
        programId: String,
        memberId: String? = nil
    ) async throws -> HealthTimelineResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/health/timeline"), resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "period", value: period),
            URLQueryItem(name: "programId", value: programId)
        ]
        if let memberId {
            items.append(URLQueryItem(name: "memberId", value: memberId))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError(message: "Invalid health timeline URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(HealthTimelineResponse.self, from: data)
    }

    func fetchDistributionByDay(token: String, programId: String) async throws -> DistributionByDayDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/distribution/day"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else {
            throw APIError(message: "Invalid distribution URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(DistributionByDayDTO.self, from: data)
    }

    func fetchWorkoutTypes(token: String, programId: String, memberId: String? = nil, limit: Int = 100) async throws -> [WorkoutTypeDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics/workouts/types"), resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "programId", value: programId),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let memberId {
            items.append(URLQueryItem(name: "memberId", value: memberId))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError(message: "Invalid workout types URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([WorkoutTypeDTO].self, from: data)
    }

    func fetchWorkoutTypesTotal(token: String, programId: String, memberId: String? = nil) async throws -> WorkoutTypesTotalDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics-v2/workouts/types/total"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "programId", value: programId)]
        if let memberId {
            items.append(URLQueryItem(name: "memberId", value: memberId))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError(message: "Invalid workout types total URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(WorkoutTypesTotalDTO.self, from: data)
    }

    func fetchWorkoutTypeMostPopular(token: String, programId: String, memberId: String? = nil) async throws -> WorkoutTypeMostPopularDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics-v2/workouts/types/most-popular"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "programId", value: programId)]
        if let memberId {
            items.append(URLQueryItem(name: "memberId", value: memberId))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError(message: "Invalid workout types most popular URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(WorkoutTypeMostPopularDTO.self, from: data)
    }

    func fetchWorkoutTypeLongestDuration(token: String, programId: String, memberId: String? = nil) async throws -> WorkoutTypeLongestDurationDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics-v2/workouts/types/longest-duration"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "programId", value: programId)]
        if let memberId {
            items.append(URLQueryItem(name: "memberId", value: memberId))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError(message: "Invalid workout types longest duration URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(WorkoutTypeLongestDurationDTO.self, from: data)
    }

    func fetchWorkoutTypeHighestParticipation(token: String, programId: String, memberId: String? = nil) async throws -> WorkoutTypeHighestParticipationDTO {
        var components = URLComponents(url: baseURL.appendingPathComponent("analytics-v2/workouts/types/highest-participation"), resolvingAgainstBaseURL: false)!
        var items = [URLQueryItem(name: "programId", value: programId)]
        if let memberId {
            items.append(URLQueryItem(name: "memberId", value: memberId))
        }
        components.queryItems = items
        guard let url = components.url else {
            throw APIError(message: "Invalid workout types highest participation URL")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(WorkoutTypeHighestParticipationDTO.self, from: data)
    }

    func addWorkoutLog(token: String, memberName: String, workoutName: String, date: String, durationMinutes: Int, programId: String?, memberId: String?) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("workout-logs"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        var body: [String: Any] = [
            "member_name": memberName,
            "workout_name": workoutName,
            "date": date,
            "duration": durationMinutes
        ]
        if let programId { body["program_id"] = programId }
        if let memberId { body["member_id"] = memberId }
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    func addDailyHealthLog(
        token: String,
        programId: String,
        memberId: String?,
        logDate: String,
        sleepHours: Double?,
        foodQuality: Int?
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("daily-health-logs"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "program_id": programId,
            "log_date": logDate
        ]
        if let memberId { body["member_id"] = memberId }
        if let sleepHours { body["sleep_hours"] = sleepHours }
        if let foodQuality { body["food_quality"] = foodQuality }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    func fetchMemberHealthLogs(
        token: String,
        programId: String,
        memberId: String,
        limit: Int = 1000,
        startDate: String? = nil,
        endDate: String? = nil,
        sortBy: String? = nil,
        sortDir: String? = nil
    ) async throws -> MemberHealthLogResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("daily-health-logs"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "programId", value: programId),
            URLQueryItem(name: "memberId", value: memberId),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let startDate { queryItems.append(URLQueryItem(name: "startDate", value: startDate)) }
        if let endDate { queryItems.append(URLQueryItem(name: "endDate", value: endDate)) }
        if let sortBy { queryItems.append(URLQueryItem(name: "sortBy", value: sortBy)) }
        if let sortDir { queryItems.append(URLQueryItem(name: "sortDir", value: sortDir)) }
        components.queryItems = queryItems
        guard let url = components.url else { throw APIError(message: "Invalid daily health logs URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberHealthLogResponse.self, from: data)
    }

    func updateDailyHealthLog(
        token: String,
        programId: String,
        memberId: String?,
        logDate: String,
        sleepHours: Double?,
        foodQuality: Int?
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("daily-health-logs"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "program_id": programId,
            "log_date": logDate
        ]
        if let memberId { body["member_id"] = memberId }
        if let sleepHours { body["sleep_hours"] = sleepHours }
        if let foodQuality { body["food_quality"] = foodQuality }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    func deleteDailyHealthLog(
        token: String,
        programId: String,
        memberId: String?,
        logDate: String
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("daily-health-logs"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "program_id": programId,
            "log_date": logDate
        ]
        if let memberId { body["member_id"] = memberId }
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    struct MemberDetailDTO: Decodable {
        let id: String
        let member_name: String
        let username: String
        let gender: String?
        let date_of_birth: String?
        let date_joined: String?
        let role: String?
        let program_id: String?
    }

    struct MemberMetricsDTO: Decodable, Identifiable {
        let id = UUID()
        let member_id: String
        let member_name: String
        let username: String
        let workouts: Int
        let total_duration: Int
        let avg_duration: Int
        let avg_sleep_hours: Double?
        let active_days: Int
        let workout_types: Int
        let current_streak: Int
        let longest_streak: Int
        let avg_food_quality: Int?
        let mtd_workouts: Int?
        let total_hours: Int?
        let favorite_workout: String?
    }

    struct MemberMetricsResponse: Decodable {
        let program_id: String
        let total: Int
        let filtered: Int
        let sort: String
        let direction: String
        let date_range: DateRangeDTO?
        let members: [MemberMetricsDTO]
    }

    struct DateRangeDTO: Decodable {
        let start: String?
        let end: String?
    }

    struct MemberHistoryPoint: Decodable, Identifiable {
        let id = UUID()
        let date: String
        let label: String
        let workouts: Int
    }

    struct MemberHistoryResponse: Decodable {
        let period: String
        let label: String
        let daily_average: Double
        let start: String
        let end: String
        let buckets: [MemberHistoryPoint]
    }

    struct MemberStreaksResponse: Decodable {
        struct Milestone: Decodable, Identifiable {
            let id = UUID()
            let dayValue: Int
            let achieved: Bool
        }
        let currentStreakDays: Int
        let longestStreakDays: Int
        let milestones: [Milestone]
    }

    struct MemberRecentWorkoutsResponse: Decodable {
        struct Item: Decodable, Identifiable {
            let id: String
            let workoutType: String
            let workoutDate: String
            let durationMinutes: Int
        }
        struct Filters: Decodable {
            let startDate: String?
            let endDate: String?
            let sortBy: String
            let sortDir: String
        }
        let items: [Item]
        let total: Int?
        let filters: Filters?
    }

    struct MemberHealthLogResponse: Decodable {
        struct Item: Decodable, Identifiable {
            let id: String
            let logDate: String
            let sleepHours: Double?
            let foodQuality: Int?
        }
        struct Filters: Decodable {
            let startDate: String?
            let endDate: String?
            let sortBy: String
            let sortDir: String
        }
        let items: [Item]
        let total: Int?
        let filters: Filters?
    }
    
    struct DeleteWorkoutLogResponse: Decodable {
        let message: String
    }

    // DTO for program membership with role info
    struct MembershipDetailDTO: Decodable, Identifiable {
        var id: String { member_id }
        let member_id: String
        let member_name: String
        let username: String?
        let gender: String?
        let date_of_birth: String?
        let date_joined: String?
        let global_role: String?
        let program_role: String
        let is_active: Bool
        let status: String?
        let joined_at: String?
    }

    struct ProgramUpdateResponse: Decodable {
        let id: String
        let name: String
        let status: String
        let start_date: String?
        let end_date: String?
        let message: String?
    }

    struct MembershipUpdateResponse: Decodable {
        let program_id: String
        let member_id: String
        let member_name: String?
        let role: String
        let is_active: Bool
        let status: String?
        let joined_at: String?
        let message: String?
    }

    struct MemberUpdateResponse: Decodable {
        let message: String
    }

    func addMember(token: String,
                   memberName: String,
                   password: String,
                   gender: String?,
                   dateOfBirth: String?,
                   dateJoined: String?,
                   programId: String) async throws -> MemberDetailDTO {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "member_name": memberName,
            "password": password,
            "program_id": programId
        ]
        if let gender { body["gender"] = gender }
        if let dateOfBirth { body["date_of_birth"] = dateOfBirth }
        if let dateJoined { body["date_joined"] = dateJoined }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberDetailDTO.self, from: data)
    }

    func fetchMemberMetrics(token: String,
                            programId: String,
                            search: String? = nil,
                            sort: String? = nil,
                            direction: String? = nil,
                            memberId: String? = nil,
                            filters: [String: String]? = nil) async throws -> MemberMetricsResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("member-metrics"), resolvingAgainstBaseURL: false)!
        var items: [URLQueryItem] = [URLQueryItem(name: "programId", value: programId)]
        if let search, !search.isEmpty { items.append(URLQueryItem(name: "search", value: search)) }
        if let sort { items.append(URLQueryItem(name: "sort", value: sort)) }
        if let direction { items.append(URLQueryItem(name: "direction", value: direction)) }
        if let memberId { items.append(URLQueryItem(name: "memberId", value: memberId)) }
        if let filters {
            for (k, v) in filters where !v.isEmpty {
                items.append(URLQueryItem(name: k, value: v))
            }
        }
        components.queryItems = items
        guard let url = components.url else { throw APIError(message: "Invalid member metrics URL") }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberMetricsResponse.self, from: data)
    }

    func fetchMemberHistory(token: String, programId: String, memberId: String, period: String) async throws -> MemberHistoryResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("member-history"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "programId", value: programId),
            URLQueryItem(name: "memberId", value: memberId),
            URLQueryItem(name: "period", value: period)
        ]
        guard let url = components.url else { throw APIError(message: "Invalid member history URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberHistoryResponse.self, from: data)
    }

    func fetchMemberStreaks(token: String, programId: String, memberId: String) async throws -> MemberStreaksResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("member-streaks"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "programId", value: programId),
            URLQueryItem(name: "memberId", value: memberId)
        ]
        guard let url = components.url else { throw APIError(message: "Invalid member streaks URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberStreaksResponse.self, from: data)
    }

    func fetchMemberRecentWorkouts(
        token: String,
        programId: String,
        memberId: String,
        limit: Int = 1000,
        startDate: String? = nil,
        endDate: String? = nil,
        sortBy: String? = nil,
        sortDir: String? = nil
    ) async throws -> MemberRecentWorkoutsResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("member-recent"), resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "programId", value: programId),
            URLQueryItem(name: "memberId", value: memberId),
            URLQueryItem(name: "limit", value: "\(limit)")
        ]
        if let startDate { queryItems.append(URLQueryItem(name: "startDate", value: startDate)) }
        if let endDate { queryItems.append(URLQueryItem(name: "endDate", value: endDate)) }
        if let sortBy { queryItems.append(URLQueryItem(name: "sortBy", value: sortBy)) }
        if let sortDir { queryItems.append(URLQueryItem(name: "sortDir", value: sortDir)) }
        components.queryItems = queryItems
        guard let url = components.url else { throw APIError(message: "Invalid member recent URL") }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberRecentWorkoutsResponse.self, from: data)
    }
    
    func deleteWorkoutLog(token: String, programId: String, memberId: String, workoutName: String, date: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("workout-logs"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "program_id": programId,
            "member_id": memberId,
            "workout_name": workoutName,
            "date": date
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    func updateWorkoutLog(
        token: String,
        programId: String,
        memberName: String?,
        workoutName: String,
        date: String,
        duration: Int
    ) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("workout-logs"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "program_id": programId,
            "workout_name": workoutName,
            "date": date,
            "duration": duration
        ]
        if let memberName, !memberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body["member_name"] = memberName
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    // MARK: - Program Management

    func updateProgram(token: String, programId: String, name: String?, status: String?, startDate: String?, endDate: String?) async throws -> ProgramUpdateResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("programs/\(programId)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [:]
        if let name { body["name"] = name }
        if let status { body["status"] = status }
        if let startDate { body["start_date"] = startDate }
        if let endDate { body["end_date"] = endDate }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(ProgramUpdateResponse.self, from: data)
    }

    // MARK: - Membership Management

    func fetchMembershipDetails(token: String, programId: String) async throws -> [MembershipDetailDTO] {
        var components = URLComponents(url: baseURL.appendingPathComponent("program-memberships/details"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "programId", value: programId)]
        guard let url = components.url else { throw APIError(message: "Invalid membership details URL") }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([MembershipDetailDTO].self, from: data)
    }

    func updateMembership(token: String, programId: String, memberId: String, role: String?, status: String?, isActive: Bool?, joinedAt: String?) async throws -> MembershipUpdateResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [
            "program_id": programId,
            "member_id": memberId
        ]
        if let role { body["role"] = role }
        if let status { body["status"] = status }
        if let isActive { body["is_active"] = isActive }
        if let joinedAt { body["joined_at"] = joinedAt }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(MembershipUpdateResponse.self, from: data)
    }

    func removeMemberFromProgram(token: String, programId: String, memberId: String) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships"))
        request.httpMethod = "DELETE"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "program_id": programId,
            "member_id": memberId
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        _ = try await data(for: request)
    }

    // MARK: - Member Profile Management

    func updateMemberProfile(token: String, memberId: String, firstName: String?, lastName: String?, gender: String?) async throws -> MemberUpdateResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("members/\(memberId)"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        var body: [String: Any] = [:]
        if let firstName { body["first_name"] = firstName }
        if let lastName { body["last_name"] = lastName }
        if let gender { body["gender"] = gender }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberUpdateResponse.self, from: data)
    }

    func fetchMemberById(token: String, memberId: String) async throws -> MemberDTO {
        var request = URLRequest(url: baseURL.appendingPathComponent("members/\(memberId)"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode(MemberDTO.self, from: data)
    }

    // MARK: - Program Invitations

    struct InviteResponse: Decodable {
        let message: String
    }

    /// Sends a program invitation to a user by username.
    /// Always returns success message for privacy (doesn't reveal if username exists).
    func sendProgramInvite(token: String, programId: String, username: String) async throws -> InviteResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships/invite"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "program_id": programId,
            "username": username
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(InviteResponse.self, from: data)
    }

    /// DTO for pending program invites
    struct PendingInviteDTO: Decodable, Identifiable {
        let invite_id: String
        let program_id: String
        let program_name: String?
        let program_status: String?
        let program_start_date: String?
        let program_end_date: String?
        let invited_by_name: String?
        let invited_at: String?
        let expires_at: String?
        // Admin-only fields (nil for standard users)
        let invited_username: String?
        let invited_member_name: String?
        let invited_member_id: String?

        var id: String { invite_id }

        enum CodingKeys: String, CodingKey {
            case invite_id, program_id, program_name, program_status
            case program_start_date, program_end_date
            case invited_by_name, invited_at, expires_at
            case invited_username, invited_member_name, invited_member_id
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            invite_id = try container.decode(String.self, forKey: .invite_id)
            program_id = try container.decode(String.self, forKey: .program_id)
            program_name = try container.decodeIfPresent(String.self, forKey: .program_name)
            program_status = try container.decodeIfPresent(String.self, forKey: .program_status)
            program_start_date = try container.decodeIfPresent(String.self, forKey: .program_start_date)
            program_end_date = try container.decodeIfPresent(String.self, forKey: .program_end_date)
            invited_by_name = try container.decodeIfPresent(String.self, forKey: .invited_by_name)
            invited_at = try container.decodeIfPresent(String.self, forKey: .invited_at)
            expires_at = try container.decodeIfPresent(String.self, forKey: .expires_at)
            invited_username = try container.decodeIfPresent(String.self, forKey: .invited_username)
            invited_member_name = try container.decodeIfPresent(String.self, forKey: .invited_member_name)
            invited_member_id = try container.decodeIfPresent(String.self, forKey: .invited_member_id)
        }
    }

    /// Fetches pending invites for the logged-in user (standard users)
    func fetchMyInvites(token: String) async throws -> [PendingInviteDTO] {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships/my-invites"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([PendingInviteDTO].self, from: data)
    }

    /// Fetches ALL pending invites system-wide (global_admin only)
    func fetchAllInvites(token: String) async throws -> [PendingInviteDTO] {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships/all-invites"))
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let data = try await data(for: request)
        return try JSONDecoder().decode([PendingInviteDTO].self, from: data)
    }

    /// Responds to a program invite (accept, decline, or revoke)
    /// - Parameters:
    ///   - action: "accept", "decline", or "revoke" (revoke is admin-only)
    ///   - blockFuture: If true, blocks future invites from this program (only for decline)
    func respondToInvite(token: String, inviteId: String, action: String, blockFuture: Bool = false) async throws -> InviteResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships/invite-response"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        var body: [String: Any] = [
            "invite_id": inviteId,
            "action": action
        ]
        if blockFuture {
            body["block_future"] = true
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(InviteResponse.self, from: data)
    }

    // MARK: - Account Management

    struct DeleteAccountResponse: Decodable {
        let message: String
    }

    struct ChangePasswordResponse: Decodable {
        let message: String
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

    // MARK: - Program Membership Actions

    struct LeaveProgramResponse: Decodable {
        let message: String
        let program_id: String
        let member_id: String
    }

    /// Leave a program (soft removal - data is preserved for potential rejoin)
    func leaveProgram(token: String, programId: String) async throws -> LeaveProgramResponse {
        var request = URLRequest(url: baseURL.appendingPathComponent("program-memberships/leave"))
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = ["program_id": programId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let data = try await data(for: request)
        return try JSONDecoder().decode(LeaveProgramResponse.self, from: data)
    }

    // MARK: - Helpers

    private func data(for request: URLRequest, allowRefresh: Bool = true) async throws -> Data {
        let (data, response) = try await rawData(for: request)

        if response.statusCode == 401, allowRefresh, shouldAttemptRefresh(for: request) {
            do {
                if let newToken = try await refreshAccessTokenIfPossible() {
                    var retryRequest = request
                    if request.value(forHTTPHeaderField: "Authorization") != nil {
                        retryRequest.setValue("Bearer \(newToken)", forHTTPHeaderField: "Authorization")
                    }
                    let (retryData, retryResponse) = try await rawData(for: retryRequest)
                    guard 200..<300 ~= retryResponse.statusCode else {
                        let message = extractErrorMessage(from: retryData) ?? "Request failed (\(retryResponse.statusCode))"
                        if retryResponse.statusCode == 401 {
                            authFailureHandler?()
                        }
                        throw APIError(message: message)
                    }
                    return retryData
                }
            } catch {
                authFailureHandler?()
            }
        }

        guard 200..<300 ~= response.statusCode else {
            let message = extractErrorMessage(from: data) ?? "Request failed (\(response.statusCode))"
            throw APIError(message: message)
        }
        return data
    }

    private func rawData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw APIError(message: "No response")
        }
        return (data, http)
    }

    private func refreshAccessTokenIfPossible() async throws -> String? {
        guard let refreshToken = SessionStore.shared.refreshToken else { return nil }
        let response = try await refreshSession(refreshToken: refreshToken)
        let newRefreshToken = response.refreshToken ?? refreshToken
        SessionStore.shared.saveTokens(accessToken: response.token, refreshToken: newRefreshToken)
        tokenUpdateHandler?(response.token, newRefreshToken)
        return response.token
    }

    private func shouldAttemptRefresh(for request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        if request.value(forHTTPHeaderField: "Authorization") == nil {
            return false
        }
        let path = url.path
        if path.contains("/auth/refresh") || path.contains("/auth/login") || path.contains("/auth/logout") {
            return false
        }
        return true
    }

    private func extractErrorMessage(from data: Data) -> String? {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return (json["error"] as? String) ?? (json["message"] as? String)
        }
        return nil
    }
}
