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

class ScannerTableViewController: UITableViewController {
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var emptyPeripheralsView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties

    private var manager: BlinkyManager!
    
    // MARK: - UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isAccessibilityElement = true
        tableView.accessibilityLabel = "Scan Results"
        tableView.accessibilityIdentifier = "scanResults"

        let mock = (UIApplication.shared.delegate as! AppDelegate).mockingEnabled
        manager = BlinkyManager(mock)
        _ = manager.onStateChange { [unowned self] state in
            if state == .poweredOn {
                self.startScan()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
        _ = manager.onBlinkyDiscovery { [unowned self] blinky in
            self.addOrUpdateBlinky(blinky)
        }
        _ = onPeripheralSelected { [unowned self] blinky in
            self.stopScan()
            self.connectBlinky(blinky)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        manager.reset()
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startScan()
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // This will rotate the view displayed when there are no peripherals scanned.
        if view.subviews.contains(emptyPeripheralsView) {
            coordinator.animate(alongsideTransition: { context in
                let width = self.emptyPeripheralsView.frame.width
                let height = self.emptyPeripheralsView.frame.height
                if context.containerView.frame.height > context.containerView.frame.width {
                    self.emptyPeripheralsView.frame = CGRect(
                        x: 0,         y: (context.containerView.frame.height / 2) - 180,
                        width: width, height: height
                    )
                } else {
                    self.emptyPeripheralsView.frame = CGRect(
                        x: 0,         y: 16,
                        width: width, height: height
                    )
                }
            })
        }
    }
    
    // MARK: - UITableViewDelegate
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        if manager.isEmpty {
            showEmptyPeripheralsView()
        } else {
            hideEmptyPeripheralsView()
        }
        return manager.discoveredPeripherals.count > 0 ? 1 : 0
    }
    
    override func tableView(_ tableView: UITableView,
                            titleForHeaderInSection section: Int) -> String? {
        return "Nearby devices"
    }

    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        return manager.discoveredPeripherals.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
                        withIdentifier: BlinkyTableViewCell.reuseIdentifier,
                        for: indexPath
                    ) as! BlinkyTableViewCell
        let blinky = manager.discoveredPeripherals[indexPath.row]
        cell.setupView(withPeripheral: blinky)
        return cell
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        post(.selectPeripheral(at: indexPath.row))
    }

    // MARK: - Segue and navigation
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier == "PushBlinkyView"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PushBlinkyView" {
            if let blinky = sender as? BlinkyPeripheral,
               let destination = segue.destination as? BlinkyViewController {
                destination.blinky = blinky
            }
        }
    }
}

// MARK: - Implementation

private extension ScannerTableViewController {

    func showEmptyPeripheralsView() {
        if !view.subviews.contains(emptyPeripheralsView) {
            view.addSubview(emptyPeripheralsView)
            emptyPeripheralsView.alpha = 0
            emptyPeripheralsView.frame = CGRect(
                    x: 0,                    y: (view.frame.height / 2) - 180,
                    width: view.frame.width, height: emptyPeripheralsView.frame.height)
            view.bringSubviewToFront(emptyPeripheralsView)
            UIView.animate(withDuration: 0.5) {
                self.emptyPeripheralsView.alpha = 1
            }
        }
    }

    func hideEmptyPeripheralsView() {
        if view.subviews.contains(emptyPeripheralsView) {
            UIView.animate(withDuration: 0.5, animations: {
                self.emptyPeripheralsView.alpha = 0
            }, completion: { completed in
                self.emptyPeripheralsView.removeFromSuperview()
            })
        }
    }

    func addOrUpdateBlinky(_ blinky: BlinkyPeripheral) {
        tableView.reloadData()
    }

    func startScan() {
        if manager.startScan() {
            activityIndicator.startAnimating()
        }
    }

    func stopScan() {
        manager.stopScan()
        activityIndicator.stopAnimating()
    }

    func connectBlinky(_ blinky: BlinkyPeripheral) {
        performSegue(withIdentifier: "PushBlinkyView", sender: blinky)
    }

}

extension Notification.Name {

    static let selection = Notification.Name("Selection")

}

extension Notification {

    static func selectPeripheral(at index: Int) -> Notification {
        return Notification(name: .selection, userInfo: ["row": index])
    }

}

private extension ScannerTableViewController {

    func post(_ notification: Notification) {
        NotificationCenter.default.post(notification)
    }

    func dispose(_ observer: NSObjectProtocol) {
        NotificationCenter.default.removeObserver(observer)
    }

    private func on(_ name: Notification.Name, do action: @escaping (Notification) -> ()) -> NSObjectProtocol {
        return NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil, using: action)
    }

    func onPeripheralSelected(do action: @escaping (BlinkyPeripheral) -> ()) -> NSObjectProtocol {
        return on(.selection) { notification in
            if let userInfo = notification.userInfo,
               let index = userInfo["row"] as? Int {
                let blinky = self.manager.discoveredPeripherals[index]
                action(blinky)
            }
        }
    }

}
