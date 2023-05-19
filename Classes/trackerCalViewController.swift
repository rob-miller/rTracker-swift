//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  trackerCalViewController.swift
//  TimesSquare
//
//  Created by Jim Puls on 12/5/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

import TimesSquare
import UIKit

class trackerCalViewController: UIViewController, TSQCalendarViewDelegate {
    /*
     {
        trackerObj *tracker;
        dpRslt *dpr;
    }
    */
    var tracker: trackerObj?
    var dpr: dpRslt?

    private var _calendar: Calendar?
    var calendar: Calendar? {
        get {
            _calendar
        }
        set(calendar) {
            _calendar = calendar

            navigationItem.title = calendar?.calendarIdentifier
            tabBarItem.title = calendar?.calendarIdentifier
        }
    }
    var dateSelDict: [AnyHashable : Any]?
    var specDate = false
    var parentUTC: Any?
    private var timer: Timer?

    override func loadView() {

        let calendarView = TSQCalendarView()
        calendarView.calendar = Calendar.current
        calendar = calendarView.calendar
        dateSelDict = [:]

        var idColors: [AnyHashable : Any] = [:]
        var sql = "select id,color from voConfig where id not in  (select id from voInfo where field='graph' and val=0)"
        tracker?.toQry2DictII(&idColors, sql: sql)

        var fnIds: Set<AnyHashable> = []
        sql = "select id from voConfig where type=6" // VOT_FUNC hard-coded!
        tracker?.toQry2SetI(&fnIds, sql: sql)

        var noGraphIds: Set<AnyHashable> = []
        sql = "select id from voInfo where field='graph' and val=0"
        tracker?.toQry2SetI(&noGraphIds, sql: sql)

        let colorSet = rTracker_resource.colorSet()
        let pv = privacyV.getPrivacyValue()
        var dates: [AnyHashable]?
        if nil == (parentUTC as? useTrackerController)?.searchSet {
            dates = []
            sql = "select date from trkrData where minpriv <= \(pv) order by date asc;"
            tracker?.toQry2AryI(&dates, sql: sql)
        } else {
            if let aSearchSet = (parentUTC as? useTrackerController)?.searchSet {
                dates = aSearchSet
            }
        }

        var vidSet: [AnyHashable] = []

        for d in dates ?? [] {
            let dc = calendar?.components([.year, .month, .day], from: Date(timeIntervalSince1970: TimeInterval((d as? NSNumber).intValue)))
            var date: Date? = nil
            if let dc {
                date = calendar?.date(from: dc)
            }
            let dayStart = Int(date?.timeIntervalSince1970 ?? 0)

            DBGLog("date= %@", date)
            if (2014 == dc?.year) && (6 == dc?.month) && (13 == dc?.day) {
                DBGLog("date 2014 june = %@", date)
            }
            // get array of vids in date range
            sql = "select t1.id from voData t0, voConfig t1 where t0.id=t1.id and t0.date >= \(dayStart) and t0.date <= \(dayStart + (24 * 60 * 60) - 1) and t1.priv <= \(pv) and t1.type != \(VOT_INFO) order by t1.rank asc"

            vidSet.removeAll()
            tracker?.toQry2AryI(&vidSet, sql: sql)
            var haveNoGraphNoFn = false
            var graphFnVid = 0
            var targVid = 0

            for vid in vidSet {
                if let vid = vid as? AnyHashable {
                    if noGraphIds.contains(vid) {
                        // not graphed
                        if !fnIds.contains(vid) {
                            // and not a vot_func
                            if 0 != graphFnVid {
                                // have a graphed fn value already set, this confirms there is privacy-ok data
                                targVid = graphFnVid
                                break
                            }
                            haveNoGraphNoFn = true
                        }
                    } else if fnIds.contains(vid) {
                        if 0 == graphFnVid {
                            // first seen vot_func to graph
                            graphFnVid = (vid as? NSNumber).intValue
                            if haveNoGraphNoFn {
                                // already have confirmation of privacy-ok data
                                targVid = graphFnVid
                                break
                            }
                        }
                    } else if 0 != graphFnVid {
                        // have a graphed fn value already set, this confirms there is privacy-ok data
                        targVid = graphFnVid
                        break
                    } else {
                        targVid = (vid as? NSNumber).intValue
                        break
                    }
                }
            }

            if haveNoGraphNoFn && (0 == targVid) {
                // only have no graph data point
                dateSelDict?[date] = "" // set for no color
                DBGLog("date: %@ - have vid but no graph", date)
            } else if targVid != 0 {
                let cndx = (idColors[NSNumber(value: targVid)] as? NSNumber)?.intValue ?? 0
                if (cndx < 0) || (cndx > (colorSet?.count ?? 0)) {
                    dateSelDict?[date] = "" // set for no color
                } else {
                    dateSelDict?[date] = colorSet?[cndx] as? UIColor
                    DBGLog("date: %@  valobj %d UIColor %@ name %@", date, targVid, colorSet?[cndx] as? UIColor, rTracker_resource.colorNames()?[cndx])
                }
            }


            if let date {
                DBGLog("data for date %@ = %@", date, dateSelDict?[date] as? UIColor)
            }
        }

        calendarView.rowCellClass = trackerCalCalendarRowCell.self
        calendarView.firstDate = Date(timeIntervalSince1970: TimeInterval(tracker?.firstDate() ?? 0.0))
        calendarView.lastDate = Date() // today

        calendarView.backgroundColor = UIColor(red: 0.84, green: 0.85, blue: 0.86, alpha: 1.0)
        calendarView.pagingEnabled = false
        let onePixel = 1.0 / UIScreen.main.scale
        calendarView.contentInset = UIEdgeInsets(top: 0.0, left: onePixel, bottom: 0.0, right: onePixel)
        calendarView.contentOffset = CGPoint(x: 60.0, y: 60.0)
        calendarView.delegate = self
        calendarView.scroll(to: dpr?.date, animated: false)
        view = calendarView

        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(addTrackerController.handleViewSwipeRight(_:)))
        swipe.direction = .right
        view.addGestureRecognizer(swipe)




    }

    func leaveCalendar() {
        dpr?.date = nil
        dpr?.action = DPA_CANCEL
        //[self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)
    }

    @objc func handleViewSwipeRight(_ gesture: UISwipeGestureRecognizer?) {
        leaveCalendar()
    }

    /*
    - (void) viewDidLoad {
        if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
            self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    */

    override func viewWillAppear(_ animated: Bool) {
        /*  // must have view loaded for this or iOS complains
            self.SpecDate=true;
            DBGLog(@"showing tsqcal seldate= %@",self.dpr.date);
            ((TSQCalendarView*)self.view).selectedDate = self.dpr.date;
            self.SpecDate=false;
             */
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        // Set the calendar view to show today date on start
        //[(TSQCalendarView *)self.view scrollToDate:[NSDate date] animated:NO];
        (view as? TSQCalendarView)?.scroll(to: dpr?.date, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        specDate = true
        DBGLog("showing tsqcal seldate= %@", dpr?.date)
        (view as? TSQCalendarView)?.selectedDate = dpr?.date
        specDate = false

        super.viewDidAppear(animated)

        // Uncomment this to test scrolling performance of your custom drawing
        //    self.timer = [NSTimer scheduledTimerWithTimeInterval:.1 target:self selector:@selector(scroll) userInfo:nil repeats:YES];
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        view.setNeedsDisplay()
    }

    override func viewWillDisappear(_ animated: Bool) {
        timer?.invalidate()
        timer = nil
        super.viewWillDisappear(animated)
    }

    static var scrollAtTop = true

    func scroll() {
        let calendarView = view as? TSQCalendarView
        let tableView = calendarView?.tableView

        tableView?.setContentOffset(CGPoint(x: 0.0, y: trackerCalViewController.scrollAtTop != 0 ? 10000.0 : 0.0), animated: true)
        trackerCalViewController.scrollAtTop = !trackerCalViewController.scrollAtTop
    }

    @objc func calendarView(_ calendarView: TSQCalendarView?, didSelect date: Date?) {
        if specDate {
            return
        }

        dpr?.date = date
        dpr?.action = DPA_GOTO_POST
        //[self dismissModalViewControllerAnimated:YES];
        dismiss(animated: true)
        if SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO("13.0") {
            (presentationController?.delegate as? UIViewController)?.viewWillAppear(false)
        }
    }

    @objc func calendarView(_ calendarView: TSQCalendarView?, shouldSelect date: Date?) -> Bool {
        if let date {
            if nil != dateSelDict?[date] {
                return true
            }
        }
        var components = calendar?.components([.era, .year, .month, .day], from: Date())
        var today: Date? = nil
        if let components {
            today = calendar?.date(from: components)
        }
        if let date {
            components = calendar?.components([.era, .year, .month, .day], from: date)
        }
        var inDate: Date? = nil
        if let components {
            inDate = calendar?.date(from: components)
        }

        if let inDate {
            if today?.isEqual(to: inDate) ?? false {
                return true
            }
        }
        return false
    }

    @objc func calendarView(_ calendarView: TSQCalendarView?, colorFor date: Date?) -> UIColor? {
        var obj: Any? = nil
        if let date {
            obj = dateSelDict?[date]
        }
        if nil == obj {
            return nil
        } else if "" == obj {
            return nil
        }
        return obj as? UIColor
    }
}

extension TSQCalendarView {
    private(set) var tableView: UITableView?
}