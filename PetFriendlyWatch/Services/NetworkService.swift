import Foundation

// MARK: - 简版网络请求（watchOS 无 Alamofire）

enum NetworkError: LocalizedError {
    case invalidURL
    case httpError(statusCode: Int, message: String)
    case decodingError(String)
    case noData
    case notAuthenticated
    case loginFailed(reason: String)
    case encryptionFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "无效的 URL"
        case .httpError(let code, let msg): return "HTTP \(code): \(msg)"
        case .decodingError(let detail): return "数据解析失败: \(detail)"
        case .noData: return "无返回数据"
        case .notAuthenticated: return "未登录"
        case .loginFailed(let reason): return reason
        case .encryptionFailed(let detail): return "加密失败: \(detail)"
        case .networkError(let detail): return "网络错误: \(detail)"
        }
    }
}

struct ApiResponse<T: Decodable>: Decodable {
    let code: Int
    let msg: String?
    let data: T?
}

final class NetworkService {
    /// Token（来自登录或 iPhone 同步）
    static var token: String? {
        get { UserDefaults.standard.string(forKey: "auth_token") }
        set { UserDefaults.standard.set(newValue, forKey: "auth_token") }
    }

    /// 用户昵称（可选，用于显示）
    static var userNickname: String? {
        get { UserDefaults.standard.string(forKey: "user_nickname") }
        set { UserDefaults.standard.set(newValue, forKey: "user_nickname") }
    }

    /// 用户头像（可选，用于显示）
    static var userAvatar: String? {
        get { UserDefaults.standard.string(forKey: "user_avatar") }
        set { UserDefaults.standard.set(newValue, forKey: "user_avatar") }
    }

    /// 是否已登录（本地有 token）
    static var isLoggedIn: Bool {
        guard let t = token, !t.isEmpty else { return false }
        return true
    }

    private static let baseURL = Secrets.defaultBaseURL
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    // MARK: - 宠物相关 API

    /// 获取我的宠物列表
    static func fetchMyPets() async throws -> [Pet] {
        let resp: ApiResponse<PetListResp> = try await request("/petFriendly/client/myPets")
        let list = resp.data
        return list?.rows ?? list?.data ?? []
    }

    // MARK: - 通用请求

    /// 普通 GET 请求（带 token）
    static func request<T: Decodable>(_ path: String) async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = token, !token.isEmpty {
            req.setValue(token, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: req)

        guard let httpResp = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: 0, message: "无响应")
        }

        guard (200...299).contains(httpResp.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NetworkError.httpError(statusCode: httpResp.statusCode, message: body)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }

    /// 加密请求（用于登录等需要加密的 POST）
    static func encryptedRequest<T: Decodable>(_ path: String, method: String = "GET") async throws -> T {
        guard let url = URL(string: baseURL + path) else {
            throw NetworkError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue(Secrets.appKey, forHTTPHeaderField: "X-APP-KEY")
        req.setValue(Secrets.clientId, forHTTPHeaderField: "CliendId")
        req.setValue("zh_CN", forHTTPHeaderField: "Content-Language")

        if let token = token, !token.isEmpty {
            req.setValue(token, forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: req)

        guard let httpResp = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: 0, message: "无响应")
        }

        guard (200...299).contains(httpResp.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            if httpResp.statusCode == 401 || httpResp.statusCode == 403 {
                throw NetworkError.notAuthenticated
            }
            throw NetworkError.httpError(statusCode: httpResp.statusCode, message: body)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }
    }
}
