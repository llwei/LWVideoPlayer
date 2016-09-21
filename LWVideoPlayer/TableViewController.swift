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

    fileprivate var player = LWVideoPlayer()
    fileprivate var selectedRow: IndexPath?
    fileprivate let assetUrls: [URL] = [
        URL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")!,
        URL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621104820876931.mp4")!,
        URL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")!,
        URL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621104820876931.mp4")!,
        URL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")!,
        URL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621112404690593.mp4")!,
        URL(string: "http://vf1.mtime.cn/Video/2012/06/21/mp4/120621104820876931.mp4")!]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        print("TableViewController.deinit")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        player.stop()
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assetUrls.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if (selectedRow as NSIndexPath?)?.row == (indexPath as NSIndexPath).row {
            // 暂停/继续播放
            if player.playing() {
                player.pause()
            } else {
                player.play()
            }
        } else {
            // 切换视频资源
            selectedRow = indexPath
            
            if let preview = tableView.cellForRow(at: indexPath)?.contentView.viewWithTag(1) as? LWVideoPlayerView {
                let item = AVPlayerItem(url: assetUrls[(indexPath as NSIndexPath).row])
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
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if (selectedRow as NSIndexPath?)?.row == (indexPath as NSIndexPath).row {
            player.stop()
            selectedRow = nil
        }
    }
    

  
}
