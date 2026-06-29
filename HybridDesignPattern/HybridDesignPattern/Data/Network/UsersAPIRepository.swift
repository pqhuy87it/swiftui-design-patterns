import Foundation

// MARK: - Data implementation
// Conform UsersRepositoryProtocol (domain) + APIRepositoryProtocol (transport).
// Map ApiModel.User -> domain User tại ranh giới Data.
struct UsersAPIRepository: UsersRepositoryProtocol, APIRepositoryProtocol {
    let session: URLSession
    let baseURL: String

    init(session: URLSession, baseURL: String = "https://api.example.com/v1") {
        self.session = session
        self.baseURL = baseURL
    }

    func fetchUsers() async throws -> [User] {
        let dtos: [ApiModel.User] = try await call(endpoint: API.getUsers)
        return dtos.map { $0.toDomain() }
    }
}

// Define specific endpoints for User
extension UsersAPIRepository {
    enum API {
        case getUsers
        case createUser(payload: Data)
    }
}

extension UsersAPIRepository.API: APICall {
    var path: String {
        switch self {
        case .getUsers, .createUser:
            return "/users"
        }
    }
    var method: String {
        switch self {
        case .getUsers: return "GET"
        case .createUser: return "POST"
        }
    }
    var headers: [String: String]? {
        return ["Accept": "application/json", "Content-Type": "application/json"]
    }
    func body() throws -> Data? {
        switch self {
        case .getUsers: return nil
        case let .createUser(payload): return payload
        }
    }
}

// MARK: - Mapping ApiModel -> Domain entity
private extension ApiModel.User {
    func toDomain() -> User {
        User(id: id, username: username, name: name)
    }
}
