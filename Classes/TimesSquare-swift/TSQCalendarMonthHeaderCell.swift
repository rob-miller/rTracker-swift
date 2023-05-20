//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  TSQCalendarMonthHeaderCell.swift
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

/// The `TSQCalendarMonthHeaderCell` class displays the month name and day names at the top of a month's worth of weeks.
/// By default, it lays out the day names in the bottom 20 points, the month name in the remainder of its height, and has a height of 65 points. You'll want to subclass it to change any of those things.
private let TSQCalendarMonthHeaderCellMonthsHeight: CGFloat = 20.0

class TSQCalendarMonthHeaderCell: TSQCalendarCell {
    /// Day Labels

    /// The day header labels.
    /// The count is equal to the `daysInWeek` property, likely seven. You can position them in the call to `layoutViewsForColumnAtIndex:inRect:`.
    var headerLabels: [AnyHashable]?

    private var _monthDateFormatter: DateFormatter?
    private var monthDateFormatter: DateFormatter? {
        if _monthDateFormatter == nil {
            _monthDateFormatter = DateFormatter()
            _monthDateFormatter?.calendar = calendar

            let dateComponents = "yyyyLLLL"
            _monthDateFormatter?.dateFormat = DateFormatter.dateFormat(fromTemplate: dateComponents, options: 0, locale: NSLocale.current)
        }
        return _monthDateFormatter
    }

    override init(calendar: Calendar?, reuseIdentifier: String?) {
        super.init(calendar: calendar, reuseIdentifier: reuseIdentifier)

        createHeaderLabels()
    }

    override class func cellHeight() -> CGFloat {
        return 65.0
    }

    /// Creates the header labels.
    /// If you want the text in your header labels to be something other than the short day format ("Mon Tue Wed" etc.), override this method, call `super`, and loop through `self.headerLabels`, changing their text.
    func createHeaderLabels() {
        var referenceDate = Date(timeIntervalSinceReferenceDate: 0)
        let offset = DateComponents()
        offset.day = 1
        var headerLabels = [AnyHashable](repeating: 0, count: daysInWeek)

        let dayFormatter = DateFormatter()
        dayFormatter.calendar = calendar
        dayFormatter.dateFormat = "cccccc"

        for index in 0..<daysInWeek {
            headerLabels.append("")
        }

        for index in 0..<daysInWeek {
            //NSInteger ordinality = [self.calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSWeekCalendarUnit forDate:referenceDate];
            let ordinality = calendar?.ordinality(of: .day, in: .weekOfMonth, for: referenceDate) ?? 0 // same result for NSCalendarUnitWeekOfYear
            let label = UILabel(frame: frame)
            label.textAlignment = .center // ios6  UITextAlignmentCenter;
            label.text = dayFormatter.string(from: referenceDate)
            label.font = .boldSystemFont(ofSize: 12.0)
            label.backgroundColor = backgroundColor
            label.textColor = textColor
            label.shadowColor = .white
            label.shadowOffset = shadowOffset
            label.sizeToFit()
            headerLabels[ordinality - 1] = label
            contentView.addSubview(label)

            if let aDate = calendar?.date(byAdding: offset, to: referenceDate, options: []) {
                referenceDate = aDate
            }
        }

        self.headerLabels = headerLabels
        textLabel?.textAlignment = .center // ios6  UITextAlignmentCenter;
        textLabel?.textColor = textColor
        textLabel?.shadowColor = .white
        textLabel?.shadowOffset = shadowOffset
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let bounds = contentView.bounds
        bounds.size.height -= TSQCalendarMonthHeaderCellMonthsHeight
        textLabel?.frame = bounds.offsetBy(dx: 0.0, dy: 5.0)
    }

    override func layoutViewsForColumn(at index: Int, in rect: CGRect) {
        let label = headerLabels?[index] as? UILabel
        let labelFrame = rect
        labelFrame.size.height = TSQCalendarMonthHeaderCellMonthsHeight
        labelFrame.origin.y = bounds.size.height - TSQCalendarMonthHeaderCellMonthsHeight
        label?.frame = labelFrame
    }

    override var firstOfMonth: Date? {
        get {
            super.firstOfMonth
        }
        set(firstOfMonth) {
            super.firstOfMonth = firstOfMonth
            if let firstOfMonth {
                textLabel?.text = monthDateFormatter?.string(from: firstOfMonth)
            }
            accessibilityLabel = textLabel?.text
        }
    }

    override var backgroundColor: UIColor? {
        get {
            super.backgroundColor
        }
        set(backgroundColor) {
            super.backgroundColor = backgroundColor
            for label in headerLabels ?? [] {
                guard let label = label as? UILabel else {
                    continue
                }
                label.backgroundColor = backgroundColor
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}