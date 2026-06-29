import Foundation

// Trung tâm cấu hình/secret. Đọc giá trị nhạy cảm từ Secrets.plist (được .gitignore),
// thay vì hardcode trong source. Xem Secrets.example.plist để biết các khoá cần khai báo.
enum AppConfig {

    /// Unsplash API access key (Client-ID).
    static var unsplashClientID: String { string(forKey: "UnsplashClientID") }

    // MARK: - Plist loader

    private static let secrets: [String: Any] = {
        guard
            let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
            let dict = NSDictionary(contentsOf: url) as? [String: Any]
        else {
            assertionFailure("""
            ⚠️ Không tìm thấy Secrets.plist trong bundle.
            Hãy copy Config/Secrets.example.plist -> Config/Secrets.plist và điền giá trị thật.
            """)
            return [:]
        }
        return dict
    }()

    private static func string(forKey key: String) -> String {
        guard let value = secrets[key] as? String, !value.isEmpty else {
            assertionFailure("⚠️ Thiếu hoặc rỗng khoá '\(key)' trong Secrets.plist.")
            return ""
        }
        return value
    }
}
