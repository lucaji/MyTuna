//
//  GLNPianoView.swift
//  GLNPianoView
//
//  Created by Gary Newby on 16/05/2016.
//  Copyright © 2016 Gary Newby. All rights reserved.
//

import UIKit
import QuartzCore

public protocol GLNPianoViewDelegate: class {
    func pianoKeyUp(_ keyNumber: UInt8)
    func pianoKeyDown(_ keyNumber: UInt8)
}

public class GLNPianoView: UIView {

    @IBInspectable var showNotes: Bool = true
    public weak var delegate: GLNPianoViewDelegate?
    private var _octave: UInt8 = 60
    private var keyObjectsArray: [GLNPianoKey?] = []
    private var _numberOfKeys: Int = 24
    private static let minNumberOfKeys = 12
    private static let maxNumberOfKeys = 61
    private var _blackKeyHeight: CGFloat = 0.60
    private var _blackKeyWidth: CGFloat = 0.80
    private var currentTouches = NSMutableSet(capacity: maxNumberOfKeys)
    private var whiteKeyCount = 0
    private var keyCornerRadius: CGFloat = 0

    @IBInspectable public var numberOfKeys: Int {
        get {
            return _numberOfKeys
        }
        set {
            _numberOfKeys = clamp(value: newValue, min: GLNPianoView.minNumberOfKeys, max: GLNPianoView.maxNumberOfKeys)
            setNeedsLayout()
        }
    }

    @IBInspectable public var blackKeyHeight: CGFloat {
        get {
            return _blackKeyHeight
        }
        set {
            let value = CGFloat(clamp(value: Int(newValue), min: 0, max: 10))
            _blackKeyHeight = (value + 5) * 0.05
        }
    }

    @IBInspectable public var blackKeyWidth: CGFloat {
        get {
            return _blackKeyWidth
        }
        set {
            let value = CGFloat(clamp(value: Int(newValue), min: 0, max: 8))
            _blackKeyWidth = (value + 10) * 0.05
        }
    }
    
    var octave: UInt8 {
        get {
            return _octave
        }
        set {
            _octave = newValue
            setNeedsLayout()
        }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        keyCornerRadius = _blackKeyWidth * 8.0
        whiteKeyCount = 0
        currentTouches = NSMutableSet()
        keyObjectsArray = [GLNPianoKey?](repeating: nil, count: (_numberOfKeys + 1))

        for i in 1 ..< _numberOfKeys + 1 {
            if isWhiteKey(i) {
                whiteKeyCount += 1
            }
        }

        isMultipleTouchEnabled = true
        layer.masksToBounds = true
        if let subLayers = layer.sublayers {
            for layer in subLayers {
                layer.removeFromSuperlayer()
            }
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        commonInit()

        let rect: CGRect = bounds
        let whiteKeyHeight = rect.size.height
        let whiteKeyWidth = whiteKeyWidthForRect(rect)
        let blackKeyHeight = rect.size.height * _blackKeyHeight
        let blackKeyWidth = whiteKeyWidth * _blackKeyWidth
        let blackKeyOffset = blackKeyWidth / 2.0

        // White Keys
        var x: CGFloat = 0
        for i in 0 ..< _numberOfKeys {
            if isWhiteKey(i) {
                let newX = (x + 0.5)
                let newW = ((x + whiteKeyWidth + 0.5) - newX)
                let keyRect = CGRect(x: newX, y: 0, width: newW, height: whiteKeyHeight - 1)
                let key = GLNPianoKey(color: UIColor.white, aRect: keyRect, whiteKey: true, blackKeyWidth: blackKeyWidth,
                                      blackKeyHeight: blackKeyHeight, keyCornerRadius: keyCornerRadius, showNotes: showNotes, noteNumber: (i + Int(octave)))
                keyObjectsArray[i] = key
                layer.addSublayer(key.layer)
                x += whiteKeyWidth
            }
        }
        // Black Keys
        x = 0.0
        for i in 0 ..< _numberOfKeys {
            if isWhiteKey(i) {
                x += whiteKeyWidth
            } else {
                let keyRect = CGRect(x: (x - blackKeyOffset), y: 0, width: blackKeyWidth, height: blackKeyHeight)
                let key = GLNPianoKey(color: UIColor.black, aRect: keyRect, whiteKey: false, blackKeyWidth: blackKeyWidth,
                                      blackKeyHeight: blackKeyHeight, keyCornerRadius: keyCornerRadius, showNotes: showNotes, noteNumber: (i + Int(octave)))
                keyObjectsArray[i] = key
                layer.addSublayer(key.layer)
            }
        }
    }

    func isWhiteKey(_ keyNumber: Int) -> Bool {
        let k = keyNumber % 12
        return (k == 0 || k == 2 || k == 4 || k == 5 || k == 7 || k == 9 || k == 11)
    }

    func whiteKeyWidthForRect(_ rect: CGRect) -> CGFloat {
        return (rect.size.width / CGFloat(whiteKeyCount))
    }

    func updateKeys() {
        let touches = currentTouches.allObjects as Array
        let count = touches.count
        var keyIsDownAtIndex = [Bool](repeating: false, count: _numberOfKeys)

        for i in 0 ..< count {
            let touch = touches[i]
            let point = (touch as AnyObject).location(in: self)
            let index = getKeyContaining(point)
            if index != NSNotFound {
                keyIsDownAtIndex[index] = true
            }
        }

        for i in 0 ..< _numberOfKeys {
            if keyObjectsArray[i]?.isDown != keyIsDownAtIndex[i] {
                if keyIsDownAtIndex[i] {
                    delegate?.pianoKeyDown(UInt8(i))
                    keyObjectsArray[i]?.setImage(keyNum: i, isDown: true)
                } else {
                    delegate?.pianoKeyUp(UInt8(i))
                    keyObjectsArray[i]?.setImage(keyNum: i, isDown: false)
                }
                keyObjectsArray[i]?.isDown = keyIsDownAtIndex[i]
            }
        }
        setNeedsDisplay()
    }

    func getKeyContaining(_ point: CGPoint) -> Int {
        var keyNum = NSNotFound
        for i in 0 ..< _numberOfKeys {
            if let frame = keyObjectsArray[i]?.layer.frame, frame.contains(point) {
                keyNum = i
                if !isWhiteKey(i) {
                    break
                }
            }
        }
        return keyNum
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with _: UIEvent?) {
        for touch in touches {
            currentTouches.add(touch)
        }
        updateKeys()
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with _: UIEvent?) {
        for touch in touches {
            currentTouches.add(touch)
        }
        updateKeys()
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with _: UIEvent?) {
        for touch in touches {
            currentTouches.remove(touch)
        }
        updateKeys()
    }

    func toggleShowNotes() {
        showNotes = !showNotes
        setNeedsLayout()
    }
    
    func clamp(value: Int, min: Int, max: Int) -> Int {
        let r = value < min ? min : value
        return r > max ? max : r
    }
}
