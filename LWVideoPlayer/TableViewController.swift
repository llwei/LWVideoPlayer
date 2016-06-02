//
//  TableViewController.swift
//  LWVideoPlayer
//
//  Created by lailingwei on 16/6/2.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import AVFoundation

private let CellIdentifier = "CellIdentifier"

class TableViewController: UITableViewController {

    private var player = LWVideoPlayer()
    private var selectedRow: NSIndexPath?
    private let assetUrls: [NSURL] = [
        NSURL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")!,
        NSURL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621104820876931.mp4")!,
        NSURL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")!,
        NSURL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621104820876931.mp4")!,
        NSURL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")!,
        NSURL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621112404690593.mp4")!,
        NSURL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621104820876931.mp4")!]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        print("TableViewController.deinit")
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        player.stop()
    }
    
    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetUrls.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if selectedRow?.row == indexPath.row {
            // 暂停/继续播放
            if player.playing() {
                player.pause()
            } else {
                player.play()
            }
        } else {
            // 切换视频资源
            selectedRow = indexPath
            
            if let preview = tableView.cellForRowAtIndexPath(indexPath)?.contentView.viewWithTag(1) as? LWVideoPlayerView {
                let item = AVPlayerItem(URL: assetUrls[indexPath.row])
                player.replaceCurrentItemWithPlayerItem(item,
                                                        videoPlayerView: preview,
                                                        playRepeatCount: 0,
                                                        loadingFailedHandler: { (error) in
                                                            print("-----error: \(error?.localizedDescription)")
                    }, playbackHandler: {
                        (readyToPlay, current, loadedBuffer, totalBuffer, finished) in
                        if readyToPlay {
                            print("=================readyToPlay is true")
                            print("当前播放进度: \(current)")
                            print("当前资源加载进度: \(loadedBuffer)")
                            print("当前资源总时长: \(totalBuffer)")
                        }
                    })
                player.play()
            }
        }
    }
    
    override func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if selectedRow?.row == indexPath.row {
            player.stop()
            selectedRow = nil
        }
    }
    

  
}
