//
//  TorExample_iOSApp.swift
//  TorExample-iOS
//
//  Created by Adam Teale on 23-08-21.
//

import SwiftUI

@main
struct TorExample_iOSApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
        }
    }
}
