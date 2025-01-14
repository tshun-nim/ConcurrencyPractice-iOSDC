//
//  ViewController.swift
//  ConcurrencyPractice-iOSDC
//
//  Created by 田島隼也 on 2025/01/08.
//

import UIKit

class ViewController: UIViewController {
    let url = URL(string: "https://example.com")!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - IBActions
    // case1
    @IBAction func case1btn(_ sender: Any) {
        // ## Before ##
        // downloadData(from: url) { data in
        //     // dataを使う処理
        // }
        
        // **** After ****
        // # 戻り値でdataを取得
        Task {
            let data = await downloadData(from: url)
        }
        
        // **** 注意点 ****
        // # 非同期処理のため、下記の処理は全て同じスレッドで実行されているかは分からない
        // print("A")
        // let data = await downloadData(from: url)
        // print("A")
    }
    
    
    // MARK: - Case1. 非同期関数の利用（エラーハンドリングがある場合）
    // ------------------------------------------------
    //  Before: コールバックでdataを使う処理を記述
    // ------------------------------------------------
    @available(*, deprecated, message: "Not Conccurency")
    func downloadData(from url: URL, completoin: @escaping (Data) -> Void) {
        // データ取得処理
    }
    
    // ------------------------------------------------
    //  After: 戻り値でdataを取得
    // ------------------------------------------------
    func downloadData(from url: URL) async -> Data {
        // データ取得処理
        return Data()
    }
    
    
    // MARK: - Case3. 非同期関数の利用（エラーハンドリングがある場合）
    // ------------------------------------------------
    //  Before
    // ------------------------------------------------
    @available(*, deprecated, message: "Not Conccurency")
    func downloadData2(from url: URL, completoin: @escaping (Result<Data, Error>) -> Void) {
        // データ取得処理
    }
    // **** 使用例 ****
    // downloadData(from: url) { result in
    //     do {
    //         let data = try result.get()
    //         // dataを使う処理
    //     } catch {
    //         // エラーハンドリング
    //     }
    // }
    
    // ------------------------------------------------
    //  After
    // ------------------------------------------------
    func downloadData2(from url: URL) async throws -> Data {
        // データ取得処理
        return Data()
    }
    // **** 使用例 ****
    // do {
    //     let data = try await downloadData2(from: url)
    //     // dataを使う処理
    // } catch {
    //     // エラーハンドリング
    // }
    
    
    // MARK: - Case4. 非同期関数の利用（エラーハンドリングがある場合）
    // 例) Userを表すJSONを取得してデコード
    struct User: Decodable {
        let id: ID
        let iconURL: URL
        
        init(id: ID, iconURL: URL) {
            self.id = id
            self.iconURL = iconURL
        }
        
        struct ID: Decodable {
            
        }
    }
    
    // ------------------------------------------------
    //  Before
    // ------------------------------------------------
    @available(*, deprecated, message: "Not Conccurency")
    func fetchUser(for id: String, completoin: @escaping (Result<User, Error>) -> Void) {
        let url: URL = .init(string: "")!
        
        downloadData2(from: url) { result in
            do {
                let data = try result.get()
                let user = try JSONDecoder().decode(User.self, from: data)
                completoin(.success(user))
            } catch {
                completoin(.failure(error))
            }
        }
    }
    
    // ------------------------------------------------
    //  After
    // ------------------------------------------------
    func fetchUser(for id: String) async throws -> User {
        let url: URL = .init(string: "")!
        
        let data = try await downloadData2(from: url)
        let user = try JSONDecoder().decode(User.self, from: data)
        return user
    }
    
    // ** メモ **
    // async/await では do/catch を使用せずに直接throwsでエラーを投げられる！
    // asyncとthrowsを併用することでより強力となる！
    
    
    // MARK: - Case5. 非同期関数の連結
    // 例) ユーザーアイコンのダウンロード（ただし、アイコンのURLはユーザーのJSONの中に記載）
    
    // ------------------------------------------------
    //  Before
    // ------------------------------------------------
    @available(*, deprecated, message: "Not Conccurency")
    func fetchUserIcon(for id: User.ID, completion: @escaping (Result<Data, Error>) -> Void) {
        let url: URL = .init(string: "")!
        
        downloadData2(from: url) { [self] data in
            do {
                let data = try data.get()
                let user = try JSONDecoder().decode(User.self, from: data)
                downloadData2(from: user.iconURL) { icon in
                    do {
                        let icon = try icon.get()
                        completion(.success(icon))
                    } catch {
                        completion(.failure(error))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    
    // ------------------------------------------------
    //  After
    // ------------------------------------------------
    func fetchUserIcon(for id: User.ID) async throws -> Data {
        let url: URL = .init(string: "")!
        
        let data = try await downloadData2(from: url)
        let user = try JSONDecoder().decode(User.self, from: data)
        let icon = try await downloadData2(from: user.iconURL)
        return icon
    }
    
    
    // MARK: - Case6. コールバックからasyncへの変換
    // `withCheckedThrowingContinuation` のクロージャの引数で `CheckedContinuation` を取得。
    // `CheckedContinuation` の `resume(returning: )` で戻り値としてreturn、`resume(throwing: )` でthrowしてくれる
    func downloadData3(from url: URL) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            downloadData2(from: url) { result in
                do {
                    let data = try result.get()
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
            // Result型で受け取っている場合は、`resume(with: )` で返せる
            // downloadData2(from: url) { result in
            //     continuation.resume(with: result)
            // }
        }
    }
    
    
    // MARK: - Structured Conccurency
    // MARK: - Case7. 非同期処理の開始
    // async関数はasync関数の中でしか呼べない -> async関数を呼び出すコールスタック全体がasyncで繋がってしまう... どうするか？
    // すべてのasync関数はTask上で実行される -> メインスレッド内でasync関数を使用したい場合はTask{}を使用する（async関数を使用するコールスタックは、根っこまで辿ると必ずTaskがある）
    func foo() async {}
    
    @MainActor
    func main() {
        Task {
            await foo()
        }
    }
    // 例1) viewDidAppear: ViewControllerが表示されたらfetchUser（async関数）でUserを取得して表示
    // 例2) @IBAction: ダウンロードボタンが押されたらdownloadData（async関数）でダウンロード
    
    
    // MARK: - Case9. 並行処理（固定個数の場合）
    // 例) 大小のアイコンを同時にダウンロード（SNSで低解像度と高解像度のアイコンを同時にダウンロードするケースを想定）
    func fetchUserIcon(for id: User.ID) async throws -> (small: Data, large: Data) {
        let smallURL: URL = .init(string: "")!
        let largeURL: URL = .init(string: "")!
        
        // これでは並行処理にならない
        // let smallIcon = try await downloadData2(from: smallURL)
        // let largeIcon = try await downloadData2(from: largeURL)
        // let icons = (small: smallIcon, large: largeIcon)
        
        // async let では完了を待たずに次の処理を開始 → awaitの段階で完了を待つ
        async let smallIcon = downloadData2(from: smallURL)
        async let largeIcon = downloadData2(from: largeURL)
        let icons = try await (small: smallIcon, large: largeIcon)
        
        return icons
    }
}

