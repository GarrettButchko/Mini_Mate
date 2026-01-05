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
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        let willChange = NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)

        willShow
            .merge(with: willChange)
            .compactMap { $0.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect }
            .map { $0.height }
            .sink { [weak self] in self?.height = $0 }
            .store(in: &cancellables)

        willHide
            .map { _ in }
            .sink { [weak self] in self?.height = 0 }
            .store(in: &cancellables)
    }
}
