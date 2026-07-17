import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var errorMessage: String?
    @State private var showPassword = false

    /// 登录成功回调（通知父视图刷新）
    var onLoginSuccess: (() -> Void)?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // MARK: Logo / 标题
                Image(systemName: "pawprint.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.accentColor)
                    .padding(.top, 20)

                Text("PetFriendly")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("登录以管理您的宠物")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)

                // MARK: 用户名
                VStack(alignment: .leading, spacing: 4) {
                    Text("账号")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    TextField("手机号 / 邮箱 / 用户名", text: $username)
                        .textContentType(.username)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.12))
                        )
                }

                // MARK: 密码
                VStack(alignment: .leading, spacing: 4) {
                    Text("密码")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    HStack {
                        if showPassword {
                            TextField("请输入密码", text: $password)
                                .textContentType(.password)
                        } else {
                            SecureField("请输入密码", text: $password)
                                .textContentType(.password)
                        }

                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.12))
                    )
                }

                // MARK: 错误信息
                if let error = errorMessage {
                    Text(error)
                        .font(.caption2)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // MARK: 登录按钮
                Button(action: performLogin) {
                    if isLoggingIn {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("登 录")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canLogin ? Color.accentColor : Color.gray.opacity(0.3))
                )
                .foregroundColor(.white)
                .disabled(!canLogin || isLoggingIn)

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    private var canLogin: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    private func performLogin() {
        guard canLogin else { return }
        isLoggingIn = true
        errorMessage = nil

        Task {
            do {
                try await AuthService.shared.login(
                    username: username.trimmingCharacters(in: .whitespaces),
                    password: password
                )
                await MainActor.run {
                    isLoggingIn = false
                    onLoginSuccess?()
                }
            } catch {
                await MainActor.run {
                    isLoggingIn = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
