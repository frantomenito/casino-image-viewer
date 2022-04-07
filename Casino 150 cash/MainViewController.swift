//
//  MainViewController.swift
//  Casino 150 cash
//
//  Created by Dmytro Maksymyak on 26.07.2021.
//

import UIKit
import UniformTypeIdentifiers
import SwiftCSVExport
import CSVImporter

class MainViewController: UIViewController {
    
    @IBOutlet weak var logOutButton: UIButton!
    @IBOutlet weak var loadFileButton: UIButton!
    var headerValues = [String]()
        
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadView()
    }
    
    @IBAction func LogOutButtonPressed(_ sender: Any) {
        logOutUser()
        reloadView()
    }
    
    @IBAction func loadButtonPressed(_ sender: Any) {
        if isUserLoggedIn() {
            openDocumentPicker(self)
        } else {
            openLogInWindow(self) {
                self.reloadView()
            }
        }
    }
    
    private func openDocumentPicker(_ viewController: UIViewController) {
        let supportedFiles: [UTType] = [UTType.data]
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedFiles)
        documentPicker.delegate = viewController as? UIDocumentPickerDelegate
        documentPicker.modalPresentationStyle = .fullScreen
        viewController.present(documentPicker, animated: true)
    }
    
    private func reloadView() {
        if isUserLoggedIn() {
            loadFileButton.setTitle("Load CSV file", for: .normal)
            logOutButton.isHidden = false
            logOutButton.isUserInteractionEnabled = true
        } else {
            loadFileButton.setTitle("Log In", for: .normal)
            logOutButton.isHidden = true
            logOutButton.isUserInteractionEnabled = false
        }
    }
}

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        let navVc = self.storyboard?.instantiateViewController(identifier: String(describing: type(of: ViewController()))) as! ViewController
            
        guard urls.first!.startAccessingSecurityScopedResource() else { //Start secured connection
            print("error start")
            return
        }
        
        let importer = CSVImporter<[String: String]>(url: urls.first!, delimiter: ";" )
        
        importer!.startImportingRecords(structure: { (headerValues) -> Void in
            self.headerValues = headerValues
            }) { $0 }.onFail {
                print("The CSV file coudnt be read")
            }.onFinish { importedRecords in
                var games = [Game]()
                DispatchQueue.global().async {
                    for game in importedRecords {
                        let myGame = self.generateGame(game)
                        games.append(myGame)
                    }
                
                    navVc.games = games
                    navVc.headerValues = self.headerValues
                    urls.first!.stopAccessingSecurityScopedResource() //Stop secured connection
                    
                    DispatchQueue.main.sync {
                        self.show(navVc, sender: nil)
                    }
                }
            }
        
    }
    
    private func generateGame(_ game: [String: String]) -> Game {
        let id: Int = Int(game["id"]!) ?? 0
        let gameId: Int = Int(game["Game Id"]!) ?? 0
        let title = game["Title"]!
        let gameProvider = game["Games Providers"]!
        let gameLink: URL = URL(string: game["Games Links"]!)!
        let isOk: Int? = Int(game["Is Ok"]!)
        
        return Game(id: id, gameId: gameId, title: title, gameProvider: gameProvider, gameLink: gameLink, isOk: isOk ?? 2)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Picker was cancelled")
        controller.dismiss(animated: true, completion: nil)
    }
}


