//
//  TorClient.swift
//  TorDemo
//
//  Created by Adam Teale on 23-08-21.
//

import Foundation
import Tor


final class TorClient {

    static let shared = TorClient()

    private var configuration = TorConfiguration()
    private var torThread: TorThread!
    private var cookieUrl: URL?
    private var cookie: Data?
    private var torController: TorController?
    private var session: URLSession?

    required init() {
        setup()
    }

    private func setup() {

        let authDirPath = createAuthDirectory()

        configuration.options = [
            "DNSPort": "12345",
            "AutomapHostsOnResolve": "1",
            "SocksPort": "19050",//OnionTrafficOnly
            "AvoidDiskWrites": "1",
            "ClientOnionAuthDir": "\(authDirPath)",
            "LearnCircuitBuildTimeout": "1",
            "NumEntryGuards": "8",
            "SafeSocks": "1",
            "LongLivedPorts": "80,443",
            "NumCPUs": "2",
            "DisableDebuggerAttachment": "1",
            "SafeLogging": "1"
            //"ExcludeExitNodes": "1",
            //"StrictNodes": "1"
        ]
        configuration.cookieAuthentication = true
        configuration.dataDirectory = createTorDirectory()
        configuration.controlSocket = configuration.dataDirectory?.appendingPathComponent("cp")

        torThread = TorThread(configuration: configuration)

        if let controlSocket = configuration.controlSocket {
            torController = TorController(socketURL: controlSocket)

            torThread?.start()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

                if !(self.torController?.isConnected ?? false) {
                    do {
                        try self.torController?.connect()
                    } catch {
                        print("error=\(error)")
                    }
                }

                if let cookieUrl = self.configuration.dataDirectory?.appendingPathComponent("control_auth_cookie") {
                    debugPrint("\(cookieUrl) cookieUrl")
                    do {
                        self.cookie = try Data(
                            contentsOf: cookieUrl,
                            options: NSData.ReadingOptions(rawValue: 0)
                        )
                    } catch {
                        debugPrint("cookie issue", error)
                        return
                    }

                    guard let cookie = self.cookie else {
                        debugPrint("cookie nil...")
                        return
                    }

                    self.torController?.authenticate(with: cookie as Data, completion: { [weak self] success, error in
                        guard let self = self else { return }
                        if !success || (error != nil) {
                            debugPrint("error", error)
                            return
                        }

                        self.torController?.addObserver(forCircuitEstablished: { established in
                            if !established {
                                debugPrint("circuit not established...")
                            }

                            self.torController?.getSessionConfiguration({ uRLSessionConfiguration in
                                guard let uRLSessionConfiguration = uRLSessionConfiguration else {
                                    debugPrint("uRLSessionConfiguration nil...")
                                    return
                                }
                                self.session = URLSession(configuration: uRLSessionConfiguration)
                                debugPrint(self.session)
                            })
                        })
                    })
                }
            }
        }
    }

    private func createTorDirectory() -> URL? {

        let torPath = self.getTorPath()

        do {
            try FileManager.default.createDirectory(
                at: torPath,
                withIntermediateDirectories: true,
                attributes: [
                    FileAttributeKey.posixPermissions: 0o700
                ]
            )
        } catch {
            print("Directory previously created. 🤷‍♀️", error)
        }

        return torPath
    }

    private func getTorPath() -> URL {

        let path = getDocumentsDirectory().appendingPathComponent("tor").appendingPathComponent(".tor_tmp")
        debugPrint(path)
        return path
//        #if targetEnvironment(simulator)
//        print("is simulator")
//
//        let path = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true).first ?? ""
//        torDirectory = "\(path.split(separator: Character("/"))[0..<2].joined(separator: "/"))/.tor_tmp"
//
//        #else
//        print("is device")
//
//        torDirectory = "\(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? "")/t"
//
//        #endif
//
//        return torDirectory

    }


    private func createAuthDirectory() -> String {
        // Create tor v3 auth directory if it does not yet exist
        let authPath = URL(
            fileURLWithPath: getTorPath().path,
            isDirectory: true
        ).appendingPathComponent("onion_auth", isDirectory: true).path

        do {
            try FileManager.default.createDirectory(atPath: authPath,
                                                    withIntermediateDirectories: true,
                                                    attributes: [FileAttributeKey.posixPermissions: 0o700])
        } catch {
            print("Auth directory previously created.")
        }

        return authPath
    }

    private func getDocumentsDirectory() -> URL {

        #if targetEnvironment(simulator)
            let path = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true).first ?? ""
            return URL(fileURLWithPath: "\(path.split(separator: Character("/"))[0..<2].joined(separator: "/"))/.tor_tmp")
        #elseif targetEnvironment(macCatalyst)
            let path = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .userDomainMask, true).first ?? ""
            return URL(fileURLWithPath: "\(path.split(separator: Character("/"))[0..<2].joined(separator: "/"))/.tor_tmp")
        #else
            return URL(fileURLWithPath: "\(NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? "")/tor")
        #endif

    }

    func requestTest(url: URL, onCompletion: @escaping ((String) -> Void)) {

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        let task = session?.dataTask(with: request as URLRequest) { (data, response, error) in
//            debugPrint(data)
//            debugPrint(response)
//            debugPrint(error)

            if let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves) as? NSDictionary {
                DispatchQueue.main.async {
                    onCompletion(json["result"] as! String)
                }
            }
        }

        task?.resume()
    }

    func addObserverForCircuitEstablished(observer: @escaping (() -> Void) ) {
        torController?.addObserver(forCircuitEstablished: { established in
            if established {
                DispatchQueue.main.async {
                    observer()
                }
            }
        })
    }

    func addObserverForCircuitEstablished(observer: @escaping ((TorLogEntry) -> Void) ) {
        torController?.addObserver(forStatusEvents: { a, b, c, d in

            print(a)
            print(b)
            print(c)
            print(d)

            if let d = d {
                if let tag = d["TAG"],
                   let summary = d["SUMMARY"],
                   let progress = d["PROGRESS"] {
                    DispatchQueue.main.async {
                        observer(
                            TorLogEntry(
                                title: "\(summary.replacingOccurrences(of: "\"", with: "")) (\(tag))",
                                detail: "Bootstrapped: \(progress)%"
                            )
                        )
                    }
                }
            }
            return true
        })
    }

}

struct TorLogEntry {
    let title: String
    let detail: String
}
