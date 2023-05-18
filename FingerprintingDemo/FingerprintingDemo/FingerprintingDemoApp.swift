//
//  FingerprintingDemoApp.swift
//  FingerprintingDemo
//
//  Created by Aditya Malladi on 4/4/23.
//

import SwiftUI

@main
struct FingerprintingDemoApp: App {
    var body: some Scene {
        WindowGroup {
            LoginView(service: Service(apiKey: "dev_O44BEFPOEYCwdkvdCJyDNcelpNaoXjGq"))
        }
    }
}


