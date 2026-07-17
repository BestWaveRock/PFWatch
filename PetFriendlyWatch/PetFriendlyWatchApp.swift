import SwiftUI

@main
struct PetFriendlyWatchApp: App {
    @State private var isLoggedIn = NetworkService.isLoggedIn
    @State private var isChecking = true

    var body: some Scene {
        WindowGroup {
            Group {
                if isChecking {
                    // 启动时验证 token 是否有效
                    VStack(spacing: 12) {
                        Image(systemName: "pawprint.circle")
                            .font(.system(size: 36))
                            .foregroundColor(.accentColor)
                        ProgressView("验证登录…")
                            .font(.caption2)
                    }
                } else if isLoggedIn {
                    // 已登录 → 主界面
                    NavigationStack {
                        ContentView(onLogout: performLogout)
                    }
                } else {
                    // 未登录 → 登录页
                    NavigationStack {
                        LoginView(onLoginSuccess: {
                            withAnimation {
                                isLoggedIn = true
                            }
                        })
                    }
                }
            }
            .onAppear {
                checkLoginState()
            }
            .onReceive(NotificationCenter.default.publisher(for: .tokenDidExpire)) { _ in
                // token 在子页面失效 → 跳回登录
                withAnimation {
                    isLoggedIn = false
                }
            }
        }
    }

    private func checkLoginState() {
        Task {
            if NetworkService.isLoggedIn {
                // 有本地 token，验证是否有效
                let valid = await AuthService.shared.validateToken()
                await MainActor.run {
                    isLoggedIn = valid
                    isChecking = false
                }
            } else {
                await MainActor.run {
                    isLoggedIn = false
                    isChecking = false
                }
            }
        }
    }

    private func performLogout() {
        AuthService.shared.logout()
        withAnimation {
            isLoggedIn = false
        }
    }
}
