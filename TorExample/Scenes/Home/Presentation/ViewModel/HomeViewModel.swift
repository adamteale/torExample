//
//  HomeViewModel.swift
//  TorDemo
//
//  Created by Adam Teale on 13-08-21.
//

import Foundation

struct LogEntry: Identifiable, Equatable {
    var id: UUID
    let text: String
}

final class HomeViewModel: BaseViewModel {

    let torClient = TorClient.shared

    @Published var logEntries = [LogEntry]()

    override init() {
        super.init()
        loading = true
        torClient.addObserverForCircuitEstablished { [weak self] in
            self?.loading = false
            self?.logEntries.append(LogEntry(id: UUID(), text: "\n\nCircuit established.✅\n\n"))
        }
        torClient.addObserverForCircuitEstablished { [weak self] text in
            self?.logEntries.append(LogEntry(id: UUID(), text: text))
            debugPrint(text)
        }
    }

    func testConnection() {

        guard let url = URL(string: "http://bpcquxqcswqmb4h37ckcb5yuis644766qunwblshw7cz7khmyc4kbaad.onion/test") else { return }

        logEntries.append(LogEntry(id: UUID(), text: "Request:\n\(url.absoluteString)"))

        loading = true
        torClient.requestTest(url: url) { [weak self] text in
            self?.loading = false
            self?.logEntries.append(LogEntry(id: UUID(), text: "Response:\n\(text)\n"))
        }
    }
}
