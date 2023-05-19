//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  TSQCalendarState.h
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

//
//  TSQCalendarState.m
//  TimesSquare
//
//  Created by Jim Puls on 11/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

import 
import UIKit

/// The `TSQCalendarView` class displays a monthly calendar in a self-contained scrolling view. It supports any calendar that `NSCalendar` supports.
/// The implementation and usage are very similar to `UITableView`: the app provides reusable cells via a data source and controls behavior via a delegate. See `TSQCalendarCell` for a cell superclass.
class TSQCalendarView: UIView, UITableViewDataSource, UITableViewDelegate {
    /// Date Setup

    /// The earliest month the calendar view displays.
    /// Set this property to any `NSDate`; `TSQCalendarView` will only look at the month and year.
    /// Must be set for the calendar to be useful.

    private var _firstDate: Date?
    var firstDate: Date? {
        get {
            _firstDate
        }
        set(firstDate) {
            // clamp to the beginning of its month
            _firstDate = clampDate(firstDate, toComponents: [.month, .year].rawValue)
        }
    }
    /// The latest month the calendar view displays.
    /// Set this property to any `NSDate`; `TSQCalendarView` will only look at the month and year.
    /// Must be set for the calendar to be useful.

    private var _lastDate: Date?
    var lastDate: Date? {
        get {
            _lastDate
        }
        set(lastDate) {
            // clamp to the end of its month
            let firstOfMonth = clampDate(lastDate, toComponents: [.month, .year].rawValue)

            let offsetComponents = DateComponents()
            offsetComponents.month = 1
            offsetComponents.day = -1
            if let firstOfMonth {
                _lastDate = calendar?.date(byAdding: offsetComponents, to: firstOfMonth, options: [])
            }
        }
    }
    /// The currently-selected date on the calendar.
    /// Set this property to any `NSDate`; `TSQCalendarView` will only look at the month, day, and year.
    /// You can read and write this property; the delegate method `calendarView:didSelectDate:` will be called both when a new date is selected from the UI and when this method is called manually.

    private var _selectedDate: Date?
    var selectedDate: Date? {
        get {
            _selectedDate
        }
        set(newSelectedDate) {
            DBGLog("-> %@", newSelectedDate)
            // clamp to beginning of its day
            let startOfDay = clampDate(newSelectedDate, toComponents: [.day, .month, .year].rawValue)

            if delegate?.responds(to: #selector(TSQCalendarViewDelegate.calendarView(_:shouldSelect:))) ?? false && !(delegate?.calendarView?(self, shouldSelect: startOfDay) ?? false) {
                return
            }

            cellForRow(at: _selectedDate)?.selectColumn(for: nil)
            cellForRow(at: startOfDay)?.selectColumn(for: startOfDay)
            let newIndexPath = indexPathForRow(at: startOfDay)
            var newIndexPathRect: CGRect? = nil
            if let newIndexPath {
                newIndexPathRect = tableView?.rectForRow(at: newIndexPath)
            }
            let scrollBounds = tableView?.bounds

            if pagingEnabled {
                let sectionRect = tableView?.rect(forSection: newIndexPath?.section ?? 0)
                tableView?.setContentOffset(sectionRect?.origin ?? CGPoint.zero, animated: true)
            } else {
                if (scrollBounds?.minY ?? 0.0) > (newIndexPathRect?.minY ?? 0.0) {
                    if let newIndexPath {
                        tableView?.scrollToRow(at: newIndexPath, at: .top, animated: true)
                    }
                } else if (scrollBounds?.maxY ?? 0.0) < (newIndexPathRect?.maxY ?? 0.0) {
                    if let newIndexPath {
                        tableView?.scrollToRow(at: newIndexPath, at: .bottom, animated: true)
                    }
                }
            }

            _selectedDate = startOfDay

            if delegate?.responds(to: #selector(TSQCalendarViewDelegate.calendarView(_:didSelect:))) ?? false {
                delegate?.calendarView?(self, didSelect: startOfDay)
            }
        }
    }
    /// Calendar Configuration

    /// The calendar type to use when displaying.
    /// If not set, this defaults to `[NSCalendar currentCalendar]`.

    private var _calendar: Calendar?
    var calendar: Calendar? {
        if _calendar == nil {
            self.calendar = .current
        }
        return _calendar
    }
    /// Visual Configuration

    /// The delegate of the calendar view.
    /// The delegate must adopt the `TSQCalendarViewDelegate` protocol.
    /// The `TSQCalendarView` class, which does not retain the delegate, invokes each protocol method the delegate implements.
    // when rTracker min supported is ios5 can use weak : @property (nonatomic, weak) id<TSQCalendarViewDelegate> delegate;
    var delegate: TSQCalendarViewDelegate?
    /// Whether to pin the header to the top of the view.
    /// If you're trying to emulate the built-in calendar app, set this to `YES`. Default value is `NO`.

    private var _pinsHeaderToTop = false
    var pinsHeaderToTop: Bool {
        get {
            _pinsHeaderToTop
        }
        set(pinsHeaderToTop) {
            _pinsHeaderToTop = pinsHeaderToTop
            setNeedsLayout()
        }
    }
    /// Whether or not the calendar snaps to begin a month at the top of its bounds.
    /// This property is roughly equivalent to the one defined on `UIScrollView` except the snapping is to months rather than integer multiples of the view's bounds.
    var pagingEnabled = false
    /// The distance from the edges of the view to where the content begins.
    /// This property is equivalent to the one defined on `UIScrollView`.
    var contentInset: UIEdgeInsets!
    /// The point on the calendar where the currently-visible region starts.
    /// This property is equivalent to the one defined on `UIScrollView`.
    var contentOffset = CGPoint.zero
    /// The cell class to use for month headers.
    /// Since there's very little configuration to be done for each cell, this can be set as a shortcut to implementing a data source.
    /// The class should be a subclass of `TSQCalendarMonthHeaderCell` or at least implement all of its methods.

    private var _headerCellClass: AnyClass?
    var headerCellClass: AnyClass? {
        if _headerCellClass == nil {
            self.headerCellClass = TSQCalendarMonthHeaderCell.self
        }
        return _headerCellClass
    }
    /// The cell class to use for week rows.
    /// Since there's very little configuration to be done for each cell, this can be set as a shortcut to implementing a data source.
    /// The class should be a subclass of `TSQCalendarRowCell` or at least implement all of its methods.

    private var _rowCellClass: AnyClass?
    var rowCellClass: AnyClass? {
        if _rowCellClass == nil {
            self.rowCellClass = TSQCalendarRowCell.self
        }
        return _rowCellClass
    }
    private var tableView: UITableView?
    private var headerView: TSQCalendarMonthHeaderCell? // nil unless pinsHeaderToTop == YES

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        _TSQCalendarView_commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        _TSQCalendarView_commonInit()
    }

    func _TSQCalendarView_commonInit() {
        tableView = UITableView(frame: bounds, style: .plain)
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.separatorStyle = .none
        tableView?.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        if let tableView {
            addSubview(tableView)
        }
    }

    deinit {
        tableView?.dataSource = nil
        tableView?.delegate = nil

    }

    func cellClassForRow(at indexPath: IndexPath?) -> AnyClass {
        if indexPath?.row == 0 && !pinsHeaderToTop {
            return headerCellClass
        } else {
            return rowCellClass
        }
    }

    override var backgroundColor: UIColor? {
        get {
            super.backgroundColor
        }
        set(backgroundColor) {
            super.backgroundColor = backgroundColor
            tableView?.backgroundColor = backgroundColor
        }
    }

    /// Scrolls the receiver until the specified date month is completely visible.
    /// - Parameters:
    ///   - date: A date that identifies the month that will be visible.
    ///   - animated: YES if you want to animate the change in position, NO if it should be immediate.
    func scroll(to date: Date?, animated: Bool) {
        let section = self.section(for: date)
        tableView?.scrollToRow(at: IndexPath(row: 0, section: section), at: .top, animated: animated)
    }

    func makeHeaderCell(withIdentifier identifier: String?) -> TSQCalendarMonthHeaderCell? {
        let cell = headerCellClass?.init(calendar: calendar, reuseIdentifier: identifier) as? TSQCalendarMonthHeaderCell
        cell?.backgroundColor = backgroundColor
        cell?.calendarView = self
        return cell
    }

    // MARK: Calendar calculations

    func firstOfMonth(forSection section: Int) -> Date? {
        let offset = DateComponents()
        offset.month = section
        /*
            DBGLog(@"cal %@",self.calendar);
            DBGLog(@"offset %@",offset);
            DBGLog(@"firstDate %@",self.firstDate);
            */

        if let firstDate {
            return calendar?.date(byAdding: offset, to: firstDate, options: [])
        }
        return nil
    }

    func cellForRow(at date: Date?) -> TSQCalendarRowCell? {
        if let indexPath = indexPathForRow(at: date) {
            return tableView?.cellForRow(at: indexPath) as? TSQCalendarRowCell
        }
        return nil
    }

    func section(for date: Date?) -> Int {
        if let firstDate, let date {
            return calendar?.components(.month, from: firstDate, to: date, options: []).month ?? 0
        }
        return 0
    }

    func indexPathForRow(at date: Date?) -> IndexPath? {
        if date == nil {
            return nil
        }

        let section = self.section(for: date)
        let firstOfMonth = self.firstOfMonth(forSection: section)

        var firstWeek: Int? = nil
        if let firstOfMonth {
            firstWeek = calendar?.components(.weekOfMonth, from: firstOfMonth).weekOfMonth ?? 0
        }
        var targetWeek: Int? = nil
        if let date {
            targetWeek = calendar?.components(.weekOfMonth, from: date).weekOfMonth ?? 0
        }

        return IndexPath(row: (pinsHeaderToTop ? 0 : 1) + (targetWeek ?? 0) - (firstWeek ?? 0), section: section)
    }

    // MARK: UIView

    override func layoutSubviews() {
        if pinsHeaderToTop {
            if headerView == nil {
                headerView = makeHeaderCell(withIdentifier: nil)
                if (tableView?.visibleCells.count ?? 0) > 0 {
                    headerView?.firstOfMonth = tableView?.visibleCells[0]?.firstOfMonth()
                } else {
                    headerView?.firstOfMonth = firstDate
                }
                if let headerView {
                    addSubview(headerView)
                }
            }
            let bounds = self.bounds
            var headerRect: CGRect
            var tableRect: CGRect
            bounds.divided(atDistance: headerCellClass?.cellHeight() ?? 0.0, from: .minYEdge)
            headerView?.frame = headerRect
            tableView?.frame = tableRect
        } else {
            if headerView != nil {
                headerView?.removeFromSuperview()
                headerView = nil
            }
            tableView?.frame = self.bounds
        }
    }

    // MARK: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        if let firstDate, let lastDate {
            return 1 + (calendar?.components(.month, from: firstDate, to: lastDate, options: []).month ?? 0)
        }
        return 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let firstOfMonth = self.firstOfMonth(forSection: section)
        //NSRange rangeOfWeeks = [self.calendar rangeOfUnit:NSWeekCalendarUnit inUnit:NSCalendarUnitMonth forDate:firstOfMonth];
        var rangeOfWeeks: NSRange? = nil
        if let firstOfMonth {
            rangeOfWeeks = calendar?.range(of: .weekOfYear, in: .month, for: firstOfMonth)
        } // NSCalendarUnitWeekOfMonth does not work
        return (pinsHeaderToTop ? 0 : 1) + (rangeOfWeeks?.length ?? 0)
    }

    // month header
    static let tableViewIdentifier = "header"

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 && !pinsHeaderToTop {
            var cell = tableView.dequeueReusableCell(withIdentifier: TSQCalendarView.tableViewIdentifier) as? TSQCalendarMonthHeaderCell
            if cell == nil {
                cell = makeHeaderCell(withIdentifier: TSQCalendarView.tableViewIdentifier)
            }
            return cell!
        } else {
            var cell = tableView.dequeueReusableCell(withIdentifier: TSQCalendarView.tableViewIdentifier) as? TSQCalendarRowCell
            if cell == nil {
                cell = rowCellClass?.init(calendar: calendar, reuseIdentifier: TSQCalendarView.tableViewIdentifier) as? TSQCalendarRowCell
                cell?.backgroundColor = backgroundColor
                cell?.calendarView = self
            }
            return cell!
        }
    }

    // MARK: UITableViewDelegate

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let firstOfMonth = self.firstOfMonth(forSection: indexPath.section)
        (cell as? TSQCalendarCell)?.firstOfMonth = firstOfMonth
        if indexPath.row > 0 || pinsHeaderToTop {
            //NSInteger ordinalityOfFirstDay = [self.calendar ordinalityOfUnit:NSCalendarUnitDay inUnit:NSWeekCalendarUnit forDate:firstOfMonth];
            var ordinalityOfFirstDay: Int? = nil
            if let firstOfMonth {
                ordinalityOfFirstDay = calendar?.ordinality(of: .day, in: .weekOfMonth, for: firstOfMonth) ?? 0
            } // same result NSCalendarUnitWeekOfYear
            let dateComponents = DateComponents()
            dateComponents.day = 1 - (ordinalityOfFirstDay ?? 0)
            dateComponents.weekOfYear = indexPath.row - (pinsHeaderToTop ? 0 : 1)
            if let firstOfMonth {
                (cell as? TSQCalendarRowCell)?.beginningDate = calendar?.date(byAdding: dateComponents, to: firstOfMonth, options: [])
            }
            (cell as? TSQCalendarRowCell)?.selectColumn(for: selectedDate)

            let isBottomRow = indexPath.row == self.tableView(tableView, numberOfRowsInSection: indexPath.section) - (pinsHeaderToTop ? 0 : 1)
            (cell as? TSQCalendarRowCell)?.bottomRow = isBottomRow
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellClassForRow(at: indexPath).cellHeight()
    }

    // MARK: UIScrollViewDelegate

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if pagingEnabled {
            let indexPath = tableView?.indexPathForRow(at: targetContentOffset)
            // If the target offset is at the third row or later, target the next month; otherwise, target the beginning of this month.
            let section = indexPath?.section ?? 0
            if (indexPath?.row ?? 0) > 2 {
                section += 1
            }
            let sectionRect = tableView?.rect(forSection: section)
            targetContentOffset = sectionRect?.origin ?? CGPoint.zero
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if pinsHeaderToTop && (tableView?.visibleCells.count ?? 0) > 0 {
            let cell = tableView?.visibleCells[0] as? TSQCalendarCell
            headerView?.firstOfMonth = cell?.firstOfMonth
        }
    }

    func clampDate(_ date: Date?, toComponents unitFlags: Int) -> Date? {
        var components: DateComponents? = nil
        if let date {
            components = calendar?.components(NSCalendar.Unit(rawValue: unitFlags), from: date)
        }
        if let components {
            return calendar?.date(from: components)
        }
        return nil
    }
}

/// The methods in the `TSQCalendarViewDelegate` protocol allow the adopting delegate to either prevent a day from being selected or respond to it.
@objc protocol TSQCalendarViewDelegate: NSObjectProtocol {
    /// Responding to Selection

    /// Asks the delegate whether a particular date is selectable.
    /// This method should be relatively efficient, as it is called repeatedly to appropriate enable and disable individual days on the calendar view.
    /// - Parameters:
    ///   - calendarView: The calendar view that is selecting a date.
    ///   - date: Midnight on the date being selected.
    /// - Returns: Whether or not the date is selectable.
    @objc optional func calendarView(_ calendarView: TSQCalendarView?, shouldSelect date: Date?) -> Bool
    /// Tells the delegate that a particular date was selected.
    /// - Parameters:
    ///   - calendarView: The calendar view that is selecting a date.
    ///   - date: Midnight on the date being selected.
    @objc optional func calendarView(_ calendarView: TSQCalendarView?, didSelect date: Date?)
    /// Asks the delegate for a textColor for a particular date.
    /// This method should be relatively efficient, as it is called repeatedly to color individual day labels on the calendar view.
    /// - Parameters:
    ///   - calendarView: The calendar view that is selecting a date.
    ///   - date: Midnight on the date being selected.
    /// - Returns: UIColor for the date.
    @objc optional func calendarView(_ calendarView: TSQCalendarView?, colorFor date: Date?) -> UIColor?
}