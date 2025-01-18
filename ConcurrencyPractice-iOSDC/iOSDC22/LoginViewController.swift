//
//  LoginViewController.swift
//  ConcurrencyPractice-iOSDC
//
//  Created by 田島隼也 on 2025/01/18.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet weak var idField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    var viewModel = LoginViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        viewModel.$isLoginButtonEnabled.sink { [weak self] isEnabled in
            guard let self else { return }
            self.loginButton.isEnabled = isEnabled
        }
//        .store(in: &cancellables)
        
        viewModel.dismiss.sink { [weak self] _ in
            self?.parent?.dismiss(animated: true)
        }
//        .store(in: &cancellables)
    }

    
    @IBAction func loginButtonPressed(_ sender: Any) {
        // IBActionはmainスレッド
        // 同期メソッドから非同期処理を始めるにはTask.initを使用
        Task {
            await viewModel.loginButtonPressed()
        }
    }
}

actor AuthService {
    static let shared: AuthService = .init()
    private init() {}
    
    private var isLoggingIn: Bool = false
    
    func login(
        for id: User.ID,
        with password: String
    ) async throws {
        if isLoggingIn { return }
        
        isLoggingIn = true
        defer { isLoggingIn = false}
        let idToken = try await AuthAPI.login(
            for: id,
            with: password
        )
        
        try await IDTokenStore.shared.update(idToken)
    }
}

// actorはシリアルエグゼキュータを持つが、インスタンス単位なので、シングルトンにしておく
actor IDTokenStore {
    static let shared: IDTokenStore = .init()
    private init() {}
    
    func update(_ value: IDToken) throws {
        let data: Data = value.rawValue.data(using: .utf8)!
        let url: URL = .libraryDirectory.appendingPathComponent("IDToken")
        try data.write(to: url, options: .atomic)
    }
}


enum AuthAPI {
    static func login(
        for id: User.ID,
        with password: String
    ) async throws -> IDToken {
        let url: URL = URL(string: "https://example.com")!
        let request: URLRequest = URLRequest(url: url)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // レスポンスからIDトークンを取得
        // ...
        sleep(5)
        
        return IDToken(rawValue: "")
    }
}

struct IDToken {
    let rawValue: String
    init(rawValue: String) {
        self.rawValue = rawValue
    }
}

struct User: Identifiable, Sendable {
    let id: ID
    var nickname: String
    var birthday: Date
    
    struct ID: Hashable, Sendable {
        let rawValue: String
        init(rawValue: String) {
            self.rawValue = rawValue
        }
    }
}

// Xcode 13 までの場合はDate型はSendableに準拠していない
// @unchecked Sendableで強制的に準拠。（※Sendableにしても安全な場合のみ）
#if compiler(<14)
extension Date: @unchecked Sendable {}
#endif
