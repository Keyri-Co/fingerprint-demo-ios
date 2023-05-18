//
//  Service.swift
//  FingerprintingDemo
//
//  Created by Aditya Malladi on 4/11/23.
//

import Foundation
import keyri_pod

public class Service {
    let keyri: Keyri
    
    public init(apiKey: String) {
        keyri = Keyri(appKey: "", publicApiKey: apiKey)
    }
    
    public func registerUser(username: String, completion: @escaping (RiskResponse?) -> ()) {
        
        try? keyri.generateAssociationKey(username: username)
        
        event(username: username, eventType: .signup) { response in
            if let response = response {
                self.event(username: username, eventType: .signup) { response in
                    guard let response = response else { return }
                    
                    let dict = [
                        "username": username,
                        "password": "",
                        "publicKey": "C1uC8r7C53NcF/qaUPFDSEoAOh2sbvOLjAetcEKDs1eC40Vx14NMikNJu4aTGD4C9ijL2mvQYekEGxOy2Oj1lA==",
                        "encryptedSignupEventString": self.stringifyFingerprintResponse(response)!
                    ] as [String : String]
                    
                    let url = URL(string: "https://fraud-demo.keyri.com/api/signup")!

                    var request = URLRequest(url: url)
                    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpMethod = "POST"
                    
                    do {
                        let jsonData = try JSONSerialization.data(withJSONObject: dict)
                        request.httpBody = jsonData

                        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                            guard let data = data, error == nil else {
                                print(error?.localizedDescription ?? "No data")
                                return
                            }

                            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                            print("\n response json here ")
                            if let responseJSON = responseJSON as? [String: Any] {
                                print(responseJSON)
                            }
                            
                            let responseObject = try! JSONDecoder().decode(ResponseData.self, from: data)
                            print("SUCCESS")
                            print(responseObject)
                            print(responseObject.riskResponse)
                            
                            let jsonData = responseObject.riskResponse!.data(using: .utf8)!
                            let decoder = JSONDecoder()
                            let riskResponse = try! decoder.decode(RiskResponse.self, from: jsonData)
                            print(riskResponse)
                            print(riskResponse.signals)
                            print(riskResponse.location)
                            
                            
                            let locationData = riskResponse.location!.data(using: .utf8)!
                            let location = try! decoder.decode(Location.self, from: locationData)
                            print(location)
                            
                            let accessLevel = self.parseAccessLevel(jsonString: riskResponse.riskParams!)
                            print(accessLevel)
                            
                            completion(riskResponse)
                        }

                        task.resume()
                    } catch {
                        print(error)
                        completion(nil)
                    }
                }
            }
        }
    }
    
//    func register(username: String, password: String, completion: @escaping (Bool) -> ()) {
//        print(username)
//        // Create URL
//        let url = URL(string: "https://keyri-fraud-analytics-demo.vercel.app/api/signup")!
//
//        if let _ = try? keyri.getAssociationKey(username: username) {
//            completion(true)
//            return
//        }
//
//
//        // Create request object
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Create request body
//        let body: [String: Any] = [
//            "username": username,
//            "password": password,
//            "publicKey": "publicKey"
//        ]
//        let jsonData = try? JSONSerialization.data(withJSONObject: body)
//        request.httpBody = jsonData
//
//        // Create URLSession
//        let session = URLSession.shared
//
//        // Perform request
//        let task = session.dataTask(with: request) { (data, response, error) in
//            if let error = error {
//                print("Error: \(error)")
//                completion(false)
//                return
//            }
//
//            if let data = data, let dataString = String(data: data, encoding: .utf8) {
//                print("Response: \(dataString)")
//                _ = try? self.keyri.generateAssociationKey(username: username)
//                try? self.keyri.sendEvent(username: username, eventType: .signup, success: true) { res in
//
//                }
//                completion(true)
//
//            }
//        }
//        task.resume()
//    }
//
    func event(username: String, eventType: EventType, completion: @escaping (FingerprintResponse?) -> ()) {
        try? keyri.sendEvent(username: username, eventType: eventType, success: true) { response in
            switch response {
            case .success(let res):
                print("res hello")
                print(res)
                completion(res)
            case .failure(_):
                completion(nil)
            }
        }
    }
    
    public func accounts() -> [String] {
        guard let accounts = keyri.listUniqueAccounts() else { return [] }
        
        return Array(accounts.keys)
    }
    
    public func resetDevice() {
        let accounts = accounts()
        for account in accounts {
            try? keyri.removeAssociationKey(publicUserId: account)
        }
        
    }
    
    public func loginUser(username: String, completion: @escaping (RiskResponse?) -> ()) {
        event(username: username, eventType: .login) { response in
            guard let response = response else {
                completion(nil)
                return
                
            }
            
            let dict = [
                "username": username,
                "password": "",
                "publicKey": "C1uC8r7C53NcF/qaUPFDSEoAOh2sbvOLjAetcEKDs1eC40Vx14NMikNJu4aTGD4C9ijL2mvQYekEGxOy2Oj1lA==",
                "encryptedLoginEventString": self.stringifyFingerprintResponse(response)!
            ] as [String : String]
            
            print("IN THE FUCKING THING")
            
            let url = URL(string: "https://fraud-demo.keyri.com/api/login")!

            var request = URLRequest(url: url)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: dict)
                request.httpBody = jsonData

                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard let data = data, error == nil else {
                        print(error?.localizedDescription ?? "No data")
                        return
                    }

                    let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                    print("\n response json here ")
                    if let responseJSON = responseJSON as? [String: Any] {
                        print(responseJSON)
                    }
                    
                    let responseObject = try! JSONDecoder().decode(ResponseData.self, from: data)
                    print("SUCCESS")
                    print(responseObject)
                    print(responseObject.riskResponse)
                    
                    let jsonData = responseObject.riskResponse!.data(using: .utf8)!
                    let decoder = JSONDecoder()
                    let riskResponse = try! decoder.decode(RiskResponse.self, from: jsonData)
                    print(riskResponse)
                    print(riskResponse.signals)
                    print(riskResponse.location)
                    
                    
                    let locationData = riskResponse.location!.data(using: .utf8)!
                    let location = try! decoder.decode(Location.self, from: locationData)
                    print(location)
                    
                    let accessLevel = self.parseAccessLevel(jsonString: riskResponse.riskParams!)
                    print(accessLevel)
                    
                    completion(riskResponse)
                }

                task.resume()
            } catch {
                print(error)
                completion(nil)
            }
        }
    }
    
    func stringifyFingerprintResponse(_ fingerprintResponse: FingerprintResponse) -> String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        do {
            let data = try encoder.encode(fingerprintResponse)
            return String(data: data, encoding: .utf8)
        } catch {
            print("Error: \(error)")
            return nil
        }
    }
    
    
    public func parseAccessLevel(jsonString: String) -> AccessLevel {
        guard let jsonData = jsonString.data(using: .utf8) else {
            return .DENY
        }
        
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: [String: Bool]] else {
                return .DENY
            }
            
            let deny = jsonObject["deny"] ?? [:]
            let warn = jsonObject["warn"] ?? [:]
            
            let denyValues = deny.values
            let warnValues = warn.values
            
            if denyValues.contains(true) {
                return .DENY
            } else if warnValues.contains(true) {
                return .WARN
            } else {
                return .ALLOW
            }
        } catch {
            print("Error parsing JSON: \(error)")
            return .DENY
        }
    }
}

struct ResponseData: Decodable {
    let token: String?
    let riskResponse: String?
}

public struct RiskResponse: Codable {
    let signals: [String]?
    let riskParams: String?
    let location: String?
    let fingerprintId: String?
}

public struct Location: Codable {
    let region: String?
    let regionCode: String?
    let regionType: String?
    let city: String?
    let country: String?
    let countryCode: String?
    let continent_name: String?
    let continent_code: String?
    let latitude: Double?
    let longitude: Double?
}

public enum AccessLevel {
    case ALLOW
    case WARN
    case DENY
}


