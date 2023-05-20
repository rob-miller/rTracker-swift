//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  TSQCalendarRowCell.swift
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

/// The `TSQCalendarRowCell` class is a cell that represents one week in the calendar.
/// Each of the seven columns can represent a day that's in this month, a day that's not in this month, a selected day, today, or an unselected day. The cell uses several images placed strategically to achieve the effect.

class TSQCalendarRowCell: TSQCalendarCell {
    /// Images

    /// The background image for the entire row.
    /// This image should be as wide as the entire view and include the grid lines between the columns. It will probably also include the grid line at the top of the row, but not the one at the bottom.
    /// You might, however, return a different image that includes both the grid line at the top and the one at the bottom if the `bottomRow` property is set to `YES`. You might even adjust the `cellHeight`.
    // when min is ios5 @property (nonatomic, weak, readonly) UIImage *backgroundImage;
    private(set) var backgroundImage: UIImage?
    /// The background image for a day that's selected.
    /// This is blue in the system's built-in Calendar app. You probably want to use a stretchable image.
    // when min is ios5 @property (nonatomic, weak, readonly) UIImage *selectedBackgroundImage;
    private(set) var selectedBackgroundImage: UIImage?
    /// The background image for a day that's "today".
    /// This is dark gray in the system's built-in Calendar app. You probably want to use a stretchable image.
    // when min is ios5 @property (nonatomic, weak, readonly) UIImage *todayBackgroundImage;
    private(set) var todayBackgroundImage: UIImage?
    /// The background image for a day that's not this month.
    /// These are the trailing days from the previous month or the leading days from the following month. This can be `nil`.
    // when min is ios5 @property (nonatomic, weak, readonly) UIImage *notThisMonthBackgroundImage;
    private(set) var notThisMonthBackgroundImage: UIImage?
    /// State Properties Set by Calendar View

    /// The date at the beginning of the week for this cell.
    /// Notice that it might be before the `firstOfMonth` property or it might be after.

    private var _beginningDate: Date?
    var beginningDate: Date? {
        get {
            _beginningDate
        }
        set(date) {
            _beginningDate = date

            if dayButtons == nil {
                createDayButtons()
                createNotThisMonthButtons()
                createTodayButton()
                createSelectedButton()
            }

            let offset = DateComponents()
            offset.day = 1

            todayButton?.isHidden = true
            indexOfTodayButton = -1
            selectedButton?.isHidden = true
            indexOfSelectedButton = -1

            for index in 0..<daysInWeek {
                var title: String? = nil
                if let date {
                    title = dayFormatter?.string(from: date)
                }
                var accessibilityLabel: String? = nil
                if let date {
                    accessibilityLabel = accessibilityFormatter?.string(from: date)
                }
                dayButtons?[index]?.setTitle(title, for: .normal)
                dayButtons?[index]?.accessibilityLabel = accessibilityLabel
                notThisMonthButtons?[index]?.setTitle(title, for: .normal)
                notThisMonthButtons?[index]?.setTitle(title, for: .disabled)
                notThisMonthButtons?[index]?.accessibilityLabel = accessibilityLabel

                //NSDateComponents *thisDateComponents = [self.calendar components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:date];
                var thisDateComponents: DateComponents? = nil
                if let date {
                    thisDateComponents = calendar?.components([.day, .month, .year], from: date)
                }

                dayButtons?[index]?.setHidden(true)
                notThisMonthButtons?[index]?.setHidden(true)

                let thisDayMonth = thisDateComponents?.month ?? 0
                if monthOfBeginningDate != thisDayMonth {
                    notThisMonthButtons?[index]?.setHidden(false)
                } else {

                    if todayDateComponents == thisDateComponents {
                        todayButton?.isHidden = false
                        todayButton?.setTitle(title, for: .normal)
                        todayButton?.accessibilityLabel = accessibilityLabel
                        indexOfTodayButton = index
                    } else {
                        let button = dayButtons?[index] as? UIButton
                        button?.isEnabled = !(calendarView?.delegate?.responds(to: #selector(TSQCalendarViewDelegate.calendarView(_:shouldSelect:))) ?? false) || calendarView?.delegate?.calendarView?(calendarView, shouldSelect: date) ?? false
                        if calendarView?.delegate?.responds(to: #selector(TSQCalendarViewDelegate.calendarView(_:colorFor:))) ?? false {
                            let c = calendarView?.delegate?.calendarView?(calendarView, colorFor: date)
                            if nil != c {
                                button?.setTitleColor(c, for: .normal)
                            }
                        }
                        button?.isHidden = false
                    }
                }

                if let date {
                    date = calendar?.date(byAdding: offset, to: date, options: [])
                }
            }
        }
    }
    /// Whether this cell is the bottom row / last week for the month.
    /// You may find yourself using a different background image or laying out differently in the last row.

    private var _bottomRow = false
    var bottomRow: Bool {
        get {
            _bottomRow
        }
        set(bottomRow) {
            let backgroundImageView = backgroundView as? UIImageView
            if (backgroundImageView is UIImageView) && _bottomRow == bottomRow {
                return
            }

            _bottomRow = bottomRow

            backgroundView = UIImageView(image: backgroundImage)

            setNeedsLayout()
        }
    }
    private var dayButtons: [AnyHashable]?
    private var notThisMonthButtons: [AnyHashable]?
    private var todayButton: UIButton?
    private var selectedButton: UIButton?
    private var indexOfTodayButton = 0
    private var indexOfSelectedButton = 0

    private var _dayFormatter: DateFormatter?
    private var dayFormatter: DateFormatter? {
        if _dayFormatter == nil {
            _dayFormatter = DateFormatter()
            _dayFormatter?.calendar = calendar
            _dayFormatter?.dateFormat = "d"
        }
        return _dayFormatter
    }

    private var _accessibilityFormatter: DateFormatter?
    private var accessibilityFormatter: DateFormatter? {
        if _accessibilityFormatter == nil {
            _accessibilityFormatter = DateFormatter()
            _accessibilityFormatter?.calendar = calendar
            _accessibilityFormatter?.dateStyle = .long
        }
        return _accessibilityFormatter
    }

    private var _todayDateComponents: DateComponents?
    private var todayDateComponents: DateComponents? {
        if _todayDateComponents == nil {
            self.todayDateComponents = calendar?.components([.day, .month, .year], from: Date())
        }
        return _todayDateComponents
    }

    private var _monthOfBeginningDate = 0
    private var monthOfBeginningDate: Int {
        if _monthOfBeginningDate == 0 {
            if let firstOfMonth {
                _monthOfBeginningDate = calendar?.components(.month, from: firstOfMonth).month ?? 0
            }
        }
        return _monthOfBeginningDate
    }

    override init(calendar: Calendar?, reuseIdentifier: String?) {
        super.init(calendar: calendar, reuseIdentifier: reuseIdentifier)
    }

    func configureButton(_ button: UIButton?) {
        button?.titleLabel?.font = .boldSystemFont(ofSize: 19.0)
        button?.titleLabel?.shadowOffset = shadowOffset
        button?.adjustsImageWhenDisabled = false
        button?.setTitleColor(textColor, for: .normal)
        button?.setTitleShadowColor(.white, for: .normal)
    }

    func createDayButtons() {
        var dayButtons = [AnyHashable](repeating: 0, count: daysInWeek)
        for index in 0..<daysInWeek {
            let button = UIButton(frame: contentView.bounds)
            button.addTarget(self, action: #selector(dateButtonPressed(_:)), for: .touchDown)
            dayButtons.append(button)
            contentView.addSubview(button)
            configureButton(button)
            button.setTitleColor(textColor?.withAlphaComponent(0.5), for: .disabled)
        }
        self.dayButtons = dayButtons
    }

    func createNotThisMonthButtons() {
        var notThisMonthButtons = [AnyHashable](repeating: 0, count: daysInWeek)
        for index in 0..<daysInWeek {
            let button = UIButton(frame: contentView.bounds)
            notThisMonthButtons.append(button)
            contentView.addSubview(button)
            configureButton(button)

            button.isEnabled = false
            let backgroundPattern = UIColor(patternImage: notThisMonthBackgroundImage)
            button.backgroundColor = backgroundPattern
            button.titleLabel?.backgroundColor = backgroundPattern
        }
        self.notThisMonthButtons = notThisMonthButtons
    }

    func createTodayButton() {
        todayButton = UIButton(frame: contentView.bounds)
        if let todayButton {
            contentView.addSubview(todayButton)
        }
        configureButton(todayButton)
        todayButton?.addTarget(self, action: #selector(todayButtonPressed(_:)), for: .touchDown)

        todayButton?.setTitleColor(.white, for: .normal)
        todayButton?.setBackgroundImage(todayBackgroundImage, for: .normal)
        todayButton?.setTitleShadowColor(UIColor(white: 0.0, alpha: 0.75), for: .normal)

        todayButton?.titleLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0 / UIScreen.main.scale)
    }

    func createSelectedButton() {
        selectedButton = UIButton(frame: contentView.bounds)
        if let selectedButton {
            contentView.addSubview(selectedButton)
        }
        configureButton(selectedButton)

        selectedButton?.accessibilityTraits = UIAccessibilityTraits.selected.rawValue | selectedButton?.accessibilityTraits.rawValue

        selectedButton?.isEnabled = false
        selectedButton?.setTitleColor(.white, for: .normal)
        selectedButton?.setBackgroundImage(selectedBackgroundImage, for: .normal)
        selectedButton?.setTitleShadowColor(UIColor(white: 0.0, alpha: 0.75), for: .normal)

        selectedButton?.titleLabel?.shadowOffset = CGSize(width: 0.0, height: -1.0 / UIScreen.main.scale)
        indexOfSelectedButton = -1
    }

    @IBAction func dateButtonPressed(_ sender: Any) {
        let offset = DateComponents()
        if let sender = sender as? AnyHashable {
            offset.day = dayButtons?.firstIndex(of: sender) ?? NSNotFound
        }
        var selectedDate: Date? = nil
        if let beginningDate {
            selectedDate = calendar?.date(byAdding: offset, to: beginningDate, options: [])
        }
        calendarView?.selectedDate = selectedDate
    }

    @IBAction func todayButtonPressed(_ sender: Any) {
        let offset = DateComponents()
        offset.day = indexOfTodayButton
        var selectedDate: Date? = nil
        if let beginningDate {
            selectedDate = calendar?.date(byAdding: offset, to: beginningDate, options: [])
        }
        calendarView?.selectedDate = selectedDate
    }

    override func layoutSubviews() {
        if backgroundView == nil {
            bottomRow = false
        }

        super.layoutSubviews()

        backgroundView?.frame = bounds
    }

    override func layoutViewsForColumn(at index: Int, in rect: CGRect) {
        let dayButton = dayButtons?[index] as? UIButton
        let notThisMonthButton = notThisMonthButtons?[index] as? UIButton

        dayButton?.frame = rect
        notThisMonthButton?.frame = rect

        if indexOfTodayButton == index {
            todayButton?.frame = rect
        }
        if indexOfSelectedButton == index {
            selectedButton?.frame = rect
        }
    }

    /// Method to select a specific date within the week.
    /// This is funneled through and called by the calendar view, to facilitate deselection of other rows.
    /// - Parameter date: The date to select, or nil to deselect all columns.
    func selectColumn(for date: Date?) {
        if date == nil && indexOfSelectedButton == -1 {
            return
        }

        var newIndexOfSelectedButton = -1
        if let date {
            let thisDayMonth = calendar?.components(.month, from: date).month ?? 0
            if monthOfBeginningDate == thisDayMonth {
                if let beginningDate {
                    newIndexOfSelectedButton = calendar?.components(.day, from: beginningDate, to: date, options: []).day ?? 0
                }
                if newIndexOfSelectedButton >= daysInWeek {
                    newIndexOfSelectedButton = -1
                }
            }
        }

        indexOfSelectedButton = newIndexOfSelectedButton

        if newIndexOfSelectedButton >= 0 {
            selectedButton?.isHidden = false
            let newTitle = dayButtons?[newIndexOfSelectedButton]?.currentTitle
            selectedButton?.setTitle(newTitle, for: .normal)
            selectedButton?.setTitle(newTitle, for: .disabled)
            selectedButton?.accessibilityLabel = dayButtons?[newIndexOfSelectedButton]?.accessibilityLabel
        } else {
            selectedButton?.isHidden = true
        }

        setNeedsLayout()
    }

    override var firstOfMonth: Date? {
        get {
            super.firstOfMonth
        }
        set(firstOfMonth) {
            super.firstOfMonth = firstOfMonth
            monthOfBeginningDate = 0
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}