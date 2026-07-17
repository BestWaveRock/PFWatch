import Foundation

/// 模板文件 — 打包时替换为真实 Secrets.swift
/// 详见 package.sh
struct Secrets {
    static let defaultBaseURL = "https://admin.petfriendly.icu/prod-api"
    static let localDevURL = "http://192.168.6.188:31000/prod-api"
    static let clientId = ""
    static let appKey = ""
    static let encryptPublicKey = ""
}
