import SwiftUI

struct ContentView: View {
    var onLogout: (() -> Void)?

    @State private var showLogoutConfirm = false

    var body: some View {
        TabView {
            // 宠物列表
            PetListView()
                .tabItem {
                    Label("萌宠", systemImage: "pawprint")
                }

            // 个人/设置
            ProfileView(onLogout: onLogout)
                .tabItem {
                    Label("我的", systemImage: "person.circle")
                }
        }
    }
}

// MARK: - 简单个人页（含退出登录）

struct ProfileView: View {
    var onLogout: (() -> Void)?

    @State private var showLogoutConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 用户信息
                VStack(spacing: 8) {
                    if let avatar = NetworkService.userAvatar, !avatar.isEmpty {
                        let url = avatar.hasPrefix("http") ? URL(string: avatar) : URL(string: "https://rustfs.petfriendly.icu/jiaxu-technology" + avatar)
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            default:
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.accentColor)
                            }
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.accentColor)
                    }

                    if let name = AuthService.shared.currentUser?.nickName {
                        Text(name)
                            .font(.headline)
                    } else if let name = NetworkService.userNickname {
                        Text(name)
                            .font(.headline)
                    } else {
                        Text("用户")
                            .font(.headline)
                    }
                }
                .padding(.top, 10)

                Divider()

                // 退出登录
                Button(role: .destructive) {
                    showLogoutConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("退出登录")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.red.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
        }
        .navigationTitle("我的")
        .alert("退出登录", isPresented: $showLogoutConfirm) {
            Button("取消", role: .cancel) {}
            Button("退出", role: .destructive) {
                onLogout?()
            }
        } message: {
            Text("确定要退出当前账号吗？")
        }
    }
}
