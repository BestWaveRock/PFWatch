import Foundation

// MARK: - API 响应包装

struct PetListResp: Decodable {
    let rows: [Pet]?
    let data: [Pet]?
    let total: Int?
}

// MARK: - 宠物模型

struct Pet: Identifiable, Decodable {
    let petId: String
    let name: String
    let nickName: String?
    let breed: String?          // 品种文字描述
    let species: Int?
    let breeds: Int?
    let sex: Int
    let birthday: String?
    let petAvatar: String?
    let contactType: Int?
    let voiceUrl: String?       // 宠物录音 URL

    /// 头像 URL（完整拼接）
    var avatarUrl: URL? {
        guard let str = petAvatar, !str.isEmpty else { return nil }
        if str.hasPrefix("http") {
            return URL(string: str)
        }
        return URL(string: "https://rustfs.petfriendly.icu/jiaxu-technology" + str)
    }

    /// 录音 URL
    var voiceURL: URL? {
        guard let str = voiceUrl, !str.isEmpty else { return nil }
        return URL(string: str)
    }

    var id: String { petId }

    /// 显示的昵称
    var displayName: String { nickName ?? name }

    /// 性别文字
    var sexLabel: String {
        switch sex {
        case 1: return "♂ 公"
        case 2: return "♀ 母"
        default: return "未知"
        }
    }

    /// 品种名（兜底）
    var breedLabel: String {
        breed ?? "未知品种"
    }

    /// 年龄文字
    var ageString: String {
        guard let bday = birthday?.prefix(10), bday.count == 10,
              let date = ymdFormatter.date(from: String(bday)) else {
            return "未知年龄"
        }
        let comps = Calendar.current.dateComponents([.year, .month], from: date, to: Date())
        let years = comps.year ?? 0
        let months = comps.month ?? 0
        if years > 0 {
            return "\(years)岁\(months)个月"
        } else if months > 0 {
            return "\(months)个月"
        } else {
            return "幼崽"
        }
    }
}

private let ymdFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    return f
}()
