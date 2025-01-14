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
    
    
    // ------------------------------------------------
    //  After
    // ------------------------------------------------
}

