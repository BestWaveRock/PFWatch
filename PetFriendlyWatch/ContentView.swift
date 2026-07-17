import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var isLoggedIn = NetworkService.isLoggedIn
    @State private var showMainContent = false

    var body: some View {
        Group {
            if isLoggedIn {
                mainListView
            } else {
                loginPromptView
            }
        }
        .navigationTitle("PetFriendly")
        .onReceive(NotificationCenter.default.publisher(for: WatchSessionManager.tokenDidUpdate)) { _ in
            // iPhone 同步了 token → 自动登录
            withAnimation {
                isLoggedIn = NetworkService.isLoggedIn
            }
        }
    }

    // MARK: - 主列表

    private var mainListView: some View {
        List {
            NavigationLink(destination: PetListView()) {
                Label("我的萌宠", systemImage: "pawprint.circle")
            }
            Label("订单", systemImage: "list.clipboard")
            Label("消息", systemImage: "message")
            Label("我的", systemImage: "person.circle")
        }
    }

    // MARK: - 登录提示页

    private var loginPromptView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "lock.shield")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)

            Text("尚未登录")
                .font(.headline)
                .fontWeight(.semibold)

            Text("请在 iPhone 的 PetFriendly App 上\n登录后，token 将自动同步到手表")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            // 手动刷新按钮（iPhone 已登录但 Watch 没收到时用）
            Button(action: {
                // 尝试重新从 WC session 获取
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage(["requestToken": true], replyHandler: { reply in
                        if let token = reply["token"] as? String {
                            NetworkService.token = token
                            DispatchQueue.main.async {
                                withAnimation { isLoggedIn = true }
                            }
                        }
                    }, errorHandler: { _ in
                        // 静默失败
                    })
                }
            }) {
                Label("尝试同步", systemImage: "arrow.triangle.2.circlepath")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .tint(.accentColor)

            Spacer()

            Text("已在 App 登录？点击上方同步")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
