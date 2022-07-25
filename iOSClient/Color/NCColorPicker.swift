//
//  NCColorPicker.swift
//  Nextcloud
//
//  Created by Marino Faggiana on 24/07/22.
//  Copyright © 2022 Marino Faggiana. All rights reserved.
//

import Foundation
import UIKit

class NCColorPicker: UIViewController {

    @IBOutlet weak var closeButton: UIButton!

    @IBOutlet weak var orangeButton: UIButton!
    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var purpleButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    @IBOutlet weak var brownButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var grayButton: UIButton!
    @IBOutlet weak var cyanButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!

    @IBOutlet weak var systemIndigoButton: UIButton!
    @IBOutlet weak var systemMintButton: UIButton!
    @IBOutlet weak var systemPinkButton: UIButton!
    @IBOutlet weak var systemTealButton: UIButton!
    @IBOutlet weak var systemBlueButton: UIButton!

    @IBOutlet weak var defaultButton: UIButton!

    var metadata: tableMetadata?
    var tapAction: UITapGestureRecognizer?

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = NCBrandColor.shared.secondarySystemBackground

        closeButton.setImage(NCUtility.shared.loadImage(named: "xmark", color: NCBrandColor.shared.label), for: .normal)

        orangeButton.backgroundColor = .orange
        orangeButton.layer.cornerRadius = 5
        orangeButton.layer.masksToBounds = true

        redButton.backgroundColor = .red
        redButton.layer.cornerRadius = 5
        redButton.layer.masksToBounds = true

        purpleButton.backgroundColor = .purple
        purpleButton.layer.cornerRadius = 5
        purpleButton.layer.masksToBounds = true

        blueButton.backgroundColor = .blue
        blueButton.layer.cornerRadius = 5
        blueButton.layer.masksToBounds = true

        brownButton.backgroundColor = .brown
        brownButton.layer.cornerRadius = 5
        brownButton.layer.masksToBounds = true

        greenButton.backgroundColor = .green
        greenButton.layer.cornerRadius = 5
        greenButton.layer.masksToBounds = true

        grayButton.backgroundColor = .gray
        grayButton.layer.cornerRadius = 5
        grayButton.layer.masksToBounds = true

        cyanButton.backgroundColor = .cyan
        cyanButton.layer.cornerRadius = 5
        cyanButton.layer.masksToBounds = true

        yellowButton.backgroundColor = .yellow
        yellowButton.layer.cornerRadius = 5
        yellowButton.layer.masksToBounds = true

        systemBlueButton.backgroundColor = NCBrandColor.shared.systemBlue
        systemBlueButton.layer.cornerRadius = 5
        systemBlueButton.layer.masksToBounds = true

        systemMintButton.backgroundColor = NCBrandColor.shared.systemMint
        systemMintButton.layer.cornerRadius = 5
        systemMintButton.layer.masksToBounds = true

        systemPinkButton.backgroundColor = NCBrandColor.shared.systemPink
        systemPinkButton.layer.cornerRadius = 5
        systemPinkButton.layer.masksToBounds = true

        systemTealButton.backgroundColor = NCBrandColor.shared.systemTeal
        systemTealButton.layer.cornerRadius = 5
        systemTealButton.layer.masksToBounds = true

        systemIndigoButton.backgroundColor = NCBrandColor.shared.systemIndigo
        systemIndigoButton.layer.cornerRadius = 5
        systemIndigoButton.layer.masksToBounds = true

        defaultButton.backgroundColor = NCBrandColor.shared.brandElement
        defaultButton.layer.cornerRadius = 5
        defaultButton.layer.masksToBounds = true
        defaultButton.layer.borderColor = NCBrandColor.shared.label.cgColor
        defaultButton.layer.borderWidth = 1
    }

    // MARK: - Action

    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func orangeButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.orange.hexString)
    }

    @IBAction func redButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.red.hexString)
    }

    @IBAction func purpleButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.purple.hexString)
    }

    @IBAction func blueButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.blue.hexString)
    }

    @IBAction func brownButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.brown.hexString)
    }

    @IBAction func greenButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.green.hexString)
    }

    @IBAction func grayButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.gray.hexString)
    }

    @IBAction func cyanButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.cyan.hexString)
    }

    @IBAction func yellowButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: UIColor.yellow.hexString)
    }

    @IBAction func systemIndigoButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: NCBrandColor.shared.systemIndigo.hexString)
    }

    @IBAction func systemMintButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: NCBrandColor.shared.systemMint.hexString)
    }

    @IBAction func systemPinkButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: NCBrandColor.shared.systemPink.hexString)
    }

    @IBAction func systemTealButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: NCBrandColor.shared.systemTeal.hexString)
    }

    @IBAction func systemBlueButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: NCBrandColor.shared.systemBlue.hexString)
    }

    @IBAction func defaultButtonAction(_ sender: AnyObject) {
        updateColor(hexColor: nil)
    }

    func updateColor(hexColor: String?) {
        if let metadata = metadata {
            let serverUrl = metadata.serverUrl + "/" + metadata.fileName
            if NCManageDatabase.shared.setDirectory(serverUrl: serverUrl, colorFolder: hexColor, account: metadata.account) != nil {
                self.dismiss(animated: true)
                NotificationCenter.default.postOnMainThread(name: NCGlobal.shared.notificationCenterReloadDataSource, userInfo: ["serverUrl": metadata.serverUrl])
            }
        }
        self.dismiss(animated: true)
    }
}
