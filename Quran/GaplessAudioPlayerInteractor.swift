//
//  GaplessAudioPlayerInteractor.swift
//  Quran
//
//  Created by Mohamed Afifi on 5/14/16.
//  Copyright © 2016 Quran.com. All rights reserved.
//

import Foundation
import Zip

class GaplessAudioPlayerInteractor: DefaultAudioPlayerInteractor {

    weak var delegate: AudioPlayerInteractorDelegate? = nil

    let downloader: AudioFilesDownloader

    let player: AudioPlayer

    let lastAyahFinder: LastAyahFinder

    var downloadCancelled: Bool = false

    init(downloader: AudioFilesDownloader, lastAyahFinder: LastAyahFinder, player: AudioPlayer) {
        self.downloader = downloader
        self.lastAyahFinder = lastAyahFinder
        self.player = player
        self.player.delegate = self
    }

    func prePlayOperation(qari qari: Qari, startAyah: AyahNumber, endAyah: AyahNumber, completion: () -> Void) {
        guard case .Gapless(let databaseName) = qari.audioType else {
            fatalError("Unsupported qari type gapped")
        }
        let baseFileName = qari.localFolder().URLByAppendingPathComponent(databaseName)
        let dbFile = baseFileName.URLByAppendingPathExtension(Files.DatabaseLocalFileExtension)
        let zipFile = baseFileName.URLByAppendingPathExtension(Files.DatabaseRemoteFileExtension)

        guard !dbFile.checkResourceIsReachableAndReturnError(nil) else {
            completion()
            return
        }

        Queue.background.async {
            do {
                try Zip.unzipFile(zipFile, destination: qari.localFolder(), overwrite: true, password: nil, progress: nil)
            } catch {
                Crash.recordError(error)
                // delete the zip and try to re-download it again, next time.
                let _ = try? NSFileManager.defaultManager().removeItemAtURL(zipFile)
            }

            Queue.main.async {
                completion()
            }
        }
    }
}
