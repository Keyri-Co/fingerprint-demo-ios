//
//  KeyriService.swift
//  keyri-pod
//
//  Created by Aditya Malladi on 5/16/22.
//

import Foundation
import CryptoKit

public class KeyriService {
    public func getSessionInfo(appKey: String, sessionId: String, associationKey: P256.Signing.PublicKey, completionHandler: @escaping (Result<Data, Error>) -> Void) {
        
        let prefix = urlPrefix(from: appKey)
        guard let url = URL(string: "https://\(prefix).api.keyri.com/api/v1/session/\(sessionId)?appKey=\(appKey)") else {
            completionHandler(.failure(KeyriErrors.keyriSdkError))
            return
        }
        
        guard EPDUtil.isEPD() else {
            TelemetryService.sendEvent(status: .failure, code: .epdDetected, message: "EPD on GET", sessionId: sessionId)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(associationKey.derRepresentation.base64EncodedString(), forHTTPHeaderField: "x-mobile-id")
        request.addValue(UIDevice.current.identifierForVendor?.description ?? "", forHTTPHeaderField: "x-mobile-vendorId")
        request.addValue("iOS", forHTTPHeaderField: "x-mobile-os")
        
        TelemetryService.sendEvent(status: .success, code: .getTriggered, message: "Sending GET", sessionId: sessionId)

        let task = URLSession.shared.dataTask(with: request) {(data, _, error) in
            guard let data = data else {
                completionHandler(.failure(KeyriErrors.networkError))
                TelemetryService.sendEvent(status: .failure, code: .getResponseHandled, message: KeyriErrors.networkError.localizedDescription, sessionId: sessionId)
                return
                
            }
            
            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
            if let responseJSON = responseJSON as? [String: Any] {
                print(responseJSON)
            }
            
            TelemetryService.sendEvent(status: .success, code: .getResponseHandled, message: data.base64EncodedString(), sessionId: sessionId)
            completionHandler(.success(data))
        }

        task.resume()
        
    }
    
    
    public func postSuccessfulAuth(sessionId: String, sessionInfo: [String: Any], appKey: String) throws {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: sessionInfo)
            
            let prefix = urlPrefix(from: appKey)
            
            guard let url = URL(string: "https://\(prefix).api.keyri.com/api/v1/session/\(sessionId)") else {
                throw KeyriErrors.keyriSdkError
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            // insert json data to the request
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    TelemetryService.sendEvent(status: .failure, code: .postResponseReceived, message: "Failed to POST", sessionId: sessionId)
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    print(responseJSON)
                }
                
                TelemetryService.sendEvent(status: .success, code: .postResponseReceived, message: "POST success", sessionId: sessionId)
            }

            task.resume()
            TelemetryService.sendEvent(status: .success, code: .postSent, message: "Sent POST", sessionId: sessionId)
        } catch {
            throw error
        }
    }
    
    public func createDevice(appKey: String, dict: [String: Any], completion: @escaping (Bool) -> ()) {
        var url =  "https://dev-api.keyri.co/fingerprint/new-device"
        
        do {
            print(dict)
            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            guard let url = URL(string: url) else {
                throw KeyriErrors.keyriSdkError
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue(appKey, forHTTPHeaderField: "api-key")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            // insert json data to the request
            request.httpBody = jsonData as Data

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                print("Create Device Callback")
                guard let data = data, error == nil else {
                    print("Error on create")
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    print("response")
                    print(responseJSON)
                    completion(true)
                    return
                }
                completion(false)
            }

            task.resume()
            
        } catch {
            print(error)
            completion(false)
        }
    }
    
    public func sendEvent(appKey: String, username: String = "ANON", eventType: EventType, success: Bool = true, completion: @escaping (Result<FingerprintResponse, Error>) -> ()) {
        guard let url = URL(string: "https://dev-api.keyri.co/fingerprint/event") else { return }
        guard let associationKey = try? Keyri(appKey: appKey).getAssociationKey(username: "ANON") else { return }
        
        var request = URLRequest(url: url)
        
        print(String(SHA256.hash(data: associationKey.rawRepresentation).description.split(separator: " ")[2]))
        print(associationKey.rawRepresentation.base64EncodedString())
        
        let apiKey = "dev_raB7SFWt27VoKqkPhaUrmWAsCJIO8Moj"

//        request.addValue(associationKey.rawRepresentation.base64EncodedString(), forHTTPHeaderField: "cryptocookie")
//        request.addValue(String(SHA256.hash(data: associationKey.rawRepresentation).description.split(separator: " ")[2]), forHTTPHeaderField: "devicehash")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.addValue(apiKey, forHTTPHeaderField: "api-key")
        request.httpMethod = "POST"

        let deviceHash = String(SHA256.hash(data: associationKey.rawRepresentation).description.split(separator: " ")[2])
        let cryptoCookie = associationKey.rawRepresentation.base64EncodedString()
                                
        let msgDict = [
            "apiKey": apiKey,
            "deviceHash": deviceHash,
            "cryptoCookie": associationKey.rawRepresentation.base64EncodedString(),
            "serviceEncryptionKey": "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEOumVzcs7KwS7Lz3PySGhHaiOgMmrF1O7l997kMD8gEYBSiAIzavmZ9lBT5qp/LC5Sv/zRmYk2IEqUNpvw6lJrw==",
            "eventType": eventType.rawValue,
            "eventResult": success ? "success" : "fail",
            "signals": [],
            "userId": username,
            "userEmail": username
        ] as [String : Any]
        
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: msgDict, options: .prettyPrinted) else {
           print("Something is wrong while converting dictionary to JSON data.")
            return
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
           print("Something is wrong while converting JSON data to JSON string.")
           return
        }

        
        print("STR HERE")
        print(jsonString)
        
        var x = Data(base64Encoded: "O6aCXxDctj+urHBGTGQgfJ9I9euUIPtkLYMfloUqz1m/zUMIY26Ojz97C/o72DtcXh0xEi6gD/W/jIMvaUJEgw==")!
        //var x = Data(base64Encoded: "OumVzcs7KwS7Lz3PySGhHaiOgMmrF1O7l997kMD8gEYBSiAIzavmZ9lBT5qp/LC5Sv/zRmYk2IEqUNpvw6lJrw==")!
        let y = x.dropFirst()
        print(x)
        do {
            let privateKey = P256.KeyAgreement.PrivateKey()
            let generatedPublicKey = privateKey.publicKey
            let publickey = try P256.KeyAgreement.PublicKey(rawRepresentation: x)
            let share = try privateKey.sharedSecretFromKeyAgreement(with: publickey)
            print ("\n")
            
            let testSalt = Int.random(in: 0...9999).description.data(using: .utf8)!

            print(testSalt.base64EncodedString())
            
            let protocolSalt = "12345".data(using: .utf8)!
            let symKey = share.hkdfDerivedSymmetricKey(using: SHA256.self, salt: protocolSalt, sharedInfo: Data(), outputByteCount: 32)
            let keyb64 = symKey.withUnsafeBytes {
                return Data(Array($0)).base64EncodedString()
            }
            
            let encrypted = try AES.GCM.seal(jsonString.data(using: .utf8)!, using: symKey)
            
            
            let dict = [
                "clientEncryptionKey": generatedPublicKey.rawRepresentation.base64EncodedString(),
                "encryptedPayload": encrypted.combined!.dropFirst(12).base64EncodedString(),
                "salt": protocolSalt.base64EncodedString(),
                "iv": encrypted.nonce.withUnsafeBytes { Data(Array($0)).base64EncodedString() }
            ]
            //encrypted.nonce.withUnsafeBytes { Data(Array($0)).base64EncodedString() }

            let jsonData = try JSONSerialization.data(withJSONObject: dict)
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                print("SEND EVENT CALLBACK")
                if let error = error {
                    print("ERROR")
                    print(error)
                }
                
                guard let data = data, error == nil else {
                    print(error?.localizedDescription ?? "No data")
                    return
                }
                
                let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                if let responseJSON = responseJSON as? [String: Any] {
                    print("RESPONSEJSON")
                    print(responseJSON)
                }
                
                if let responseObject = try? JSONDecoder().decode(FingerprintResponse.self, from: data) {
                    print("RESPONSEOBJECT")
                    if let _ = responseObject.encryptedPayload {
                        print(responseObject)
                        completion(.success(responseObject))
                    } else {
                        completion(.failure(KeyriErrors.serverError))
                    }
                } else {
                    print("ERROR IN UNWRAPPING")
                    completion(.failure(KeyriErrors.keyriSdkError))
                }
            }
            
            print("calling")

            task.resume()
            
        } catch {
            print(error)
            completion(.failure(KeyriErrors.keyriSdkError))
        }
        
//        guard let json = try? JSONSerialization.data(withJSONObject: dict) else {
//            completion(.failure(KeyriErrors.serverError))
//            return
//        }
//
//        request.httpBody = json
//
//        let task = URLSession.shared.dataTask(with: request) { data, response, error in
//            guard let data = data, error == nil else {
//
//                print(error?.localizedDescription ?? "No data")
//                return
//            }
//
//            //print(try! JSONSerialization.jsonObject(with: data))
//
//            if let responseObject = try? JSONDecoder().decode(FingerprintResponse.self, from: data) {
//                if let _ = responseObject.data?.fingerprintId {
//                    completion(.success(responseObject))
//                } else {
//                    completion(.failure(KeyriErrors.serverError))
//                }
//            } else {
//                completion(.failure(KeyriErrors.keyriSdkError))
//            }
//        }
//
//        task.resume()
        
        
        
    }
    
    private func urlPrefix(from appKey: String) -> String {
        guard let data = appKey.data(using: .utf8) else { return "prod" }
        let hash = SHA256.hash(data: data).hashValue
        
        if hash == -7517014640307154636 { return "dev" }
        else if hash == -285964041080602815 { return "test" }
        
        return "prod"

    }
}
