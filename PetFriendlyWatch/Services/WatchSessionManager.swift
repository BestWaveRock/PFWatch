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
            return
        }
        print("[WCSession] 激活成功: \(activationState.rawValue)")

        // 兜底 1：激活前 iPhone 可能已同步过 context，直接消费已收到的 context，避免丢 token
        let received = session.receivedApplicationContext
        if !received.isEmpty {
            print("[WCSession] 激活时已有 context，立即处理")
            handleMessage(received)
        }

        // 兜底 2：若当前仍无 token，主动向 iPhone 请求（覆盖“错过推送窗口”的场景）
        requestTokenIfNeeded()
    }

    /// iPhone 可达性变化：一旦可达且本地仍无 token，主动拉取
    func sessionReachabilityDidChange(_ session: WCSession) {
        if session.isReachable {
            requestTokenIfNeeded()
        }
    }

    /// 接收到 iPhone 发来的消息
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("[WCSession] 收到消息: \(message.keys)")
        handleMessage(message)
    }

    /// 接收 Application Context（后台同步）
    /// 对手 App 未安装 / 尚未同步时收到的 context 为空字典，做空兜底，避免“nil context”报错
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard !applicationContext.isEmpty else {
            print("[WCSession] 收到空 context，跳过（可能对手 App 未安装）")
            return
        }
        print("[WCSession] 收到 context: \(applicationContext.keys)")
        handleMessage(applicationContext)
    }

    // MARK: - 主动请求 token

    private func requestTokenIfNeeded() {
        // 已有 token 就不再重复请求，避免无谓唤醒 iPhone
        guard NetworkService.token?.isEmpty ?? true else { return }
        requestToken()
    }

    private func requestToken() {
        let session = WCSession.default
        guard session.isReachable else {
            // 不可达时依赖对手 App 安装/登录后通过 ApplicationContext 推送
            print("[WCSession] iPhone 当前不可达，等待对手 App 推送 context")
            return
        }
        session.sendMessage(["requestToken": true], replyHandler: { [weak self] reply in
            print("[WCSession] 收到 iPhone 回复的 token")
            self?.handleMessage(reply)
        }, errorHandler: { error in
            print("[WCSession] 主动请求 token 失败: \(error.localizedDescription)")
        })
    }

    private func handleMessage(_ dict: [String: Any]) {
        guard !dict.isEmpty else { return }

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
