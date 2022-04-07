//
//  Dropbox.swift
//  Casino 150 cash
//
//  Created by Dmytro Maksymyak on 07.08.2021.
//

import UIKit
import SwiftyDropbox

func openLogInWindow(_ viewController: UIViewController, completion: @escaping () -> Void) {
    let scopeRequest = ScopeRequest(scopeType: .user, scopes: ["account_info.read", "files.content.write", "files.content.write", "sharing.write"], includeGrantedScopes: false)
    DropboxClientsManager.authorizeFromControllerV2(UIApplication.shared,
                                                    controller: viewController,
                                                    loadingStatusDelegate: nil,
                                                    openURL: { (url: URL) -> Void in UIApplication.shared.openURL(url) },
                                                    scopeRequest: scopeRequest)
}


private let client = DropboxClientsManager.authorizedClient!

func createFolder(named: String) {
    client.files.createFolderV2(path: "/\(named)").response(completionHandler: { response, error in
        if let response = response {
            print(response)
        } else if let error = error {
            print(error)
        }
    })
}

func uploadImage(image: UIImage, path: String, completion: @escaping (_ sharedImageURL: URL?, String?) -> Void) {
    let imageData = image.pngData()
    
    let _ = client.files.upload(path: "/\(path)", input: imageData!).response(completionHandler: { response, error in
        if error == nil {
            shareImage(path: (response?.pathLower)!) { url, error in
                if error == nil {
                    completion(url, nil)
                } else {
                    completion(nil, error)
                }
            }
        } else {
            completion(nil, error!.description)
        }
    }).progress { progressData in
        print(progressData)
    }
}

func shareImage(path: String, completion: @escaping (URL?, String?) -> Void) {
    client.sharing.createSharedLinkWithSettings(path: path, settings: .none).response { response, error in
        if let response = response {
            var goodURL = response.url
            goodURL.removeLast(4)
            let realURL: String = goodURL + "raw=1"
            print(realURL)
            completion(URL(string:realURL), nil)
        } else if let error = error {
            completion(nil, error.description)
        }
    }
}

func isUserLoggedIn() -> Bool {
    return DropboxOAuthManager.sharedOAuthManager.hasStoredAccessTokens()
}

func logOutUser() {
    DropboxClientsManager.unlinkClients()
}
