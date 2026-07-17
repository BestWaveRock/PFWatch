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
        }
    }

    /// 接收到 iPhone 发来的消息
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        print("[WCSession] 收到消息: \(message.keys)")
        handleMessage(message)
    }

    /// 接收 Application Context（后台同步）
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        print("[WCSession] 收到 context: \(applicationContext.keys)")
        handleMessage(applicationContext)
    }

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
