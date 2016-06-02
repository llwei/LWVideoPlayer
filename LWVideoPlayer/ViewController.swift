//
//  ViewController.swift
//  LWVideoPlayer
//
//  Created by lailingwei on 16/6/1.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var slider: UISlider!
    private var player = LWVideoPlayer()
    private var seeking = false
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 加载视频
        loadVideo(fetchAssetItemWithLocation(false))
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        player.stop()
    }
    
    deinit {
        print("ViewController.deinit")
    }
    
    
    // MARK: - Helper methods
    
    // 获取要播放是视频资源
    private func fetchAssetItemWithLocation(location: Bool) -> AVPlayerItem {
        var url: NSURL!
        if location {
            if let filePath = NSBundle.mainBundle().pathForResource("sample_clip1", ofType: "m4v") {
                url = NSURL(fileURLWithPath: filePath)
            }
        } else {
            url = NSURL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")
        }
        return AVPlayerItem(URL: url)
    }
    
    // 加载视频
    private func loadVideo(item: AVPlayerItem) {
        player.replaceCurrentItemWithPlayerItem(item,
                                                videoPlayerView: view as! LWVideoPlayerView,
                                                playRepeatCount: 1,
                                                loadingFailedHandler: { (error) in
                                                    
                                                    print(error?.localizedDescription)
                                                    
            }, playbackHandler: {
                [unowned self] (readyToPlay, current, loadedBuffer, totalBuffer, finished) in
                
                if readyToPlay {
                    print("=================readyToPlay is true")
                    print("当前播放进度: \(current)")
                    print("当前资源加载进度: \(loadedBuffer)")
                    print("当前资源总时长: \(totalBuffer)")
                    
                    if !self.seeking {
                        self.slider.setValue(Float(current) / Float(totalBuffer), animated: false)
                    }
                    
                    if finished {
                        print("--------视频播放结束")
                    }
                }
            })
    }
    
    // MARK: - Target actions
    
    // 播放
    @IBAction func play(sender: AnyObject) {
        player.play()
    }
    
    // 暂停
    @IBAction func pause(sender: AnyObject) {
        player.pause()
    }
    
    // 拖动进度
    @IBAction func seek(sender: UISlider) {
        seeking = true
        player.seekToProgress(sender.value, completionHandler: nil)
    }
    
    @IBAction func endSeek(sender: UISlider) {
        seeking = false
    }
    
    // 切换视频
    @IBAction func next(sender: UIBarButtonItem) {
        let flag = rand() % 2 == 1
        let item = fetchAssetItemWithLocation(flag)
        
        loadVideo(item)
    }
}

