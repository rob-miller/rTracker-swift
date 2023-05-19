//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  TSQCalendarCell.swift
//  TimesSquare
//
//  Created by Jim Puls on 11/15/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

import UIKit

/// The `TSQCalendarCell` class is an abstract superclass to the two cell types used for display in a `TSQCalendarView`.
/// Most of its interface deals with display properties. The most interesting method is `-layoutViewsForColumnAtIndex:inRect:`, which is a simple way of handling seven columns.
class TSQCalendarCell: UITableViewCell {
    /// State Properties Set by Calendar View

    /// The first day of the month this cell is currently representing.
    /// This can be useful for calculations and for display.
    var firstOfMonth: Date?
    /// How many days there are in a week.
    /// This is usually 7.

    var daysInWeek: Int {
        if _TSQCalendarCell.daysInWeekVar == 0 {
            _TSQCalendarCell.daysInWeekVar = calendar?.maximumRange(of: .weekday).length ?? 0
        }
        return _TSQCalendarCell.daysInWeekVar
    }
    /// The calendar type we're displaying.
    /// This is whatever the owning `TSQCalendarView`'s `calendar` property is set to; it's likely `[NSCalendar currentCalendar]`.
    var calendar: Calendar?
    /// The owning calendar view.
    /// This is a weak reference.
    // when min is ios5 @property (nonatomic, weak) TSQCalendarView *calendarView;
    var calendarView: TSQCalendarView?
    /// The text color.
    /// This is used for all text the cell draws; if a date is disabled, then it will draw in this color, but at 50% opacity.
    var textColor: UIColor?
    /// The text shadow offset.
    /// This is as you would set on `UILabel`.
    var shadowOffset = CGSize.zero
    /// The spacing between columns.
    /// This defaults to one pixel or `1.0 / [UIScreen mainScreen].scale`.
    var columnSpacing: CGFloat = 0.0
    private var layoutDirection: (NSLocale.LanguageDirection)!

    /// Initialization

    /// Initializes the cell.
    /// - Parameters:
    ///   - calendar: The `NSCalendar` the cell is representing
    ///   - reuseIdentifier: A string reuse identifier, as used by `UITableViewCell`
    static let initShadowOffset = {
        var shadowOffset = CGSize(width: 0.0, height: onePixel)
        return shadowOffset
    }()

    convenience init(calendar: Calendar?, reuseIdentifier: String?) {
        self.init(style: .default, reuseIdentifier: reuseIdentifier)

        self.calendar = calendar
        let languageCode = NSLocale.current[NSLocale.Key.languageCode] as? String
        layoutDirection = NSLocale.characterDirection(forLanguage: languageCode ?? "")
        backgroundColor = UIColor(red: 0.84, green: 0.85, blue: 0.86, alpha: 1.0)

        let onePixel = 1.0 / UIScreen.main.scale
        // `dispatch_once()` call was converted to a static variable initializer
        tsqCalendarCell.initShadowOffset = TSQCalendarCell.initShadowOffset
        columnSpacing = onePixel
        textColor = UIColor(red: 0.47, green: 0.5, blue: 0.53, alpha: 1.0)
    }

    /// Display Properties

    /// The preferred height for instances of this cell.
    /// The built-in implementation in `TSQCalendarCell` returns `46.0f`. Your subclass may want to return another value.
    class func cellHeight() -> CGFloat {
        return 46.0
    }

    override var selectionStyle: UITableViewCell.SelectionStyle {
        get {
            return .none
        }
        set {
            super.selectionStyle = newValue
        }
    }

    override func setHighlighted(_ selected: Bool, animated: Bool) {
        // do nothing
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // do nothing
    }

    /// Seven-column layout helper.
    /// - Parameters:
    ///   - index: The index of the column we're laying out, probably in the range [0..6]
    ///   - rect: The rect relative to the bounds of the cell's content view that represents the column.
    /// Feel free to adjust the rect before moving views and to vertically position them within the column. (In fact, you could ignore the rect entirely; it's just there to help.)
    func layoutViewsForColumn(at index: Int, in rect: CGRect) {
        // for subclass to implement
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let insets = calendarView?.contentInset


        var insetRect: CGRect? = nil
        if let insets {
            insetRect = bounds.inset(by: insets)
        }
        insetRect?.origin.y = bounds.minY
        insetRect?.size.height = bounds.height
        var increment = ((insetRect?.width ?? 0.0) - CGFloat((daysInWeek - 1)) * columnSpacing) / CGFloat(daysInWeek)
        increment = CGFloat(roundf(Float(increment)))
        var start = insets?.left

        let extraSpace = ((insetRect?.width ?? 0.0) - CGFloat((daysInWeek - 1)) * columnSpacing) - (increment * CGFloat(daysInWeek))

        // Divide the extra space out over the outer columns in increments of the column spacing
        let columnsWithExtraSpace = Int(abs(Float(extraSpace / columnSpacing)))
        let columnsOnLeftWithExtraSpace = columnsWithExtraSpace / 2
        let columnsOnRightWithExtraSpace = columnsWithExtraSpace - columnsOnLeftWithExtraSpace

        for index in 0..<daysInWeek {
            var width = increment
            if index < columnsOnLeftWithExtraSpace || index >= daysInWeek - columnsOnRightWithExtraSpace {
                width += extraSpace / CGFloat(columnsWithExtraSpace)
            }

            var displayIndex = index
            if layoutDirection == NSLocale.LanguageDirection.rightToLeft {
                displayIndex = daysInWeek - index - 1
            }

            let columnBounds = bounds
            columnBounds.origin.x = Double(start)
            columnBounds.size.width = width
            layoutViewsForColumn(at: displayIndex, in: columnBounds)
            start += width + columnSpacing
        }

    }
}