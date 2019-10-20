//
//  SplashVC.swift
//  JSonTask
//
//  Created by Mohammed on 25/11/17.
//  Copyright © 2017 Nabeel Gulzar. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class SplashVC: UIViewController {

    var layer: AVPlayerLayer? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.playVideo()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            self.performSegue(withIdentifier: String(describing: HomeVC.self), sender: self)
        })
    }
    private func playVideo() {
        guard let path = Bundle.main.path(forResource: "nabeel", ofType:".mp4") else {
            debugPrint("nabeel.mp4 not found")
            return
        }
        let player = AVPlayer(url: URL(fileURLWithPath: path))
        layer = AVPlayerLayer(player: player)
        layer?.backgroundColor = UIColor.clear.cgColor
        layer?.frame = self.view.frame
        layer?.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(layer!)
        player.play()
        NotificationCenter.default.addObserver(self, selector: #selector(SplashVC.rotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func rotated() {
        layer?.removeFromSuperlayer()
        layer?.frame = self.view.frame
        layer?.videoGravity = .resizeAspectFill
        self.view.layer.addSublayer(layer!)
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
        }
    }
    
    
    @IBAction func task1Action(_ sender: Any) {
        self.performSegue(withIdentifier: "homeToTask1", sender: self)
    }
    
    @IBAction func task2Action(_ sender: Any) {
        self.performSegue(withIdentifier: "homeToTask2", sender: self)
    }
    
}
