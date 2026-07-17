import Foundation

// MARK: - 登录/认证模型

struct LoginResp: Decodable {
    let code: Int
    let msg: String?
    let data: LoginData?
}

struct LoginData: Decodable {
    let access_token: String?
    let refresh_token: String?
    let client_id: String?
}

struct UserInfoResp: Decodable {
    let code: Int
    let msg: String?
    let data: UserInfoData?
}

struct UserInfoData: Decodable {
    let user: UserInfo?
    let permissions: [String]?
    let roles: [String]?
    let petOwner: PetOwnerData?
}

struct UserInfo: Decodable {
    let userId: String?
    let nickName: String?
    let userName: String?
    let avatar: String?
    let phonenumber: String?
    let email: String?
    let sex: String?
}

struct PetOwnerData: Decodable {
    let ownerId: String?
    let name: String?
    let petAvatar: String?
    let phoneInformation: String?
    let sex: Int?
}
