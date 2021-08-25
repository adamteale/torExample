//
//  BaseView.swift
//  TorDemo
//
//  Created by Adam Teale on 13-08-21.
//

import SwiftUI

struct BaseView<V: BaseViewModel>: View {

    let viewModel: V

    init(viewModel: V) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }

}

struct BaseView_Previews: PreviewProvider {
    static var previews: some View {
        
        BaseView(viewModel: BaseViewModel())
    }
}
