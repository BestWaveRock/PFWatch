import SwiftUI
import WatchKit

struct PetListView: View {
    @State private var pets: [Pet] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var isAuthError = false   // token 失效

    var body: some View {
        Group {
            if isAuthError {
                // token 失效 → 提示重新登录
                VStack(spacing: 12) {
                    Image(systemName: "lock.shield")
                        .font(.system(size: 36))
                        .foregroundColor(.accentColor)

                    Text("登录已失效")
                        .font(.headline)

                    Text("请在 iPhone 的 PetFriendly App 上\n重新登录后，token 将自动同步")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)

                    Button("重试") {
                        loadPets()
                    }
                    .buttonStyle(.bordered)
                    .tint(.accentColor)
                }
                .padding()
            } else if isLoading {
                ProgressView("加载中…")
            } else if let msg = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                    Text(msg)
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("重试") {
                        loadPets()
                    }
                }
                .padding()
            } else if pets.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "pawprint")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("暂无宠物")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                List(pets) { pet in
                    NavigationLink(destination: PetDetailView(pet: pet)) {
                        PetRowView(pet: pet)
                    }
                }
            }
        }
        .navigationTitle("我的萌宠")
        .onAppear { loadPets() }
    }

    private func loadPets() {
        isLoading = true
        errorMessage = nil
        isAuthError = false
        Task {
            do {
                let result = try await NetworkService.fetchMyPets()
                await MainActor.run {
                    pets = result
                    isLoading = false
                }
            } catch let error as NetworkError {
                await MainActor.run {
                    switch error {
                    case .httpError(let code, _) where code == 401 || code == 403:
                        // token 失效，清除并通知 ContentView 切换到登录页
                        NetworkService.token = nil
                        isAuthError = true
                        isLoading = false
                        NotificationCenter.default.post(name: WatchSessionManager.tokenDidUpdate, object: nil)
                    default:
                        errorMessage = error.localizedDescription
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - 宠物行视图

struct PetRowView: View {
    let pet: Pet

    var body: some View {
        HStack(spacing: 10) {
            // 头像
            if let url = pet.avatarUrl {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    case .failure:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(Image(systemName: "pawprint").font(.caption2))
                    case .empty:
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(ProgressView().scaleEffect(0.5))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(Image(systemName: "pawprint").font(.caption2))
            }

            // 文字信息
            VStack(alignment: .leading, spacing: 2) {
                Text(pet.displayName)
                    .font(.system(.body, design: .rounded))
                    .lineLimit(1)
                Text("\(pet.breedLabel) · \(pet.sexLabel)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                Text(pet.ageString)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
