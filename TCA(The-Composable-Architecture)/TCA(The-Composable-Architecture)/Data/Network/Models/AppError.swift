import Foundation

/// Kiểu lỗi thống nhất, Equatable, dùng trong Action của các Feature.
///
/// TCA yêu cầu State/Action nên là Equatable để có thể so sánh trong `TestStore`.
/// `Swift.Error` không Equatable, nên ta bọc mọi lỗi ném ra thành `AppError`.
enum AppError: Error, Equatable, LocalizedError {
    /// Lỗi từ tầng network / API đã biết trước.
    case network(String)
    /// Mọi lỗi khác không xác định.
    case unknown(String)

    init(_ error: Error) {
        switch error {
        case let appError as AppError:
            self = appError
        case let apiError as APIError:
            self = .network(apiError.errorDescription ?? "Network error")
        default:
            self = .unknown(error.localizedDescription)
        }
    }

    var errorDescription: String? {
        switch self {
        case let .network(message), let .unknown(message):
            return message
        }
    }
}
