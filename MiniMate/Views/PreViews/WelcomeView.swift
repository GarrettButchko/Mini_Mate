//
//  WelcomeView.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/6/25.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel: WelcomeViewModel

    init(viewManager: ViewManager) {
        _viewModel = StateObject(
            wrappedValue: WelcomeViewModel(viewManager: viewManager)
        )
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(Gradient(colors: [.blue, .green]))
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text(viewModel.displayedText)
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                    .padding()
                    .foregroundStyle(.white)

                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .colorScheme(.light)

                if viewModel.showLoading {
                    VStack(spacing: 16) {
                        Text("Trying to reconnect...")
                            .foregroundStyle(.white)

                        ProgressView()
                            .scaleEffect(1.5)
                    }
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}
