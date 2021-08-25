//
//  TorExampleApp.swift
//  TorExample
//
//  Created by Adam Teale on 23-08-21.
//

import SwiftUI

@main
struct TorExampleApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
        }
    }
}
