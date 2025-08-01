//
//  NCDragDrop.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 27/04/24.
//  Copyright © 2024 Marino Faggiana. All rights reserved.
//
//  Author Marino Faggiana <marino.faggiana@nextcloud.com>
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import UniformTypeIdentifiers
import NextcloudKit

class NCDragDrop: NSObject {
    let utilityFileSystem = NCUtilityFileSystem()
    let database = NCManageDatabase.shared
    let global = NCGlobal.shared

    func performDrag(metadata: tableMetadata? = nil, fileSelect: [String]? = nil) -> [UIDragItem] {
        var metadatas: [tableMetadata] = []

        if let metadata, metadata.status == 0, !metadata.isDirectoryE2EE, !metadata.e2eEncrypted {
            metadatas.append(metadata)
        } else if let fileSelect {
            for ocId in fileSelect {
                if let metadata = database.getMetadataFromOcId(ocId), metadata.status == 0, !metadata.isDirectoryE2EE, !metadata.e2eEncrypted {
                    metadatas.append(metadata)
                }
            }
        }

        let dragItems = metadatas.map { metadata in
            let itemProvider = NSItemProvider()
            itemProvider.registerDataRepresentation(forTypeIdentifier: global.metadataOcIdDataRepresentation, visibility: .all) { completion in
                let data = metadata.ocId.data(using: .utf8)
                completion(data, nil)
                return nil
            }
            return UIDragItem(itemProvider: itemProvider)
        }

        return dragItems
    }

    func performDrop(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator, serverUrl: String, isImageVideo: Bool, controller: NCMainTabBarController?) -> [tableMetadata]? {
        var serverUrl = serverUrl
        var metadatas: [tableMetadata] = []
        DragDropHover.shared.cleanPushDragDropHover()
        DragDropHover.shared.sourceMetadatas = nil

        for item in coordinator.session.items {
            if item.itemProvider.hasItemConformingToTypeIdentifier(global.metadataOcIdDataRepresentation) {
                let semaphore = DispatchSemaphore(value: 0)
                item.itemProvider.loadDataRepresentation(forTypeIdentifier: global.metadataOcIdDataRepresentation) { data, error in
                    if error == nil, let data, let ocId = String(data: data, encoding: .utf8),
                       let metadata = self.database.getMetadataFromOcId(ocId) {
                        if !isImageVideo {
                            metadatas.append(metadata)
                        } else if isImageVideo, metadata.isImageOrVideo {
                            metadatas.append(metadata)
                        }
                    }
                    semaphore.signal()
                }
                semaphore.wait()
            } else {
                item.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.data.identifier) { url, error in
                    if error == nil, let url = url {
                        if let destinationMetadata = DragDropHover.shared.destinationMetadata, destinationMetadata.directory {
                            serverUrl = destinationMetadata.serverUrl + "/" + destinationMetadata.fileName
                        }
                        self.uploadFile(url: url, serverUrl: serverUrl, controller: controller)
                    }
                }
            }
        }

        var invalidNameIndexes: [Int] = []
        let session = NCSession.shared.getSession(controller: controller)
        let capabilities = NCNetworking.shared.capabilities[session.account] ?? NKCapabilities.Capabilities()

        for (index, metadata) in metadatas.enumerated() {
            if let fileNameError = FileNameValidator.checkFileName(metadata.fileName, account: session.account, capabilities: capabilities) {
                if metadatas.count == 1 {
                    let alert = UIAlertController.renameFile(fileName: metadata.fileNameView, serverUrl: metadata.serverUrl, nativeFormat: true, isDirectory: metadata.directory, capabilities: capabilities, account: metadata.account) { newFileName in
                        metadatas[index].fileName = newFileName
                        metadatas[index].fileNameView = newFileName
                        metadatas[index].serverUrlFileName = metadatas[index].serverUrl + "/" + newFileName
                    }

                    controller?.present(alert, animated: true)
                    return nil
                } else {
                    controller?.present(UIAlertController.warning(message: "\(fileNameError.errorDescription) \(NSLocalizedString("_please_rename_file_", comment: ""))"), animated: true)
                    invalidNameIndexes.append(index)
                }
            }
        }

        for index in invalidNameIndexes.reversed() {
            metadatas.remove(at: index)
        }

        if metadatas.isEmpty {
            return nil
        } else {
            return metadatas
        }
    }

    func uploadFile(url: URL, serverUrl: String, controller: NCMainTabBarController?) {
        do {
            let data = try Data(contentsOf: url)
            Task {
                let session = NCSession.shared.getSession(controller: controller)
                let capabilities = await NKCapabilities.shared.getCapabilities(for: session.account)
                let ocId = NSUUID().uuidString
                let newFileName = FileAutoRenamer.rename(url.lastPathComponent, capabilities: capabilities)
                let fileNamePath = utilityFileSystem.getDirectoryProviderStorageOcId(ocId, fileNameView: newFileName)

                if let fileNameError = FileNameValidator.checkFileName(newFileName, account: session.account, capabilities: capabilities) {
                    await controller?.present(UIAlertController.warning(message: "\(fileNameError.errorDescription) \(NSLocalizedString("_please_rename_file_", comment: ""))"), animated: true)
                    return
                }

                let fileName = await NCNetworking.shared.createFileName(fileNameBase: newFileName, account: session.account, serverUrl: serverUrl)

                try data.write(to: URL(fileURLWithPath: fileNamePath))

                let metadataForUpload = await database.createMetadataAsync(fileName: fileName,
                                                                           ocId: ocId,
                                                                           serverUrl: serverUrl,
                                                                           session: session,
                                                                           sceneIdentifier: controller?.sceneIdentifier)

                metadataForUpload.session = NCNetworking.shared.sessionUploadBackground
                metadataForUpload.sessionSelector = global.selectorUploadFile
                metadataForUpload.size = utilityFileSystem.getFileSize(filePath: fileNamePath)
                metadataForUpload.status = global.metadataStatusWaitUpload
                metadataForUpload.sessionDate = Date()

                database.addMetadata(metadataForUpload)
            }
        } catch {
            NCContentPresenter().showError(error: NKError(error: error))
            return
        }
    }

    func copyFile(metadatas: [tableMetadata], serverUrl: String) {
        for metadata in metadatas {
            NCNetworking.shared.copyMetadata(metadata, serverUrlTo: serverUrl, overwrite: false)
            NCNetworking.shared.notifyAllDelegates { delete in
                delete.transferCopy(metadata: metadata, error: .success)
            }
        }
    }

    func moveFile(metadatas: [tableMetadata], serverUrl: String) {
        for metadata in metadatas {
            NCNetworking.shared.moveMetadata(metadata, serverUrlTo: serverUrl, overwrite: false)
            NCNetworking.shared.notifyAllDelegates { delete in
                delete.transferMove(metadata: metadata, error: .success)
            }
        }
    }
}

// MARK: -

class DragDropHover {
    static let shared = DragDropHover()

    var pushTimerIndexPath: Timer?
    var pushCollectionView: UICollectionView?
    var pushIndexPath: IndexPath?

    var sourceMetadatas: [tableMetadata]?
    var destinationMetadata: tableMetadata?

    func cleanPushDragDropHover() {
        pushTimerIndexPath?.invalidate()
        pushTimerIndexPath = nil
        pushCollectionView = nil
        pushIndexPath = nil
    }
}
