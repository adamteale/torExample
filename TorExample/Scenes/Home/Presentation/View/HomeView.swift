//
//  HomeView.swift
//  TorDemo
//
//  Created by Adam Teale on 13-08-21.
//

import SwiftUI
import Combine

struct HomeView: View {

    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Button("Make request over tor", action: {
                            viewModel.testConnection()
                        })
                        .frame(
                            idealWidth: geometry.size.width,
                            maxWidth: geometry.size.width
                        )
                        .padding()
                        .background(Color.yellow)
                        .cornerRadius(4)

                    }
                    ScrollView {
                        ScrollViewReader { value in
                            ForEach(viewModel.logEntries) { logEntry in
                                Text(logEntry.text)
                                    .id(logEntry.id)
                                    .lineLimit(nil)
                                    .frame(
                                        idealWidth: geometry.size.width,
                                        maxWidth: geometry.size.width,
                                        alignment: .topLeading
                                    )
                                    .onChange(of: viewModel.logEntries) { adsf in
                                        value.scrollTo(viewModel.logEntries.last?.id, anchor: .bottomLeading)
                                    }
                            }
                        }
                    }
                }
                .padding()
                .background(Color.red)
                .navigationBarTitle(Text("Umbrel"))
                .navigationBarItems(
                    trailing: Group {
                    if viewModel.loading {
                        ProgressView()
                    }
                })
            }
        }
    }

}


//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView()
//    }
//}
