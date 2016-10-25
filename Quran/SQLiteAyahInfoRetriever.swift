//
//  SQLiteAyahInfoPersistence.swift
//  Quran
//
//  Created by Mohamed Afifi on 4/22/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation

struct SQLiteAyahInfoRetriever: AyahInfoRetriever {

    let persistence: AyahInfoStorage

    func retrieveAyahsAtPage(_ page: Int, onCompletion: @escaping (Result<[AyahNumber : [AyahInfo]]>) -> Void) {
        Queue.background.async {
            do {
                let result = try self.persistence.getAyahInfoForPage(page)
                Queue.main.async {
                    onCompletion(Result.success(self.processAyahInfo(result)))
                }
            } catch {
                Crash.recordError(error)
                Queue.main.async({
                    onCompletion(Result.failure(error as? PersistenceError ?? PersistenceError.queryError(error: error)))
                })
            }
        }
    }

    fileprivate func processAyahInfo(_ info: [AyahNumber: [AyahInfo]]) -> [AyahNumber: [AyahInfo]] {
        var result = [AyahNumber: [AyahInfo]]()
        for (ayah, pieces) in info {
            guard pieces.count > 0 else { continue }
            var ayahResult: [AyahInfo] = []
            ayahResult += [pieces[0]]
            var lastAyah = ayahResult[0]
            for i in 1..<pieces.count {
                if pieces[i].line != lastAyah.line {
                    lastAyah = pieces[i]
                    ayahResult += [ pieces[i] ]
                } else {
                    ayahResult += [ ayahResult.removeLast().engulf(pieces[i]) ]
                }
            }
            result[ayah] = ayahResult
        }
        return result
    }
}
