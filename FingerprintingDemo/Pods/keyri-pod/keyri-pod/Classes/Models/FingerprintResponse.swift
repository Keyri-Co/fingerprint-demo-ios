//
//  FingerprintResponse.swift
//  keyri-pod
//
//  Created by Aditya Malladi on 4/11/23.
//

import Foundation

public class FingerprintResponse: NSObject, Decodable, Encodable {
    @objc public let encryptedPayload: String?
    @objc public let iv: String?
    @objc public let salt: String?
    @objc public let keyriEncryptionPublicKey: String?
    
    private enum CodingKeys: String, CodingKey {
        case encryptedPayload
        case iv
        case salt
        case keyriEncryptionPublicKey
    }
}
