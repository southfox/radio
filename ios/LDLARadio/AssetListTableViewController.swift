//
//  AssetListTableViewController.swift
//  LDLARadio
//
//  Created by Javier Fuchs on 1/6/17.
//  Copyright © 2017 Mobile Patagonia. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MediaPlayer


class AssetListTableViewController: UITableViewController {
    // MARK: Properties
    
    static let presentPlayerViewControllerSegueIdentifier = "PresentPlayerViewControllerSegueIdentifier"
    
    fileprivate var playerViewController: AVPlayerViewController?
    
    // MARK: Deinitialization
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: StreamListManager.didLoadNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: StationListManager.didLoadNotification, object: nil)
    }
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // General setup for auto sizing UITableViewCells.
        tableView.estimatedRowHeight = 75.0
        tableView.rowHeight = UITableViewAutomaticDimension
        
        // Set AssetListTableViewController as the delegate for StreamPlaybackManager to recieve playback information.
        StreamPlaybackManager.sharedManager.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleStreamListManagerDidLoadNotification(_:)), name: StreamListManager.didLoadNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(handleStreamListManagerDidLoadNotification(_:)), name: StationListManager.didLoadNotification, object: nil)
}
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if playerViewController != nil {
            // The view reappeared as a results of dismissing an AVPlayerViewController.
            // Perform cleanup.
            StreamPlaybackManager.sharedManager.setAssetForPlayback(nil)
            playerViewController?.player = nil
            playerViewController = nil
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StreamListManager.sharedManager.numberOfStreams()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AssetListTableViewCell.reuseIdentifier, for: indexPath)
        
        let stream = StreamListManager.sharedManager.stream(at: indexPath.row)
        
        if let cell = cell as? AssetListTableViewCell {
            cell.stream = stream
            cell.delegate = self
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AssetListTableViewCell, let asset = cell.stream else { return }
        
        let downloadState = StreamPersistenceManager.sharedManager.downloadState(for: asset)
        let alertAction: UIAlertAction
        
        switch downloadState {
        case .notDownloaded:
            alertAction = UIAlertAction(title: "Download", style: .default) { _ in
                StreamPersistenceManager.sharedManager.downloadStream(for: asset)
            }
            
        case .downloading:
            alertAction = UIAlertAction(title: "Cancel", style: .default) { _ in
                StreamPersistenceManager.sharedManager.cancelDownload(for: asset)
            }
            
        case .downloaded:
            alertAction = UIAlertAction(title: "Delete", style: .default) { _ in
                StreamPersistenceManager.sharedManager.deleteAsset(asset)
            }
        }
        
        let alertController = UIAlertController(title: asset.name, message: "Select from the following options:", preferredStyle: .actionSheet)
        alertController.addAction(alertAction)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let popoverController = alertController.popoverPresentationController else {
                return
            }
            
            popoverController.sourceView = cell
            popoverController.sourceRect = cell.bounds
        }
        
        present(alertController, animated: true, completion: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        if segue.identifier == AssetListTableViewController.presentPlayerViewControllerSegueIdentifier {
            guard let cell = sender as? AssetListTableViewCell, let playerViewControler = segue.destination as? AVPlayerViewController else { return }
            
            // Grab a reference for the destinationViewController to use in later delegate callbacks from StreamPlaybackManager.
            playerViewController = playerViewControler
            playerViewControler.title = cell.stream?.name
            
            let artwork = MPMediaItemArtwork.init(image: UIImage.init(named: "Locos_de_la_azotea")!)
            MPNowPlayingInfoCenter.default().nowPlayingInfo =
                [MPMediaItemPropertyTitle: cell.stream?.name ?? "Radio",
                 MPMediaItemPropertyArtist: "JF",
                 MPMediaItemPropertyAlbumTitle: "Bariloche",
                 MPMediaItemPropertyArtwork: artwork,
                 MPNowPlayingInfoPropertyPlaybackRate: 1]

            // Load the new Stream to playback into StreamPlaybackManager.
            StreamPlaybackManager.sharedManager.setAssetForPlayback(cell.stream)
        }
    }
    
    // MARK: Notification handling
    
    func handleStreamListManagerDidLoadNotification(_: Notification) {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}

/**
 Extend `AssetListTableViewController` to conform to the `AssetListTableViewCellDelegate` protocol.
 */
extension AssetListTableViewController: AssetListTableViewCellDelegate {
    
    func assetListTableViewCell(_ cell: AssetListTableViewCell, downloadStateDidChange newState: Stream.DownloadState) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

/**
 Extend `AssetListTableViewController` to conform to the `AssetPlaybackDelegate` protocol.
 */
extension AssetListTableViewController: AssetPlaybackDelegate {
    func streamPlaybackManager(_ streamPlaybackManager: StreamPlaybackManager, playerReadyToPlay player: AVPlayer) {
        player.play()
    }
    
    func streamPlaybackManager(_ streamPlaybackManager: StreamPlaybackManager, playerCurrentItemDidChange player: AVPlayer) {
        guard let playerViewController = playerViewController, player.currentItem != nil else { return }
        
        playerViewController.player = player
    }
}
