//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  trackerCalCalendarRowCell.swift
//  TimesSquare
//
//  Created by Jim Puls on 12/5/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

import CoreGraphics
import UIKit

@objc(trackerCalCalendarRowCell)
class trackerCalCalendarRowCell: TSQCalendarRowCell {
    override func layoutViewsForColumn(at index: UInt, in rect: CGRect) {
        // Move down for the row at the top
        var lrect = rect
        lrect.origin.y += columnSpacing
        lrect.size.height -= (isBottomRow ? 2.0 : 1.0) * columnSpacing
        super.layoutViewsForColumn(at: index, in: lrect)
    }

    @objc override var todayBackgroundImage: UIImage? {
        get {
            return UIImage(named: "CalendarTodaysDate.png")?.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
        }
        set {
            super.todayBackgroundImage = newValue
        }
    }

    @objc override var selectedBackgroundImage: UIImage? {
        get {
            return UIImage(named: "CalendarSelectedDate.png")!.stretchableImage(withLeftCapWidth: 4, topCapHeight: 4)
        }
        set {
            super.selectedBackgroundImage = newValue
        }
    }

    @objc override var notThisMonthBackgroundImage: UIImage? {
        get {
            return UIImage(named: "CalendarPreviousMonth.png")!.stretchableImage(withLeftCapWidth: 0, topCapHeight: 0)
        }
        set {
            super.notThisMonthBackgroundImage = newValue
        }
    }

    @objc override var backgroundImage: UIImage? {
        get {
            return UIImage(named: "CalendarRow\(isBottomRow ? "Bottom" : "").png")!
        }
        set {
            super.backgroundImage = newValue
        }
    }
}
