//
//  HomeViewModel.swift
//  TorDemo
//
//  Created by Adam Teale on 13-08-21.
//

import Foundation

enum LogEntryType {
    case title
    case detail
    case awesome
}

struct LogEntry: Identifiable, Equatable {
    var id: UUID
    let text: String
    let entryType: LogEntryType
}

final class HomeViewModel: BaseViewModel {

    let torClient = TorClient.shared

    @Published var logEntries = [LogEntry]()

    override init() {
        super.init()
        loading = true
        torClient.addObserverForCircuitEstablished { [weak self] in
            self?.loading = false
            self?.logEntries.append(LogEntry(id: UUID(), text: "\nCircuit established.✅\n", entryType: .awesome))
        }
        torClient.addObserverForCircuitEstablished { [weak self] torLogEntry in
            self?.logEntries.append(
                LogEntry(id: UUID(), text: torLogEntry.title, entryType: .title)
            )
            self?.logEntries.append(
                LogEntry(id: UUID(), text: torLogEntry.detail, entryType: .detail)
            )
        }
    }

    func testConnection() {

        guard let url = URL(string: "http://bpcquxqcswqmb4h37ckcb5yuis644766qunwblshw7cz7khmyc4kbaad.onion/test") else { return }

        logEntries.append(LogEntry(id: UUID(), text: "\nRequest:", entryType: .title))
        logEntries.append(LogEntry(id: UUID(), text: "\n\(url.absoluteString)", entryType: .detail))

        loading = true
        torClient.requestTest(url: url) { [weak self] text in
            self?.loading = false
            self?.logEntries.append(LogEntry(id: UUID(), text: "\nResponse:", entryType: .title))
            self?.logEntries.append(LogEntry(id: UUID(), text: "\n\(text)", entryType: .detail))
        }
    }
}
