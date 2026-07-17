import Foundation

// MARK: - Watch 端认证服务

/// 用户认证状态
enum AuthState {
    case unknown       // 初始状态
    case loggedIn      // 已登录（有有效 token）
    case notLoggedIn   // 未登录 / token 失效
}

final class AuthService {
    static let shared = AuthService()

    // 已登录用户信息缓存
    var currentUser: UserInfo?
    var currentPetOwner: PetOwnerData?

    private init() {}

    /// 判断当前 token 是否有效（本地 + 远程双重检查）
    var isLoggedIn: Bool {
        guard let t = NetworkService.token, !t.isEmpty else { return false }
        return true
    }

    /// 登录：用户名 + 密码
    /// 使用加密传输（与 iOS 端一致）
    func login(username: String, password: String) async throws {
        var params: [String: Any] = [
            "clientId": Secrets.clientId,
            "grantType": "password",
            "username": username,
            "password": password
        ]

        // 判断是否是邮箱
        if username.contains("@") {
            params["grantType"] = "password"   // 密码登录，邮箱也走 password grantType
        }

        // 加密请求体（与 iOS NetworkManager.encryptFlag=true 一致）
        let encrypted = try CryptoService.encryptRequest(body: params)

        // 构造加密请求
        guard let url = URL(string: Secrets.defaultBaseURL + "/auth/login") else {
            throw NetworkError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        req.setValue(Secrets.appKey, forHTTPHeaderField: "X-APP-KEY")
        req.setValue(Secrets.clientId, forHTTPHeaderField: "CliendId")
        req.setValue("zh_CN", forHTTPHeaderField: "Content-Language")
        req.setValue(encrypted.keyHeader, forHTTPHeaderField: "Encrypt-Key")
        req.httpBody = Data(encrypted.body.utf8)

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let httpResp = response as? HTTPURLResponse else {
            throw NetworkError.httpError(statusCode: 0, message: "无响应")
        }

        guard (200...299).contains(httpResp.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw NetworkError.httpError(statusCode: httpResp.statusCode, message: body)
        }

        let decoder = JSONDecoder()
        let loginResp: LoginResp
        do {
            loginResp = try decoder.decode(LoginResp.self, from: data)
        } catch {
            throw NetworkError.decodingError(error.localizedDescription)
        }

        guard loginResp.code == 200, let token = loginResp.data?.access_token else {
            throw NetworkError.loginFailed(reason: loginResp.msg ?? "登录失败")
        }

        // 保存 token
        NetworkService.token = token

        // 登录成功后拉取用户信息
        try await fetchUserInfo()
    }

    /// 获取用户信息
    func fetchUserInfo() async throws {
        let resp: ApiResponse<UserInfoData> = try await NetworkService.encryptedRequest(
            "/system/user/getInfo",
            method: "GET"
        )

        guard let data = resp.data else {
            throw NetworkError.noData
        }

        currentUser = data.user
        currentPetOwner = data.petOwner

        // 缓存用户信息到 UserDefaults
        if let nickname = data.user?.nickName {
            NetworkService.userNickname = nickname
        }
        if let avatar = data.user?.avatar {
            NetworkService.userAvatar = avatar
        }
    }

    /// 退出登录
    func logout() {
        NetworkService.token = nil
        NetworkService.userNickname = nil
        NetworkService.userAvatar = nil
        currentUser = nil
        currentPetOwner = nil
    }

    /// 验证 token 是否有效（调用 getInfo）
    func validateToken() async -> Bool {
        guard isLoggedIn else { return false }
        do {
            try await fetchUserInfo()
            return true
        } catch {
            // token 失效
            logout()
            return false
        }
    }
}
