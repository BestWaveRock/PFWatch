import Foundation
import WatchConnectivity

/// Watch 端：接收 iPhone 发送的 token
final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    /// token 更新后发送通知，让 UI 刷新
    static let tokenDidUpdate = Notification.Name("WatchTokenDidUpdate")

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("[WCSession] 激活失败: \(error.localizedDescription)")
        } else {
            print("[WCSession] 激活成功: \(activationState.rawValue)")
            // 激活后消费已在队列中的 ApplicationContext
            let pendingContext = session.receivedApplicationContext
            if !pendingContext.isEmpty {
                print("[WCSession] 消费待处理的 context: \(pendingContext.keys)")
                handleMessage(pendingContext)
            }
            // 如果还没有 token，主动向 iPhone 请求
            requestTokenIfNeeded()
        }
    }

    /// 可达性变化时，如果已配对但无 token，主动请求
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            print("[WCSession] iPhone 变为可达")
            requestTokenIfNeeded()
        }
    }

    /// 接收到 iPhone 发来的消息
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("[WCSession] 收到消息: \(message.keys)")
        handleMessage(message)
    }

    /// 接收 Application Context（后台同步）
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard !applicationContext.isEmpty else {
            print("[WCSession] 收到空 context，跳过")
            return
        }
        print("[WCSession] 收到 context: \(applicationContext.keys)")
        handleMessage(applicationContext)
    }

    // MARK: - Token 请求

    /// 如果还没有 token，主动向 iPhone 拉取
    private func requestTokenIfNeeded() {
        guard NetworkService.token.isEmpty else {
            print("[WCSession] 已有 token，跳过主动拉取")
            return
        }
        requestToken()
    }

    private func requestToken() {
        guard WCSession.default.isReachable else {
            print("[WCSession] iPhone 不可达，无法主动请求 token")
            return
        }
        WCSession.default.sendMessage(["requestToken": true], replyHandler: { reply in
            if let token = reply["token"] as? String, !token.isEmpty {
                DispatchQueue.main.async {
                    NetworkService.token = token
                    NotificationCenter.default.post(name: Self.tokenDidUpdate, object: nil)
                    print("[WCSession] 主动拉取 Token 成功")
                }
            }
        }, errorHandler: { error in
            print("[WCSession] 主动拉取 Token 失败: \(error.localizedDescription)")
        })
    }

    // MARK: - 消息处理

    private func handleMessage(_ dict: [String: Any]) {
        // 检查是否有 token
        if let token = dict["token"] as? String, !token.isEmpty {
            NetworkService.token = token
            print("[WCSession] Token 已保存")

            // 通知 UI 刷新
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.tokenDidUpdate, object: nil)
            }
        }

        // 检查是否有用户信息
        if let nickname = dict["nickname"] as? String {
            NetworkService.userNickname = nickname
        }
        if let avatar = dict["avatar"] as? String {
            NetworkService.userAvatar = avatar
        }
    }
}
