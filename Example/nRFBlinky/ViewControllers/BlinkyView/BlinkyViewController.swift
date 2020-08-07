/*
* Copyright (c) 2020, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import UIKit

class BlinkyViewController: UITableViewController {

    // MARK: - Outlets and Actions

    @IBOutlet weak var ledStateLabel: UILabel!
    @IBOutlet weak var ledToggleSwitch: UISwitch!
    @IBOutlet weak var buttonStateLabel: UILabel!

    @IBAction func ledToggleSwitchDidChange(_ sender: UISwitch) {
        handleSwitchValueChange(newValue: sender.isOn)
    }

    // MARK: - Properties

    private var hapticGenerator: NSObject? // UIImpactFeedbackGenerator is available on iOS 10 and above

    var blinky: BlinkyPeripheral! {
        didSet {
            title = blinky.advertisedName
        }
    }

    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel = "Blinky Control"
        tableView.accessibilityIdentifier = "control"

        blinky.onReady { [unowned self] ledSupported, buttonSupported in
            self.blinkyDidConnect(ledSupported: ledSupported, buttonSupported: buttonSupported)
        }
        let ledObserver = blinky.onLedStateDidChange { [unowned self] isOn in
            self.ledStateChanged(isOn: isOn)
        }
        let buttonObserver = blinky.onButtonStateDidChange { [unowned self] isPressed in
            self.buttonStateChanged(isPressed: isPressed)
        }
        blinky.onConnectionError { [weak self] error in
            self?.showErrorMessage(error?.localizedDescription ?? "Connection failed.")
        }
        blinky.onDisconnected { [weak self] error in
            if let error = error {
                self?.showErrorMessage(error.localizedDescription)
            }
            self?.blinky.dispose(ledObserver)
            self?.blinky.dispose(buttonObserver)
            self?.blinkyDidDisconnect()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !blinky.isConnected else {
            // View is coming back from a swipe, everything is already setup
            return
        }
        prepareHaptics()
        blinky.connect()
    }

    override func viewWillDisappear(_ animated: Bool) {
        // Restore original navigation bar color. It might have changed
        // when the device got disconnected.
        self.setNavigationBarColor(.dynamicColor(light: .nordicBlue, dark: .black))
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        blinky.disconnect()
        super.viewDidDisappear(animated)
    }

    // MARK: - Implementation

    private func handleSwitchValueChange(newValue isOn: Bool) {
        if isOn {
            blinky.turnOnLED()
            ledStateLabel.text = "ON".localized
        } else {
            blinky.turnOffLED()
            ledStateLabel.text = "OFF".localized
        }
    }

    /// This will run on iOS 10 or above and will generate a tap feedback
    /// when the button is tapped on the Dev kit.
    private func prepareHaptics() {
        if #available(iOS 10.0, *) {
            hapticGenerator = UIImpactFeedbackGenerator(style: .heavy)
            (hapticGenerator as? UIImpactFeedbackGenerator)?.prepare()
        }
    }

    /// Generates a tap feedback on iOS 10 or above.
    private func buttonTapHapticFeedback() {
        if #available(iOS 10.0, *) {
            (hapticGenerator as? UIImpactFeedbackGenerator)?.impactOccurred()
        }
    }

}

// MARK: - Blinky Delegate

private extension BlinkyViewController {

    func blinkyDidConnect(ledSupported: Bool, buttonSupported: Bool) {
        if ledSupported || buttonSupported {
            DispatchQueue.main.async {
                self.ledToggleSwitch.isEnabled = ledSupported

                if buttonSupported {
                    self.buttonStateLabel.text = "Reading...".localized
                }
                if ledSupported {
                    self.ledStateLabel.text    = "Reading...".localized
                }
            }
        } else {
            // Not supported device
            blinky.disconnect()
        }
    }
    
    func blinkyDidDisconnect() {
        DispatchQueue.main.async {
            self.setNavigationBarColor(.dynamicColor(light: .nordicRed, dark: .nordicRedDark))
            self.ledToggleSwitch.onTintColor = .nordicRed
            self.ledToggleSwitch.isEnabled = false
        }
    }
    
    func ledStateChanged(isOn: Bool) {
        DispatchQueue.main.async {
            if isOn {
                self.ledStateLabel.text = "ON".localized
                self.ledToggleSwitch.setOn(true, animated: true)
            } else {
                self.ledStateLabel.text = "OFF".localized
                self.ledToggleSwitch.setOn(false, animated: true)
            }
        }
    }
    
    func buttonStateChanged(isPressed: Bool) {
        DispatchQueue.main.async {
            if isPressed {
                self.buttonStateLabel.text = "PRESSED".localized
            } else {
                self.buttonStateLabel.text = "RELEASED".localized
            }
            self.buttonTapHapticFeedback()
        }
    }
    
    func showErrorMessage(_ message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error",
                                          message: message,
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            self.present(alert, animated: true)
        }
    }
}

private extension BlinkyViewController {
    
    /// Sets the color of the Navigation Bar to given one.
    /// - Parameter color: The new Navigation Bar color.
    func setNavigationBarColor(_ color: UIColor) {
        let navigationBar = navigationController?.navigationBar
        if #available(iOS 13.0, *) {
            navigationBar?.standardAppearance.backgroundColor = color
            navigationBar?.scrollEdgeAppearance?.backgroundColor = color
        } else {
            navigationBar?.barTintColor = color
        }
    }
    
}
