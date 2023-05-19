//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  privacy.swift
//  rTracker
//
//  Created by Robert Miller on 14/01/2011.
//  Copyright 2011 Robert T. Miller. All rights reserved.
//

import Foundation

// MARK: -
    // MARK: singleton privacyValue support
    var privacyValue = 0

class privacy: NSObject {
    private var _tictacView: UIView?
    var tictacView: UIView? {
        if _tictacView == nil {
            let vbounds = parentView?.frame

            let tictacRect = CGRect(x: 0.0, y: vbounds?.size.height ?? 0.0, width: vbounds?.size.width ?? 0.0, height: (vbounds?.size.height ?? 0.0) * TTVH)
            self.tictacView = UIView(frame: tictacRect)
            _tictacView?.backgroundColor = .white



            if let _tictacView {
                parentView?.addSubview(_tictacView)
            }
        }
        return _tictacView
    }
    var privacyVC: UIViewController?
    var parentView: UIView?
    var pSetterShown = false

    //+ (void)setPrivacyValue:(int)priv;
    class func getValue() -> Int {
        return privacyValue
    }

    func setPrivacyValue(_ priv: Int) {
        privacyValue = priv
    }

    // MARK: -
    // MARK: core object methods and support


    convenience init() {
        self.init(view: nil)
    }

    init(view pView: UIView?) {
        super.init()
        parentView = pView
        pSetterShown = false
    }

    func displaySetter() {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(TimeInterval(kAnimationDuration))
        tictacView?.transform = CGAffineTransform(translationX: 0, y: -((parentView?.frame.size.height ?? 0.0) * TTVH))
        UIView.commitAnimations()
        pSetterShown = true
    }

    func hideSetter() {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(TimeInterval(kAnimationDuration))
        tictacView?.transform = CGAffineTransform(translationX: 0, y: (parentView?.frame.size.height ?? 0.0) * TTVH)
        UIView.commitAnimations()
        pSetterShown = false
    }

    func toggleSetter() {
        if pSetterShown {
            hideSetter()
        } else {
            displaySetter()
        }
    }
}