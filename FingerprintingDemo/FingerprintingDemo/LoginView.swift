import SwiftUI
import MapKit
import keyri_pod

struct Account: Identifiable {
    let id = UUID()
    let username: String
}

struct LoginView: View {
    var service: Service
    
    public init(service: Service) {
        self.service = service
        UINavigationBar.appearance().largeTitleTextAttributes = [.font : UIFont(name: "HelveticaNeue-Bold", size: 22)!]
    }
    
    @State var accounts: [Account] = []
    
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showModal = false
    @State private var selectedAccount: Account? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Image(systemName: "envelope").foregroundColor(Color(hex: "934D91"))
                    TextField("Username", text: $email)
                }
                .padding()
                
                HStack {
                    Image(systemName: "lock").foregroundColor(Color(hex: "934D91"))
                    SecureField("Password", text: $password)
                }
                .padding()
                

                Button(action: {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

                    service.registerUser(username: email) { res in
                        if let response = res,
                           let params = response.riskParams,
                           service.parseAccessLevel(jsonString: params) != .DENY {
                            print("user created")
                            let created = Account(username: email)
                            accounts.append(created)
                            selectedAccount = created
                            showModal = true
                        } else {
                            print("user denied")
                            // create a dummy account to display modal, do not actually append
                            selectedAccount = Account(username: email)
                            showModal = true
                        }
                    }
                }) {
                    Text("Register user")
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(hex: "934D91"))
                .cornerRadius(8)
                .padding(.top, 10)

                Spacer()
                Divider()
                    .overlay(.white)

                if accounts.count > 0 {
                    Text("Log in to existing accounts")
                        .padding(.top, 30)
                        .font(.headline)
                }
                List(accounts) { account in
                    Button(action: {
                        selectedAccount = account
                        showModal = true
                    }) {
                        HStack {
                            Text(account.username)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: "934D91"))
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                
                Button(action: {
                    service.resetDevice()
                    accounts = []
                }) {
                    Text("Reset Device")
                }
                .foregroundColor(.white)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(Color(hex: "934D91"))
                .cornerRadius(8)
                .padding(.top, 10)
                
                
                
                NavigationLink(destination: LoggedInView(email: selectedAccount?.username ?? "", service: service, showModal: $showModal), isActive: $showModal) {
                    EmptyView()
                }
            }
            .navigationBarTitle("Keyri Fraud Analytics Demo")
            .navigationBarBackButtonHidden(true)

        }
        .navigationViewStyle(StackNavigationViewStyle())
        .preferredColorScheme(.dark)
        
        .onAppear {
            let arr = service.accounts()
            for string in arr {
                if string != "DeviceCreated" {
                    accounts.append(Account(username: string))
                }
            }
        }
    }
}

struct LoggedInView: View {
    let email: String
    let service: Service

    @Binding var showModal: Bool

    //@State var FPR: FingerprintResponse? = nil
    @State var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.507222, longitude: -0.1275), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))

    @State var signals: [String] = []

    @State var status = "ALLOW"
    @State var color = Color(hex: "1E9E2F")

    @State var shouldShowMessage = false
    @State var message = ""

    @State var loaded = false
    @State var regionSet = false
    
    @State var fpInfo: RiskResponse?
    @State var location: Location?

    @State var flags: [String] = []

    @State var logoutText = "Log out"

    var body: some View {

        VStack {
            Text("Hello, \(email)!")
                .font(.title)
                .padding()

            if shouldShowMessage {
                Text(message)
            }
            if shouldShowMessage {
                Text("Risk Signals:")
            }

            if flags.count > 0 {
                List {
                    ForEach(flags, id: \.self) { flag in
                        Text(flag).foregroundColor(Color(hex: "F7B500"))
                    }
                }
            }
            Spacer()
            if loaded {
                HStack {
                    Text("Risk Status:")
                    Text(status)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(color)
                        .cornerRadius(8)
                }
            }


            if regionSet {
                Map(coordinateRegion: $region)
                    .frame(width: 400, height: 200)
            }

            Text("Device ID: \(try! Keyri(appKey: "").getAssociationKey()!.rawRepresentation.base64EncodedString())")
            Button(action: {
                showModal = false
            }) {
                Text(logoutText)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(hex: "934D91"))
                    .cornerRadius(8)
            }
            .padding()
        }
        .onAppear {
            service.loginUser(username: email) { response in
                self.fpInfo = response
                loaded = true
                let locationData = response!.location!.data(using: .utf8)!
                let location = try? JSONDecoder().decode(Location.self, from: locationData)
                
                if let location = location {
                    print("Called")
                    region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: location.latitude!, longitude: location.longitude!), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
                    regionSet = true
                }

                if let sig = fpInfo?.signals {
                    signals = sig
                }

                if let params = fpInfo?.riskParams {

                    let level = service.parseAccessLevel(jsonString: params)

                        if level == .DENY {
                            color = Color(hex: "C42021")
                            status = "DENY"
                            message = "Your authentication was denied"
                            shouldShowMessage = true
                            logoutText = "Go back"

                        } else if level == .WARN {
                            color = Color(hex: "F7B500")
                            message = "Your authentication looks risky"
                            status = "WARN"
                            shouldShowMessage = true
                            logoutText = "Go back"
                        }
                }
            }
        }
    }
}

