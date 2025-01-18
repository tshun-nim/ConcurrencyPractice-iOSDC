//
//  LoginViewModel.swift
//  ConcurrencyPractice-iOSDC
//
//  Created by 田島隼也 on 2025/01/18.
//

import Combine

@MainActor
final class LoginViewModel {
    @Published var id: String = ""
    @Published var password: String = ""
    @Published private(set) var isLoginButtonEnabled: Bool = true
    @Published var loginErrormessage: LoginErroMessage?
    
    let dismiss: PassthroughSubject<Void, Never> = .init()
    
    func loginButtonPressed(
    
    ) async {
        isLoginButtonEnabled = false
        defer {
            isLoginButtonEnabled = true
        }
        // Task.initはactorコンテキストを引き継ぐ -> mainスレッド
        do {
            try await AuthService.shared.login(
                for: .init(rawValue: id),
                with: password
            )
            
            dismiss.send()
        } catch {
            // TODO: エラー処理実装（logger、os.Logger）
            
//            if error is LoginError {
//                loginErrormessage = .login
//            } else {
//
//            }
        }
    }
}

enum LoginErroMessage: Hashable {
    case login
    case network
    case server
    case system
}
