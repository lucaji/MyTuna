//
//  TubeScene.swift
//  SciTuner
//
//  Created by Denis Kreshikhin on 7/18/17.
//  Copyright © 2017 Denis Kreshikhin. All rights reserved.
//
// edited lookaji

import UIKit
import SpriteKit

protocol TubeSceneDelegate: class {
//    func getNotePosition() -> CGFloat
    func getPulsation() -> CGFloat
}

class TubeScene: SKScene {
    weak var customDelegate: TubeSceneDelegate?
    
    var waveNode = SKShapeNode()
    var lastPoints = [CGPoint]()
    
    let gradient = SKSpriteNode(imageNamed: "Gradient")
    
    override func didMove(to view: SKView) {
        backgroundColor = Style.waveBackground
        
        waveNode.fillColor = .clear
        waveNode.strokeColor = .white
        waveNode.lineWidth = 3
        waveNode.glowWidth = 1
        
        gradient.position.x = size.width / 2
        gradient.position.y = size.height / 2
        
        gradient.size = size
        
        addChild(waveNode)
        addChild(gradient)
    }
    
    override func didChangeSize(_ oldSize: CGSize) {
        gradient.position.x = size.width / 2
        gradient.position.y = size.height / 2
        
        gradient.size = size
    }
    
    func draw(wave: [Double]) {
        let count: CGFloat = CGFloat(wave.count)
        let n = 5
        
        var yScale: CGFloat = 1.0
        
        if let pulsation = customDelegate?.getPulsation() {
            if pulsation < 50 {
                yScale = pulsation / 50.0
            }
        }
        
        var points = [CGPoint](repeating: CGPoint(), count:  wave.count / n)
        
        for i in 0..<points.count {
            let u = wave[i * n]
            points[i] =  CGPoint(x: 1.06 * size.width * (CGFloat(i * n) + 0.3) / count, y:  (yScale * CGFloat(u) + 1) * size.height / 2)
        }
        
        for i in 0..<points.count {
            if i >= lastPoints.count {
                break
            }
            
            points[i].y = (lastPoints[i].y + points[i].y) / 2
        }
        
        lastPoints = points
        
        waveNode.path = SKShapeNode(splinePoints: &points, count: points.count).path
    }
    
    func cleanWave() {
        waveNode.path = nil
    }
}
