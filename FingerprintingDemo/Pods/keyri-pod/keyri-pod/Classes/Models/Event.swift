//
//  Event.swift
//  keyri-pod
//
//  Created by Aditya Malladi on 4/11/23.
//

public class Event: NSObject, Decodable {
    @objc let applicationId: String?
    @objc let createdAt: String?
    @objc let event: String?
    @objc let fingerprintId: String?
    @objc let id: String?
    @objc let ip: String?
    @objc public let location: FPLocation?
    @objc let result: String?
    @objc public let riskParams: String?
    @objc public let signals: [String]?
    @objc let updatedAt: String?
    @objc let userId: String?
    
    private enum CodingKeys: String, CodingKey {
        case applicationId
        case createdAt
        case event
        case fingerprintId
        case id
        case ip
        case location
        case result
        case riskParams
        case signals
        case updatedAt
        case userId
    }
}
