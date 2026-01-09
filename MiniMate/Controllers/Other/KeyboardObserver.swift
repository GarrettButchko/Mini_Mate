//
//  KeyboardObserver.swift
//  MiniMate
//
//  Created by Garrett Butchko on 1/5/26.
//

import SwiftUI
import Combine

final class KeyboardObserver: ObservableObject {
    @Published var height: CGFloat = 0
    private var cancellables = Set<AnyCancellable>()

    init() {
        let willShowOrChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .merge(with: NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification))
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map(\.height)

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        willShowOrChange
            .merge(with: willHide)
            .receive(on: RunLoop.main)
            .sink { [weak self] newHeight in
                DispatchQueue.main.async { self?.height = newHeight }
            }
            .store(in: &cancellables)
    }
}

