//
//  LWVideoPlayer.swift
//  LWVideoPlayer
//
//  Created by lailingwei on 16/6/1.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  github: https://github.com/llwei/LWVideoPlayer

import UIKit
import AVFoundation

private var LWVideoPlayerItemStatusContext = "LWVideoPlayerItemStatusContext"
private var LWVideoPlayerItemLoadedTimeRangesContext = "LWVideoPlayerItemLoadedTimeRangesContext"

typealias LoadingFailedHandler = ((_ error: NSError?) -> Void)
typealias PlaybackHandler = ((_ readyToPlay: Bool, _ current: Float64, _ loadedBuffer: Float64, _ totalBuffer: Float64, _ finished: Bool) -> Void)


class LWVideoPlayer: NSObject {
    
    // MARK: Properties
    
    fileprivate var player: AVPlayer? = AVPlayer()
    fileprivate var playerLayer: LWVideoPlayerView?
    
    fileprivate var currentProgressObserver: AnyObject?
    
    fileprivate var repeatCount: UInt = 0
    fileprivate var composable: Bool = true
    fileprivate var readyToPlay: Bool = false
    
    fileprivate var current: Float64 = 0
    fileprivate var loadedBuffer: Float64 = 0
    fileprivate var totalBuffer: Float64 = 0
    
    fileprivate var loadingFailedHandler: LoadingFailedHandler?
    fileprivate var playbackHandler: PlaybackHandler?
    
    
    // MARK:  Life cycle
    
    override init() {
        super.init()
    }
    
    deinit {
        removeObservers()
        print("LWVideoPlayer.deinit")
    }
    
    
    // MARK:  Helper methods
    
    fileprivate func setupPlayback(ofPlayerItem item: AVPlayerItem?, withKeys keys: [String], videoPlayerView: LWVideoPlayerView) {
        guard let asset = item?.asset else { return }
        
        // Check whether the values of each of the keys we need has been successfully loaded
        for key in keys {
            var error: NSError?
            if asset.statusOfValue(forKey: key, error: &error) == .failed {
                loadingFailedHandler?(error)
                return
            }
        }
        
        if !asset.isPlayable {
            // Asset canot be played.
            let error = LWVideoPlayerError.error(Code.itemNotPlayable, failureReason: "Asset canot be played")
            loadingFailedHandler?(error)
            return
        }
        
        // Asset canot be used to create a composition(e.g. it may have protected content).
        self.composable = asset.isComposable
        
        // Set up an AVPlayerLayer
        if asset.tracks(withMediaType: AVMediaTypeVideo).count > 0 {
            videoPlayerView.player = player
            playerLayer = videoPlayerView
        }
        
        // Create a new AVPlayerItem and make it the player's current item.
        player?.replaceCurrentItem(with: item)
        
        // Add rate and status/loadedTimeRanges observers
        addObservers()
    }
    
    
    fileprivate func resetProgressParameters() {
        current = 0
        loadedBuffer = 0
        totalBuffer = 0
    }
    
    
    // MARK:  Observers
    
    fileprivate func addObservers() {
        guard let player = player else { return }
        player.addObserver(self,
                    forKeyPath: "currentItem.status",
                    options: .new,
                    context: &LWVideoPlayerItemStatusContext)
        
        player.addObserver(self,
                    forKeyPath: "currentItem.loadedTimeRanges",
                    options: .new,
                    context: &LWVideoPlayerItemLoadedTimeRangesContext)
        
        // Update "current"
        currentProgressObserver = player.addPeriodicTimeObserver(forInterval: CMTimeMake(1, 1),
                                                                             queue: DispatchQueue.main,
                                                                             using: {
                                                                                [unowned self] (time: CMTime) in
                                                                                
                                                                                self.current = CMTimeGetSeconds(time)
                                                                                self.playbackHandler?(self.readyToPlay,
                                                                                                    self.current,
                                                                                                    self.loadedBuffer,
                                                                                                    self.totalBuffer,
                                                                                                    false)
        }) as AnyObject?
        
        NotificationCenter.default.addObserver(self,
                                                         selector: #selector(LWVideoPlayer.plackbackFinished(_:)),
                                                         name: NSNotification.Name.AVPlayerItemDidPlayToEndTime,
                                                         object: player.currentItem)
    }
    
    fileprivate func removeObservers() {
        
        if let _ = player?.currentItem {
            player?.removeObserver(self,
                                   forKeyPath: "currentItem.status",
                                   context: &LWVideoPlayerItemStatusContext)
            
            player?.removeObserver(self,
                                   forKeyPath: "currentItem.loadedTimeRanges",
                                   context: &LWVideoPlayerItemLoadedTimeRangesContext)
            
            player?.replaceCurrentItem(with: nil)
        }

        if let observer = currentProgressObserver {
            player?.removeTimeObserver(observer)
            currentProgressObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                                         of object: Any?,
                                                  change: [NSKeyValueChangeKey : Any]?,
                                                  context: UnsafeMutableRawPointer?) {
        
        if context == &LWVideoPlayerItemStatusContext {
            if let status = change?[NSKeyValueChangeKey.newKey] as? Int {
                switch status {
                case AVPlayerItemStatus.readyToPlay.rawValue:
                    readyToPlay = true
                    // Update "totalBuffer"
                    if let item = player?.currentItem {
                        totalBuffer = CMTimeGetSeconds(item.duration)
                    }
                case AVPlayerItemStatus.failed.rawValue:
                    readyToPlay = false
                    loadingFailedHandler?(player?.currentItem?.error as NSError?)
                default:
                    readyToPlay = false
                    break
                }
                playbackHandler?(readyToPlay,
                                 current,
                                 loadedBuffer,
                                 totalBuffer,
                                 false)
            }
            
        } else if context == &LWVideoPlayerItemLoadedTimeRangesContext {
            // Update "loadedBuffer"
            if let item = player?.currentItem {
                if let timeRange = item.loadedTimeRanges.first?.timeRangeValue {
                    let startSeconds = CMTimeGetSeconds(timeRange.start)
                    let durationSeconds = CMTimeGetSeconds(timeRange.duration)
                    
                    loadedBuffer = startSeconds + durationSeconds
                    playbackHandler?(readyToPlay,
                                     current,
                                     loadedBuffer,
                                     totalBuffer,
                                     false)
                }
            }
        
        } else {
            super.observeValue(forKeyPath: keyPath,
                                         of: object,
                                         change: change,
                                         context: context)
        }
    }
    
    func plackbackFinished(_ notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        guard item == player?.currentItem else { return }
        
        if repeatCount == 0 {
            playbackHandler?(readyToPlay,
                             current,
                             loadedBuffer,
                             totalBuffer,
                             true)
        } else {
            repeatCount -= 1
            item.seek(to: kCMTimeZero)
            current = 0
            player?.play()
        }
    }

}

// MARK: - Public methods

extension LWVideoPlayer {
    
    /**
     Replaces the player's current item with the specified player item.
     
     - parameter item:                 The AVPlayerItem that will become the player's current item.
     - parameter videoPlayerView:      An instance of AVPlayerLayer to display the visual output of the specified AVPlayer
     - parameter count:                Repeat play count
     - parameter loadingFailedHandler: loadingFailedHandler
     - parameter playbackHandler:      playbackHandler
     */
    func replaceCurrentItemWithPlayerItem(_ item: AVPlayerItem,
                                          videoPlayerView: LWVideoPlayerView,
                                          playRepeatCount count: UInt,
                                                          loadingFailedHandler: LoadingFailedHandler?,
                                                          playbackHandler: PlaybackHandler?) {
        
        // Stop player
        stop()
        
        guard item.status != .failed else {
            self.loadingFailedHandler?(item.error as NSError?)
            return
        }
        
        // Record repeatCount
        repeatCount = count
        
        // Update input asset, and load the values of AVAsset keys to inspect subsequently
        let assetKeysToLoadAndTest = ["playable", "composable", "tracks", "duration"]
        item.asset.loadValuesAsynchronously(forKeys: assetKeysToLoadAndTest) {
            [unowned self] in
            DispatchQueue.main.async(execute: { 
                self.setupPlayback(ofPlayerItem: item, withKeys: assetKeysToLoadAndTest, videoPlayerView: videoPlayerView)
            })
        }
        
        // Set up handlers
        self.loadingFailedHandler = loadingFailedHandler
        self.playbackHandler = playbackHandler
    }
    
    
    func stop() {
        // Remove old observers
        removeObservers()
        
        // Reset progress parameters
        resetProgressParameters()
        
        // Set up old playerLayer.play to nil
        if let playerLayer = playerLayer {
            playerLayer.player = nil
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func playing() -> Bool {
        return  player?.rate == 1.0 ? true : false
    }
    
    func seekToProgress(_ progress: Float, completionHandler: ((Bool) -> Void)?) {
        guard let item = player?.currentItem else { return }
        guard 0 <= progress && progress <= 1 else { return }
        
        let secondes = CMTimeGetSeconds(item.duration) * Float64(progress)
        let time = CMTimeMakeWithSeconds(secondes, item.duration.timescale)
        
        player?.seek(to: time, completionHandler: { (flag: Bool) in
            completionHandler?(flag)
        })
    }
    
    func assetCanComposabled() -> Bool {
        return composable
    }
    
    func currentItem() -> AVPlayerItem? {
        return player?.currentItem
    }
    
}



// MARK: - ============ LWVideoPlayerView ============

class LWVideoPlayerView: UIView {
    
    override class var layerClass : AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer? {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.player = newValue
        }
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.player
        }
    }
    
    var videoGravity: String {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.videoGravity = newValue
        }
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.videoGravity
        }
    }
    
    var readyForDisplay: Bool {
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.isReadyForDisplay
        }
    }
    
    @available(iOS 7.0, *)
    var videoRect: CGRect {
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.videoRect
        }
    }

    @available(iOS 9.0, *)
    var pixelBufferAttributes: [String : AnyObject]? {
        set {
            let playerLayer = layer as! AVPlayerLayer
            playerLayer.pixelBufferAttributes = newValue
        }
        get {
            let playerLayer = layer as! AVPlayerLayer
            return playerLayer.pixelBufferAttributes as [String : AnyObject]?
        }
    }
    
}


// MARK: - ============ LWVideoPlayerError ============

enum Code: Int {
    case itemNotPlayable    = -1001
}

struct LWVideoPlayerError {
    
    static let Domain = "com.lwvideoplayer.error"
    
    static func error(_ code: Code, failureReason: String?) -> NSError {
        let userInfo = [NSLocalizedDescriptionKey : failureReason ?? ""]
        return NSError(domain: Domain, code: code.rawValue, userInfo: userInfo)
    }
}

