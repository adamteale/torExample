//
//  BaseViewModel.swift
//  TorDemo
//
//  Created by Adam Teale on 13-08-21.
//

import Combine

class BaseViewModel: ObservableObject {
    @Published var loading: Bool = false
}
