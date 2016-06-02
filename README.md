# LWVideoPlayer
基于AVPlayer的视频播放器

Deployment Target iOS 7.0


一、用法：

    // 初始化
    private var player = LWVideoPlayer()
    
    // 加载/切换视频 (注意：让 view 继承 LWVideoPlayerView)
    let url = NSURL(string: "http://vf1.mtime.cn/Video/2012/04/23/mp4/120423212602431929.mp4")
    AVPlayerItem(URL: url)
    player.replaceCurrentItemWithPlayerItem(item,
                                            videoPlayerView: view as! LWVideoPlayerView,
                                            playRepeatCount: 1,                 // 重复播放次数
                                            loadingFailedHandler: { (error) in
                                                // 加载资源发生异常回调
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
                    // 视频播放结束
                    print("--------视频播放结束")
                }
            }
        })


    // 开始播放
    player.play()

    // 暂停播放
    player.pause()

    // 停止播放
    player.stop()

    // 切换播放进度
    player.seekToProgress(sender.value, completionHandler: nil)


