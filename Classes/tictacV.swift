//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
///************
/// tictac.h
/// Copyright 2011-2021 Robert T. Miller
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///***************

//
//  tictacV.swift
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

///************
/// tictacV.swift
/// Copyright 2011-2021 Robert T. Miller
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
/// http://www.apache.org/licenses/LICENSE-2.0
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.
///***************

//
//  tictacV.swift
//  rTracker
//
//  Created by Robert Miller on 20/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import QuartzCore
import UIKit

// MARK: key singleton access
    var theKey: UInt = 0

class tictacV: UIView {

    var tob: tObjBase?

    var key: UInt {
        get {
            return theKey
        }
        set(k) {
            //DBGLog("setKey: \(theKey) \(String(theKey, radix: 2)) -> \(k) \(String(k, radix: 2))")
            theKey = k
        }
    }
    var currRect = CGRect.zero
    var currRegion: UIAccessibilityElement? = nil
    var currX = 0
    var currY = 0
    // region definitions
    var vborder: CGFloat = 0.0
    var hborder: CGFloat = 0.0
    var vlen: CGFloat = 0.0
    var hlen: CGFloat = 0.0
    var vstep: CGFloat = 0.0
    var hstep: CGFloat = 0.0
    // UI element properties 
    var context: CGContext?
    var myFont: UIFont?
    
    var _accessibilityElements: [UIAccessibilityElement] = []
    override var accessibilityElements: [Any]? {
        get {
            // Return your custom accessibility elements here.
            // UIKit will manage the count automatically.
            return _accessibilityElements
        }
        set {
            // Set the new value here if needed, typically not required.
            DBGLog("why is set called?")
        }
    }
    
    let labels = ["left", "middle", "right"]

    
    // MARK: core object

    //- (id)initWithFrame:(CGRect)frame {
    //    if ((self = [super initWithFrame:frame])) {
    //        // Initialization code
    //    }
    //    return self;
    //}

    init(pFrame pttf: CGRect) {
        var ttf = pttf
        ttf.origin.x = TICTACHRZFRAC * ttf.size.width
        ttf.origin.y = TICTACVRTFRAC * ttf.size.height
        ttf.size.width *= TICTACWIDFRAC
        ttf.size.height *= TICTACHGTFRAC
        //DBGLog(String("ttv: x=\(ttf.origin.x) y=\(ttf.origin.y) w=\(ttf.size.width) h=\(ttf.size.height)"));
        super.init(frame: ttf)
        backgroundColor = .secondarySystemBackground //.white
        layer.cornerRadius = 8 // doesn't work, probably overwriting rectangle elsewhere
        
        drawTicTac()
        setupAccessibility()
    }

    func setupAccessibility() {
        //isAccessibilityElement = true
        //accessibilityIdentifier = "ttv"
        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name:"toggle cell", target: self, selector: #selector(press))
        ]

        for i in 0..<3 {
            for j in 0..<3 {
                setCurrPt(i, y: j)
                
                let region = UIAccessibilityElement(accessibilityContainer: self)
                region.accessibilityIdentifier = "\(labels[i])-\(labels[j])"
                region.accessibilityLabel = "\(labels[i]) \(labels[j])"
                region.accessibilityHint = "tap to change"
                region.accessibilityTraits = .button
                region.isAccessibilityElement = true
                //let frame = CGRect(x: /* x position */, y: /* y position */, width: /* width */, height: /* height */)
                region.accessibilityFrameInContainerSpace = currRect
                _accessibilityElements.append(region)
            }
        }
    }
    
    override func accessibilityElement(at index: Int) -> Any? {
        return _accessibilityElements[index]
    }
    
    override func index(ofAccessibilityElement element: Any) -> Int {
        return _accessibilityElements.firstIndex(of: element as! UIAccessibilityElement) ?? NSNotFound
    }

    // MARK: -
    // MARK: draw view

    let TTBF = 0.1
    let TTSF = 0.2667

    func drawTicTac() {
        //var i: Int
        //DBGLog(String("\(frame)"))
        safeDispatchSync({ [self] in
            vborder = TTBF * frame.size.height
            hborder = TTBF * frame.size.width
        })
        vlen = bounds.size.height - (2 * vborder)
        hlen = bounds.size.width - (2 * hborder)
        vstep = bounds.size.height * TTSF
        hstep = bounds.size.width * TTSF

        if let context = self.context {
            
            context.setStrokeColor(UIColor.green.cgColor)
            MoveTo(context, hborder, vborder)
            AddLineTo(context, hborder + hlen, vborder)
            AddLineTo(context, hborder + hlen, vborder + vlen)
            AddLineTo(context, hborder, vborder + vlen)
            AddLineTo(context, hborder, vborder)
            context.strokePath()
            
            context.setStrokeColor(UIColor.label.cgColor)
            
            for i in 1...2 {
                // horiz lines
                MoveTo(context, hborder, vborder + (CGFloat(i) * vstep))
                AddLineTo(context, hborder + hlen, vborder + (CGFloat(i) * vstep))
            }
            
            for i in 1...2 {
                // vert lines
                MoveTo(context, hborder + (CGFloat(i) * hstep), vborder)
                AddLineTo(context, hborder + (CGFloat(i) * hstep), vborder + vlen)
            }
            context.strokePath()
        }
    }

    // MARK: bitfuncs to get selected bits from key

    func REGIONMASK(_ x: Int, _ y: Int) -> UInt {
        return ((UInt(0x03)) << (y << 1)) << (x * 2 * 3)
    }
    func REGIONINC(_ x: Int, _ y: Int) -> UInt {
        return ((UInt(0x01)) << (y << 1)) << (x * 2 * 3)
    }
    func REGIONVAL(_ v: UInt, _ x: Int, _ y: Int) -> UInt {
        return ((v & REGIONMASK(x, y)) >> (y << 1)) >> (x * 2 * 3)
    }

    // MARK: translate tic-tac-toe regions to view coords upper left corner

    func tt2vc() -> CGPoint {
        var ret = CGPoint(x: 0.0, y: 0.0)
        ret.x = hborder + (CGFloat(currX) * hstep)
        ret.y = vborder + (CGFloat(currY) * vstep)
        //ret.size.width = self.hstep;
        //ret.size.height = self.vstep;

        return ret
    }

    // MARK: draw current state

    func drawBlank() {
        //context?.setStrokeColor(UIColor.white.cgColor)
        context?.setFillColor(UIColor.secondarySystemBackground.cgColor)   // (UIColor.white.cgColor)
        context?.fill(currRect)
        //self.layer.cornerRadius = 8;


    }

    func sDraw(_ str: String?) {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18.0), // font size
            .foregroundColor: UIColor.label,  // UIColor.black, // font color
            .paragraphStyle: paragraphStyle
        ]

        context?.saveGState()
        
        // draw the text
        UIGraphicsPushContext(context!)
        str!.draw(in: currRect, withAttributes: attributes)
        UIGraphicsPopContext()

    }

    func setCurrPt(_ x: Int, y: Int) {
        var rect: CGRect = CGRect.zero
        currX = x
        currY = y
        rect.origin = tt2vc()
        rect.size.width = hstep
        rect.size.height = vstep
        currRect = rect
        //DBGLog(@"currPt: %d %d",x,y);
        let ndx = (x*3) + y
        if _accessibilityElements.indices.contains(ndx) {
            currRegion = _accessibilityElements[(x*3) + y]
        }
    }

    func setNoCurrPt() {
        //DBGLog(@"no curr pt");
        currX = -1
        currY = -1
    }

    func currPt() -> Bool {
        return currX > -1
    }

    func drawCell() {
        drawBlank()
        context!.setStrokeColor(UIColor.label.cgColor)
        switch REGIONVAL(key, currX, currY) {
        case 0x00:
            //DBGLog(@"00");
            currRegion?.accessibilityLabel = "blank \(labels[currX]) \(labels[currY])"
            break
        case 0x01:
            //DBGLog(@"01");
            currRegion?.accessibilityLabel = "X \(labels[currX]) \(labels[currY])"
            sDraw("X")
        case 0x02:
            //DBGLog(@"10");
            currRegion?.accessibilityLabel = "O \(labels[currX]) \(labels[currY])"
            sDraw("O")
        case 0x03:
            //DBGLog(@"11");
            currRegion?.accessibilityLabel = "+ \(labels[currX]) \(labels[currY])"
            sDraw("+")
        default:
            dbgNSAssert(false, "drawCell bad region val")
        }
    }

    func updateTT() {

        for i in 0..<3 {
            for j in 0..<3 {
                setCurrPt(i, y: j)
                drawCell()
            }
        }

        setNoCurrPt()
    }

    // MARK: handle region press

    @objc func press(_ x: Int, y: Int) {
        setCurrPt(x, y: y)
        DBGLog(String("press: \(x),\(y) => \(currRect.origin.x) \(currRect.origin.y) \(currRect.size.width) \(currRect.size.height)"))

        //unsigned int rmask = REGIONMASK(x,y);
        //unsigned int rinc =  REGIONINC(x,y);
        var newVal = key // copy current key
        var currBits = newVal & REGIONMASK(x, y) // select bits for this press
        currBits += REGIONINC(x, y) // inc state
        currBits &= REGIONMASK(x, y) // wipe overflow 0x3-> 0x4 0b0011 -> 0b0100
        newVal &= ~REGIONMASK(x, y) // clear bits in current key
        newVal |= currBits // set new bits

        key = newVal
        setNeedsDisplay(currRect)
        //[self setNeedsDisplay];
    }

    // MARK: translate view coords to tic-tac-toe regions

    func ttx(_ x: Int) -> Int {
        var i: Int = 1
        while i<3 {
            if CGFloat(x) < hborder + (CGFloat(i) * hstep) {
                return i - 1
            }
            i+=1
        }
        return i - 1
    }

    func tty(_ y: Int) -> Int {
        var i: Int = 1
        while i<3 {
            if CGFloat(y) < vborder + (CGFloat(i) * vstep) {
                return i - 1
            }
            i+=1
        }
        return i - 1
    }

    // MARK: api: draw current key

    func showKey(_ k: UInt) {
        key = k //rtm
        setNeedsDisplay()
    }

    // MARK: -
    // MARK: UIView drawing

    let FONTNAME = "Helvetica-Bold"
    let FONTSIZE = 20

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
     */
    override func draw(_ rect: CGRect) {
        // Drawing code
        context = UIGraphicsGetCurrentContext()
        context?.setLineWidth(1.0)
        context?.setAlpha(0.5)
        myFont = UIFont(name: String(FONTNAME), size: CGFloat(FONTSIZE))
        updateTT()
        drawTicTac()

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        let touchPoint = touch!.location(in: self)
        DBGLog(String("ttv: I am touched at \(touchPoint.x), \(touchPoint.y) => x:\(ttx(Int(touchPoint.x))) y:\(tty(Int(touchPoint.y)))"));
        press(ttx(Int(touchPoint.x)), y: tty(Int(touchPoint.y)))
        resignFirstResponder()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
