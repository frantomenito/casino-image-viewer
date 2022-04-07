//
//  ExcelDecoder.swift
//  Casino 150 cash
//
//  Created by Dmytro Maksymyak on 27.07.2021.
//

import Foundation

struct Game: Decodable {
    var id: Int, gameId: Int, title: String, gameProvider: String, gameLink: URL, isOk: Int?
    
    init(id: Int, gameId: Int, title: String, gameProvider: String, gameLink: URL, isOk: Int?) {
        self.id = id
        self.gameId = gameId
        self.title = title
        self.gameProvider = gameProvider
        self.gameLink = gameLink
        self.isOk = isOk
    }
    
    func getDictionary() -> NSMutableDictionary{
        let game = NSMutableDictionary()
        game.setObject(id, forKey: "id" as NSCopying)
        game.setObject(gameId, forKey: "Game Id" as NSCopying)
        game.setObject(title, forKey: "Title" as NSCopying)
        game.setObject(gameProvider, forKey: "Games Providers" as NSCopying)
        game.setObject(gameLink, forKey: "Games Links" as NSCopying)
        game.setObject(isOk ?? 2, forKey: "Is Ok" as NSCopying)
        return game
    }
}
