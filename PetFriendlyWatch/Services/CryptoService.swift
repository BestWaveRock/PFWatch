import Foundation
import CommonCrypto
import Security

// MARK: - 加密服务（与 iOS 端保持一致）
// AES-256-ECB + PKCS5Padding + RSA 公钥加密 AES Key
enum CryptoService {

    /// 生成 32 位随机密钥
    static func randomAESKey() -> String {
        let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        return String((0..<32).map { _ in charset.randomElement()! })
    }

    /// AES-256-ECB + PKCS5Padding 加密
    /// - Parameters:
    ///   - string: 明文
    ///   - key: 32 字节密钥（Base64 字符串）
    /// - Returns: 密文 Data
    static func aesEncryptECB_PKCS5(string: String, key: String) throws -> Data {
        guard let keyData = Data(base64Encoded: key) else {
            throw CryptoError.invalidKey
        }
        precondition(keyData.count == kCCKeySizeAES256, "AES-256 密钥必须是 32 字节")
        let plainData = Data(string.utf8)

        let cryptLen = plainData.count + kCCBlockSizeAES128
        var cryptData = Data(count: cryptLen)
        var numBytes: size_t = 0

        let status = cryptData.withUnsafeMutableBytes { cryptBytes in
            plainData.withUnsafeBytes { plainBytes in
                keyData.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        CCAlgorithm(kCCAlgorithmAES),
                        CCOptions(kCCOptionPKCS7Padding | kCCOptionECBMode),
                        keyBytes.baseAddress, kCCKeySizeAES256,
                        nil,                    // ECB 无 IV
                        plainBytes.baseAddress, plainData.count,
                        cryptBytes.baseAddress, cryptLen,
                        &numBytes
                    )
                }
            }
        }

        guard status == kCCSuccess else {
            throw CryptoError.aesFailed(status: Int(status))
        }
        cryptData.count = numBytes
        return cryptData
    }

    /// RSA 公钥加密（PKCS1）
    static func rsaEncrypt(_ data: Data, publicKeyPEM: String) throws -> String {
        guard let secKey = loadPublicKey(pem: publicKeyPEM) else {
            throw CryptoError.invalidPublicKey
        }

        let blockSize = SecKeyGetBlockSize(secKey)
        let maxChunk = blockSize - 11
        guard data.count <= maxChunk else {
            throw CryptoError.dataTooLong
        }

        var error: Unmanaged<CFError>?
        guard let cipherData = SecKeyCreateEncryptedData(
            secKey,
            .rsaEncryptionPKCS1,
            data as CFData,
            &error
        ) as Data? else {
            if let err = error?.takeRetainedValue() {
                throw err as Error
            }
            throw CryptoError.rsaFailed
        }
        return cipherData.base64EncodedString()
    }

    /// PEM 公钥字符串 → SecKey
    private static func loadPublicKey(pem: String) -> SecKey? {
        let stripped = pem
            .replacingOccurrences(of: "-----BEGIN PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "-----END PUBLIC KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")

        guard let data = Data(base64Encoded: stripped) else { return nil }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits as String: 2048
        ]
        return SecKeyCreateWithData(data as CFData, attributes as CFDictionary, nil)
    }

    /// 加密登录请求体（与 iOS NetworkManager.encryptFlag 一致）
    /// - Returns: (encryptedBody: String, encryptKeyHeader: String)
    static func encryptRequest(body: [String: Any]) throws -> (body: String, keyHeader: String) {
        let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
        guard let jsonStr = String(data: jsonData, encoding: .utf8) else {
            throw CryptoError.invalidJSON
        }

        let aesKey = randomAESKey()
        let aesKeyBase64 = aesKey.data(using: .utf8)!.base64EncodedString()

        // RSA 加密 AES Key
        let aesKeyBase64Data = Data(aesKeyBase64.utf8)
        let rsaCipherB64 = try rsaEncrypt(aesKeyBase64Data, publicKeyPEM: Secrets.encryptPublicKey)

        // AES 加密 Body
        let cipherData = try aesEncryptECB_PKCS5(string: jsonStr, key: aesKeyBase64)
        let bodyB64 = cipherData.base64EncodedString()

        return (bodyB64, rsaCipherB64)
    }
}

// MARK: - Errors

enum CryptoError: LocalizedError {
    case invalidKey
    case aesFailed(status: Int)
    case invalidPublicKey
    case dataTooLong
    case rsaFailed
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .invalidKey: return "无效的 AES 密钥"
        case .aesFailed(let s): return "AES 加密失败 (status=\(s))"
        case .invalidPublicKey: return "无效的公钥"
        case .dataTooLong: return "RSA 加密数据过长"
        case .rsaFailed: return "RSA 加密失败"
        case .invalidJSON: return "JSON 序列化失败"
        }
    }
}
