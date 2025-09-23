//
//  voFunctionConfig.swift
//  rTracker
//
//  Created by Robert Miller on 08/04/2025.
//  Copyright © 2025 Robert T. Miller. All rights reserved.
//

import Foundation

extension voFunction {
    
    // MARK: function configTVObjVC
    // MARK: -

    // MARK: range definition page

    //
    // convert endpoint from left or right picker to rownum for offset symbol (hours, months, ...) or valobj
    //

    // ep options are :
    //     row 0:      entry
    //     rows 1..m:  [valObjs] (ep = vid)
    //     rows n...:  other epTitles entries

    func ep(toRow component: Int) -> Int {
        let key = String(format: "frep%ld", component)
        var ep: Int?
        let n = vo.optDict[key]
        ep = (n != nil ? Int(n!) : nil)
        //DBGLog(String("comp= \(component) ep= \(ep) n= \(n)"))
        if n == nil || ep! == FREPDFLT {
            // no endpoint defined, so default row 0
            //DBGLog(" returning 0")
            return 0
        }
        if ep! >= 0 || ep! <= -TMPUNIQSTART {
            // ep defined and saved, or ep not saved and has tmp vid, so return ndx in vo table
            //return [MyTracker.valObjTable indexOfObjectIdenticalTo:[MyTracker getValObj:ep]] +1;
            if let getValObj = MyTracker.getValObj(ep!) {
                DBGLog(String(" returning \(UInt(((votWoSelf as NSArray?)?.indexOfObjectIdentical(to: getValObj) ?? 0) + 1))"))
                return ((votWoSelf as NSArray?)?.indexOfObjectIdentical(to: getValObj) ?? 0) + 1
            }
            return 0
            //return ep+1;
        }
        DBGLog(String(" returning \((ep! * -1) + votWoSelf.count - 1)"))
        return (ep! * -1) + votWoSelf.count - 1 // ep is offset into hours, months list
        //return (ep * -1) + [MyTracker.valObjTable count] -1;  // ep is offset into hours, months list
    }

    func fnrRowTitle(_ row: Int) -> String {
        var row = row
        if row != 0 {
            let votc = votWoSelf.count//[MyTracker.valObjTable count];
            if row <= votc {
                //DBGLog(String(" returning \(votWoSelf[row - 1].valueName)"))
                return votWoSelf[row - 1].valueName! //((valueObj*) [MyTracker.valObjTable objectAtIndex:row-1]).valueName;
            } else {
                row -= votc
            }
        }
        //DBGLog(String(" returning \(epTitles[row])"))
        return epTitles[row]
    }

    //
    // if picker row is offset (not valobj), display a textfield and label to get number of (hours, months,...) offset
    // check
    //

    func updateValTF(_ row: Int, component: Int) {
        let votc = votWoSelf.count //[MyTracker.valObjTable count];

        if row > votc {
            let vkey = String(format: "frv%ld", component)
            let key = String(format: "frep%ld", component)
            if FREPNONE == Int(vo.optDict[key]!) {
                return
            }
            let vtfkey = String(format: "fr%ldTF", component)
            let pre_vkey = String(format: "frpre%ldvLab", component)
            let post_vkey = String(format: "frpost%ldvLab", component)

            let vtf = (ctvovcp?.wDict)?[vtfkey] as? UITextField
            vtf?.text = vo.optDict[vkey]
            if let vtf {
                ctvovcp?.scroll.addSubview(vtf)
            }
            if let aWDict = (ctvovcp?.wDict)?[pre_vkey] as? UIView {
                ctvovcp?.scroll.addSubview(aWDict)
            }
            let postLab = (ctvovcp?.wDict)?[post_vkey] as? UILabel
            //postLab.text = [[self fnrRowTitle:row] stringByReplacingOccurrencesOfString:@"cal " withString:@"c "];
            postLab?.text = fnrRowTitle(row)
            //DBGLog(String(" postlab= \(postLab?.text ?? "")"))
            if let postLab {
                ctvovcp?.scroll.addSubview(postLab)
            }

            if (0 == component) && (ISCALFREP(Int(vo.optDict[key]!)!)) {
                let ckBtn = (ctvovcp?.wDict)?["calOnlyLastBtn"] as? UISwitch // UIButton
                let state = !(vo.optDict["calOnlyLast"] == "0") // default:1
                ckBtn?.isOn = state
                if let ckBtn {
                    ctvovcp?.scroll.addSubview(ckBtn)
                }
                let glLab = (ctvovcp?.wDict)?["calOnlyLastLabel"] as? UILabel
                if let glLab {
                    ctvovcp?.scroll.addSubview(glLab)
                }
            }
        }
    }

    func drawFuncOptsRange() {
        var frame = CGRect(x: MARGIN, y: ctvovcp?.lasty ?? 0.0, width: 0.0, height: 0.0)

        var labframe = ctvovcp?.configLabel(
            "Function range endpoints:",
            frame: frame,
            key: "freLab",
            addsv: true)
        frame.origin.x = MARGIN
        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN

        // labframe =
        _ = ctvovcp?.configLabel(
            "Previous:",
            frame: frame,
            key: "frpLab",
            addsv: true)
        frame.origin.x = ((ctvovcp?.view.frame.size.width ?? 0.0) / 2.0) + MARGIN

        labframe = ctvovcp?.configLabel(
            "Current:",
            frame: frame,
            key: "frcLab",
            addsv: true)

        frame.origin.y += (labframe?.size.height ?? 0.0) + MARGIN
        frame.origin.x = 0.0

        frame = ctvovcp?.configPicker(frame, key: "frPkr", caller: self) ?? CGRect.zero
        let pkr = (ctvovcp?.wDict)?["frPkr"] as? UIPickerView

        //DBGLog(String("pkr component 0 selectRow \(ep(toRow: 0))"))
        pkr?.selectRow(ep(toRow: 0), inComponent: 0, animated: false)
        //DBGLog(String("pkr component 1 selectRow \(ep(toRow: 1))"))
        pkr?.selectRow(ep(toRow: 1), inComponent: 1, animated: false)

        frame.origin.y += frame.size.height + MARGIN
        frame.origin.x = MARGIN

        labframe = ctvovcp?.configLabel(
            "-",
            frame: frame,
            key: "frpre0vLab",
            addsv: false)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        let tfWidth = "9999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovcp?.lfHeight ?? 0.0)

        _ = ctvovcp?.configTextField(
            frame,
            key: "fr0TF",
            target: nil,
            action: nil,
            num: true,
            place: nil,
            text: vo.optDict["frv0"],
            addsv: false)

        frame.origin.x += tfWidth + 2 * SPACE
        //labframe =
        _ = ctvovcp?.configLabel(
            "cal months",
            frame: frame,
            key: "frpost0vLab",
            addsv: false)

        //[self updateValTF:[self epToRow:0] component:0];

        frame.origin.x = ((ctvovcp?.view.frame.size.width ?? 0.0) / 2.0) + MARGIN

        labframe = ctvovcp?.configLabel(
            "only last:",
            frame: frame,
            key: "calOnlyLastLabel",
            addsv: false)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        _ = ctvovcp?.configSwitch(
            frame,
            key: "calOnlyLastBtn",
            state: !(vo.optDict["calOnlyLast"] == "0"),
            addsv: false)

        updateValTF(ep(toRow: 0), component: 0)

    }

    // MARK: -
    // MARK: function definition page

    //
    // generate text to describe function as specified by symbols,vids in fnArray from
    //  strings in fnStrs or valueObj names
    //

    func reloadEmptyFnArray() {
        if 0 == fnArray.count {
            // one last try if nothing there
            loadConfig()
        }
    }

    func voFnDefnStr(_ dbg: Bool = false, cfndx: Int? = nil) -> String? {
        var cfndx = cfndx
        var fstr = ""
        var closePending = false //square brackets around target of Fn1Arg
        var constantPending = false // next item is a number not tok or vid
        var constantClosePending = false // constant bounded on both sides by constant token
        var arg2Pending = false // looking for second argument
        var openParenCount = 0
        
        for (ndx, n) in fnArray.enumerated() {
            let i = n.intValue
            if let cfn = cfndx {
                if cfn == ndx {
                    fstr += ">"
                }
            }
            //DBGLog(@"loop start: closePend=%d constantPend=%d constantClosePend=%d arg2Pend=%d openParen=%d fstr=%@",closePending,constantPending,constantClosePending,arg2Pending, openParenCount, fstr);
            if constantPending {
                fstr += n.stringValue
                constantPending = false
                constantClosePending = true
            } else if isFn(i) {
                if isFn2ArgOp(i) {
                    arg2Pending = true
                } else {
                    arg2Pending = false
                }
                if FNCONSTANT == i {
                    if constantClosePending {
                        constantClosePending = false
                    } else {
                        constantPending = true
                    }
                } else {
                    //NSInteger ndx = (i * -1) -1;
                    //[fstr appendString:[self.fnStrs objectAtIndex:ndx]];  xxx   // get str for token
                    fstr += "\(fnStrDict[NSNumber(value:i)]!)"
                    if isFn1Arg(i) {
                        // Special handling for classify operator
                        if i == FN1ARGCLASSIFY {
                            fstr += "["
                            closePending = true
                            
                            // Skip over the classify values in display
                            if let cfn = cfndx, cfn > ndx {
                                // We're highlighting the current token, need to adjust
                                // Skip over the classify values (14 entries) when advancing
                                let tokensToSkip = 14
                                if cfn <= ndx + tokensToSkip + 1 {
                                    // We're within the classify values, don't highlight
                                    cfndx = nil
                                }
                            }
                        } else {
                            fstr += "["
                            closePending = true
                        }
                    }
                    if FNPARENOPEN == i {
                        openParenCount += 1
                    } else if FNPARENCLOSE == i {
                        openParenCount -= 1
                    }
                }
            } else {
                if dbg {
                    let vt = MyTracker.voGetType(forVID: i)
                    if 0 > vt {
                        fstr += "noType"
                    } else {
                        fstr += ValueObjectType.typeNames[vt]
                    }
                } else {
                    fstr += MyTracker.voGetName(forVID: i)!  // could get from self.fnStrs
                }
                if closePending {
                    fstr += "]"
                    closePending = false
                }
                arg2Pending = false
            }
            if !closePending {
                fstr += " "
            }
            //DBGLog(String("loop end: closeP=\(closePending) constantP=\(constantPending) constantCloseP=\(constantClosePending) arg2P=\(arg2Pending) openPC=\(openParenCount) fstr=\(fstr)"))
        }
        if arg2Pending || closePending || constantPending || constantClosePending || openParenCount != 0 {
            fstr += " ❌"
            FnErr = true
        } else {
            FnErr = false
        }
        DBGLog(String("final fstr: \(fstr)"))
        return fstr
    }

    func updateFnTV() {
        let ftv = (ctvovcp?.wDict)?["fdefnTV2"] as? UITextView
        ftv?.text = voFnDefnStr()
    }

    @objc func btnAdd(_ sender: Any?) {
        if 0 >= fnTitles.count {
            noVarsAlert()
            return
        }

        let pkr = (ctvovcp?.wDict)?["fdPkr"] as? UIPickerView
        let row = pkr?.selectedRow(inComponent: 0) ?? 0
        let ntok = fnTitles[row] // get tok from fnTitle and add to fnArray

        if FNCONSTANT == ntok.intValue {
            // constant has const_tok on both sides to help removal
            let vtf = (ctvovcp?.wDict)?[CTFKEY] as? UITextField
            if let vtftd = Double(vtf!.text ?? "") {
                _fnArray!.append(ntok)
                _fnArray!.append(NSNumber(value: vtftd))
                _fnArray!.append(ntok)
                ctvovcp?.tfDone(vtf)
            } else {
                rTracker_resource.alert("Need Value", msg: "Please set a value for the constant.", vc: nil)
                return
            }
        } else if FN1ARGCLASSIFY == ntok.intValue {
            // Get values from text fields
            for i in 1...7 {
                if let tf = (ctvovcp?.wDict)?["classifyTF\(i)"] as? UITextField {
                    let value = tf.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    // Delete any existing value for this position
                    vo.optDict.removeValue(forKey: "classify_\(i)")
                    if !value.isEmpty {
                        vo.optDict["classify_\(i)"] = value
                    }
                }
            }
            _fnArray!.append(ntok)
        } else {
            _fnArray!.append(ntok)
        }
        updateFnTitles()
        pkr?.reloadComponent(0)
        updateFnTV()
    }

    @objc func btnDelete(_ sender: Any?) {
        // i= constTok remove token and value  -- done
        //  also [self.tempValObj.optDict removeObjectForKey:@"fdc"]; -- can't be sure with mult consts
        let pkr = (ctvovcp?.wDict)?["fdPkr"] as? UIPickerView
        DBGLog("fnArray=\(String(describing: _fnArray))")
        if 0 < fnArray.count {
            // Check if we're deleting a classify operator
            if FN1ARGCLASSIFY == fnArray.last!.intValue {
                _fnArray!.removeLast() // remove normal token
                
                // Also remove classify text values from optDict
                for i in 1...7 {
                    let key = "classify_\(i)_text"
                    vo.optDict.removeValue(forKey: key)
                }
            } else if FNCONSTANT == fnArray.last!.intValue {
                _fnArray!.removeLast() // remove bounding token after
                _fnArray!.removeLast() // remove constant value
                _fnArray!.removeLast() // remove start (normal) token
            } else {
                _fnArray!.removeLast() // remove normal token
            }
        }
        updateFnTitles()
        pkr?.reloadComponent(0)
        updateFnTV()
    }

    func drawFuncOptsDefinition() {
        guard let ctvovcp = ctvovcp else {
            return
        }
        updateFnTitles()

        // top of view
        var frame = CGRect(x: MARGIN, y: MARGIN, width: 0.0, height: 0.0)

        // label for view
        frame = ctvovcp.configLabel(
            "Function definition:",
            frame: frame,
            key: "fdLab",
            addsv: true)

        // textview to show function definition
        //frame.origin.x = MARGIN
        frame.origin.y += frame.size.height + MARGIN
        frame.size.width = ctvovcp.view.frame.size.width - 2 * MARGIN
        let maxDim = rTracker_resource.getScreenMaxDim()
        frame.size.height = maxDim/6
        
        frame = ctvovcp.configTextView(frame, key: "fdefnTV2", text: voFnDefnStr())

        // picker for function op choice
        //frame.origin.x = MARGIN
        frame.origin.y += frame.size.height - MARGIN  // default picker has too much vertical space for me
        frame = ctvovcp.configPicker(frame, key: "fdPkr", caller: self)

        // delete and add buttons
        //frame.origin.x = MARGIN
        frame.origin.y += frame.size.height
        frame = ctvovcp.configActionBtn(frame, key: "fddBtn", label: "Delete", target: self, action: #selector(btnDelete(_:)))
        frame.origin.x = -1.0  // -1 means right justify
        frame = ctvovcp.configActionBtn(frame, key: "fdaBtn", label: "Add", target: self, action: #selector(btnAdd(_:)))

        // below are hidden textfields, subviews not added yet
        // both vertically start here:
        frame.origin.y += frame.size.height + MARGIN;
        let startY = frame.origin.y
        
        // constant value label and text field -- subviews not added yet
        frame.origin.x = 3 * MARGIN
        
        frame = ctvovcp.configLabel(
            "Constant value:",
            frame: frame,
            key: CLKEY,
            addsv: false)

        frame.origin.x += frame.size.width + 2*SPACE
        let tfWidth = "9999.99".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = minLabelHeight(ctvovcp.lfHeight)

        _ = ctvovcp.configTextField(
            frame,
            key: CTFKEY,
            target: nil,
            action: nil,
            num: true,
            place: nil,
            text: nil,
            addsv: false)

        
        // classify fixed values and labels
        
        frame.origin.x = MARGIN
        
        // Screen width to calculate column positions
        let screenWidth = ctvovcp.view.frame.size.width
        
        // Use 2 columns for the 7 text fields
        let col1X = frame.origin.x
        let col2X = screenWidth / 2 + frame.origin.x/2
        
        for i in 0...7 {
            // Calculate position (column 1 for 0-3, column 2 for 4-7)
            let isColumn1 = i <= 3
            let columnX = isColumn1 ? col1X : col2X
            // Calculate Y position within its column
            let rowInColumn = isColumn1 ? i : i - 4
            let yPos = startY + CGFloat(rowInColumn * 40)
            
            // Row label with its value
            let frame = CGRect(x: columnX, y: yPos, width: 25, height: minLabelHeight(ctvovcp.lfHeight))
            let labelKey = "classify\(i)Label"
            _ = ctvovcp.configLabel(
                "\(i):",
                frame: frame,
                key: labelKey,
                addsv: false
            )
            
            if i > 0 {
                // Text field for the value
                let tfFrame = CGRect(
                    x: columnX + 20,
                    y: yPos,
                    width: (isColumn1 ? screenWidth/2 - MARGIN - 35 : screenWidth/2 - MARGIN*2 - 35),
                    height: minLabelHeight(ctvovcp.lfHeight)
                )
                
                _ = ctvovcp.configTextField(
                    tfFrame,
                    key: "classifyTF\(i)",
                    target: nil,
                    action: nil,
                    num: false,
                    place: nil,
                    text: nil,
                    addsv: false
                )
            }
        }
    }

    // MARK: -
    // MARK: function overview page

    //
    // nice text string to describe a specified range endpoint
    //

    func voEpStr(_ component: Int, dbg: Bool) -> String {
        let key = String(format: "frep%ld", component)
        let vkey = String(format: "frv%ld", component)
        let pre = component != 0 ? "current" : "previous"

        var ep: Int?
        let n = vo.optDict[key]
        ep = (n != nil ? Int(n!) : nil)
        let ep2 = n != nil ? (ep! + 1) * -1 : 0 // invalid if ep is tmpUniq (negative)

        if nil == n || FREPDFLT == ep || FREPNONE == ep {
            let anEpTitles = epTitles[ep2]
            return "\(pre) \(anEpTitles)" // FREPDFLT
        }

        if ep! >= 0 || ep! <= -TMPUNIQSTART {
            // endpoint is vid and valobj saved, or tmp vid as valobj not saved
            if dbg {
                let vtypeNames = ValueObjectType.typeNames[MyTracker.getValObj(ep!)!.vtype]
                return "\(pre) \(vtypeNames)"
            } else {
                return "\(pre) \(MyTracker.getValObj(ep!)!.valueName!)"
            }
        }

        // ep is hours / days / months entry
        let anEpTitles = epTitles[ep2]
        return "\(component != 0 ? "+" : "-")\(Int(vo.optDict[vkey] ?? "0")!) \(anEpTitles)"
    }

    func voRangeStr(_ dbg: Bool) -> String? {
        return "\(voEpStr(0, dbg: dbg)) to \(voEpStr(1, dbg: dbg))"
    }

    func drawFuncOptsOverview() {

        var frame = CGRect(x: MARGIN, y: ctvovcp?.lasty ?? 0.0, width: 0.0, height: 0.0)
        var labframe = ctvovcp?.configLabel(
            "Range:",
            frame: frame,
            key: "frLab",
            addsv: true)

        //frame = (CGRect) {-1.0f, frame.origin.y, 0.0f,labframe.size.height};
        //[self configActionBtn:frame key:@"frbBtn" label:@"Build" action:@selector(btnBuild:)];
        let screenSize = UIScreen.main.bounds.size

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + (labframe?.size.height ?? 0.0)
        frame.size.width = screenSize.width - 2 * MARGIN // seems always wrong on initial load // self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
        frame.size.height = ctvovcp?.lfHeight ?? 0.0

        _ = ctvovcp?.configTextView(frame, key: "frangeTV", text: voRangeStr(false))

        frame.origin.y += frame.size.height + MARGIN
        labframe = ctvovcp?.configLabel(
            "Definition:",
            frame: frame,
            key: "fdLab",
            addsv: true)

        frame = CGRect(x: -1.0, y: frame.origin.y, width: 0.0, height: labframe?.size.height ?? 0.0)
        //[self configActionBtn:frame key:@"fdbBtn" label:@"Build" action:@selector(btnBuild:)];

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + frame.size.height
        frame.size.width = screenSize.width - 2 * MARGIN // self.ctvovcp.view.frame.size.width - 2*MARGIN; // 300.0f;
        frame.size.height = 2 * (ctvovcp?.lfHeight ?? 0.0)

        let maxDim = rTracker_resource.getScreenMaxDim()
        if maxDim > 480 {
            if maxDim <= 568 {
                // iphone 5
                frame.size.height = 3 * (ctvovcp?.lfHeight ?? 0.0)
            } else if maxDim <= 736 {
                // iphone 6, 6+
                frame.size.height = 4 * (ctvovcp?.lfHeight ?? 0.0)
            } else {
                frame.size.height = 6 * (ctvovcp?.lfHeight ?? 0.0)
            }
        }

        _ = ctvovcp?.configTextView(frame, key: "fdefnTV", text: voFnDefnStr())

        frame.origin.y += frame.size.height + MARGIN

        labframe = ctvovcp?.configLabel("Display result decimal places:", frame: frame, key: "fnddpLab", addsv: true)

        frame.origin.x += (labframe?.size.width ?? 0.0) + SPACE
        let tfWidth = "999".size(withAttributes: [
            NSAttributedString.Key.font: PrefBodyFont
        ]).width
        frame.size.width = tfWidth
        frame.size.height = ctvovcp?.lfHeight ?? 0.0 // self.labelField.frame.size.height; // lab.frame.size.height;

        _ = ctvovcp?.configTextField(
            frame,
            key: "fnddpTF",
            target: nil,
            action: nil,
            num: true,
            place: "\(FDDPDFLT)",
            text: vo.optDict["fnddp"],
            addsv: true)

        // Display minutes as hrs:mins switch
        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + (labframe?.size.height ?? 0.0)

        labframe = ctvovcp?.configLabel("Display minutes as hrs:mins:", frame: frame, key: "hrsminsLab", addsv: true)

        frame = CGRect(x: (labframe?.size.width ?? 0.0) + MARGIN + SPACE, y: frame.origin.y, width: labframe?.size.height ?? 0.0, height: labframe?.size.height ?? 0.0)

        frame = ctvovcp?.configSwitch(
            frame,
            key: "hrsminsBtn",
            state: (vo.optDict["hrsmins"] == "1") /* default:0 */,
            addsv: true) ?? CGRect.zero

        frame.origin.x = MARGIN
        frame.origin.y += MARGIN + (labframe?.size.height ?? 0.0)

        frame = ctvovcp?.yAutoscale(frame) ?? CGRect.zero

        //frame.origin.y += frame.size.height + MARGIN;
        //frame.origin.x = MARGIN;

        ctvovcp?.lasty = frame.origin.y + frame.size.height + MARGIN
    }

    // MARK: -
    // MARK: configTVObjVC general support

    //
    // called for btnDone in configTVObjVC
    //

    func funcDone() -> Bool {
        if FnErr {
            return false
        }
        if fnArray.count != 0 {
            saveFnArray()
            DBGLog(String("funcDone 1: \(vo.optDict["func"])"))

            // frep0 and 1 not set if user did not click on range picker
            if vo.optDict["frep0"] == nil {
                vo.optDict["frep0"] = String("\(FREPDFLT)")
            }
            if vo.optDict["frep1"] == nil {
                vo.optDict["frep1"] = String("\(FREPDFLT)")
            }

            DBGLog(String("ep0= \(vo.optDict["frep0"])  ep1=\(vo.optDict["frep1"])"))
        }
        return true
    }

    @objc func btnHelp() {
        guard let ctvovc = ctvovcp else { return }

        switch fnSegNdx {
        case FNSEGNDX_OVERVIEW:
            rTracker_resource.showContextualHelp(
                identifiers: ["page_function_overview"],
                from: ctvovc.toolBar,
                in: ctvovc
            )
        case FNSEGNDX_RANGEBLD:
            showFunctionRangeHelp()
        case FNSEGNDX_FUNCTBLD:
            showFunctionDefinitionHelp()
        default:
            dbgNSAssert(false, "fnSegmentAction bad index!")
        }
    }

    // MARK: - Documentation Mapping Tables

    /// Maps function operator names to documentation identifiers
    private func getOperatorDocIdentifier(_ operatorName: String) -> String {
        switch operatorName.lowercased() {
        // Basic operators
        case "sum": return "op_sum"
        case "avg": return "op_avg"
        case "min": return "op_min"
        case "max": return "op_max"
        case "count": return "op_count"
        case "change_in": return "op_change_in"

        // Pre/post operators with hyphens
        case "pre-sum": return "op_pre_sum"
        case "post-sum": return "op_post_sum"
        case "pre-avg": return "op_pre_avg"
        case "post-avg": return "op_post_avg"
        case "pre-min": return "op_pre_min"
        case "post-min": return "op_post_min"
        case "pre-max": return "op_pre_max"
        case "post-max": return "op_post_max"
        case "pre-count": return "op_pre_count"
        case "post-count": return "op_post_count"
        case "pre-change_in": return "op_pre_change_in"
        case "post-change_in": return "op_post_change_in"

        // Ratio operators
        case "old/new": return "op_old_new"
        case "new/old": return "op_new_old"

        // Time elapsed operators
        case "elapsed_weeks": return "op_elapsed_weeks"
        case "elapsed_days": return "op_elapsed_days"
        case "elapsed_hrs": return "op_elapsed_hrs"
        case "elapsed_mins": return "op_elapsed_mins"
        case "elapsed_secs": return "op_elapsed_secs"

        // Other operators
        case "delay": return "op_delay"
        case "round": return "op_round"
        case "classify": return "op_classify"
        case "¬": return "op_not"

        // Arithmetic operators
        case "+": return "op_plus"
        case "-": return "op_minus"
        case "*": return "op_multiply"
        case "/": return "op_divide"

        // Logical operators
        case "∧": return "op_and"
        case "∨": return "op_or"
        case "⊕": return "op_xor"

        // Comparison operators
        case "==": return "op_equal"
        case "!=": return "op_not_equal"
        case ">": return "op_greater"
        case "<": return "op_less"
        case ">=": return "op_greater_equal"
        case "<=": return "op_less_equal"

        // Floor/ceiling
        case "⌊": return "op_floor"
        case "⌈": return "op_ceiling"

        default: return "op_unknown"
        }
    }

    /// Maps range endpoint picker selections to documentation identifiers
    private func getRangeDocIdentifiers() -> [String] {
        guard let ctvovc = ctvovcp else { return ["page_function_range"] }

        var identifiers = ["page_function_range"]

        // Check for endpoint picker selections from the range picker (frPkr) with two components
        if let rangePicker = ctvovc.wDict["frPkr"] as? UIPickerView {
            // Component 0 is the "Previous" (left) endpoint
            let leftRow = rangePicker.selectedRow(inComponent: 0)
            if leftRow == 0 {
                // Row 0 is "entry"
                identifiers.append("endpoint_entry")
            } else if leftRow <= votWoSelf.count {
                // This is a value object selection
                //let vobj = votWoSelf[leftRow - 1]
                //let vtypeName = ValueObjectType.typeNames[vobj.vtype]
                //identifiers.append("value_\(vtypeName.lowercased())")
                identifiers.append("endpoint_value")
            } else {
                // This is a time offset selection - map to appropriate endpoint
                let offsetIndex = leftRow - votWoSelf.count - 1
                let timeOffsets = ["hours", "days", "weeks", "months", "years", "cal_days", "cal_weeks", "cal_months", "cal_years", "none"]
                if offsetIndex >= 0 && offsetIndex < timeOffsets.count {
                    identifiers.append("endpoint_\(timeOffsets[offsetIndex])")
                } else {
                    identifiers.append("endpoint_time_offset")
                }
            }

            // Component 1 is the "Current" (right) endpoint
            let rightRow = rangePicker.selectedRow(inComponent: 1)
            if rightRow == 0 {
                // Row 0 is "entry"
                identifiers.append("endpoint_entry")
            } else if rightRow <= votWoSelf.count {
                // This is a value object selection
                identifiers.append("endpoint_value")
            }
            // Note: Component 1 only has votWoSelf.count + 1 rows (no time offsets)
        }

        return identifiers
    }

    /// Shows context-sensitive help for function range based on current picker selections
    func showFunctionRangeHelp() {
        guard let ctvovc = ctvovcp else { return }

        let identifiers = getRangeDocIdentifiers()

        rTracker_resource.showContextualHelp(
            identifiers: identifiers,
            from: ctvovc.toolBar,
            in: ctvovc
        )
    }

    /// Shows context-sensitive help for function definition based on current picker selection
    func showFunctionDefinitionHelp() {
        guard let ctvovc = ctvovcp else { return }

        var identifiers = ["page_function_definition"]

        // Check if there's a picker view and get the selected row
        if let pickerView = ctvovc.wDict["fdPkr"] as? UIPickerView {
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            if selectedRow < fnTitles.count {
                let operatorToken = fnTitles[selectedRow].intValue
                let operatorName = fnTokenToStr(operatorToken)
                let docIdentifier = getOperatorDocIdentifier(operatorName)
                identifiers.append(docIdentifier)
            }
        }

        // Show contextual help with page description and operator-specific help
        rTracker_resource.showContextualHelp(
            identifiers: identifiers,
            from: ctvovc.toolBar,
            in: ctvovc
        )
    }

    //
    // called for configTVObjVC  viewDidLoad
    //
    func funcVDL(_ ctvovc: configTVObjVC?, donebutton db: UIBarButtonItem?) {

        if vo.parentTracker.valObjTable.count > 0 {

            let flexibleSpaceButtonItem = UIBarButtonItem(
                barButtonSystemItem: .flexibleSpace,
                target: nil,
                action: nil)

            let segmentTextContent = ["Overview", "Range", "Definition"]

            let segmentedControl = UISegmentedControl(items: segmentTextContent)
            //[segmentTextContent release];

            segmentedControl.addTarget(self, action: #selector(fnSegmentAction(_:)), for: .valueChanged)
            //segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
            segmentedControl.selectedSegmentIndex = fnSegNdx //= 0;
            
            // Set accessibility properties for each segment with safe array access
            if segmentedControl.subviews.indices.contains(0) {
                segmentedControl.subviews[0].accessibilityIdentifier = "fnRange"
            }
            if segmentedControl.subviews.indices.contains(1) {
                segmentedControl.subviews[1].accessibilityIdentifier = "fnDefinition"
            }
            if segmentedControl.subviews.indices.contains(2) {
                segmentedControl.subviews[2].accessibilityIdentifier = "fnOverview"
            }

            segmentedControl.accessibilityIdentifier = "fnConfigSeg"
            
            let scButtonItem = UIBarButtonItem(
                customView: segmentedControl)
            let fnHelpButtonItem = rTracker_resource.createHelpInfoButton(target: self, action: #selector(btnHelp))

            ctvovc?.toolBar.items = [
                db,
                flexibleSpaceButtonItem,
                scButtonItem,
                flexibleSpaceButtonItem,
                fnHelpButtonItem,
                flexibleSpaceButtonItem
            ].compactMap { $0 }
        } else {
            ctvovc?.toolBar.items = [db].compactMap { $0 }
        }

    }

    func drawSelectedPage() {
        ctvovcp!.lasty = 2 //frame.origin.y + frame.size.height + MARGIN;
        switch fnSegNdx {
        case FNSEGNDX_OVERVIEW:
            drawFuncOptsOverview()
            super.voDrawOptions(ctvovcp!)
        case FNSEGNDX_RANGEBLD:
            drawFuncOptsRange()
        case FNSEGNDX_FUNCTBLD:
            drawFuncOptsDefinition()
        default:
            dbgNSAssert(false, "fnSegmentAction bad index!")
        }
    }

    @objc func fnSegmentAction(_ sender: UISegmentedControl) {
        fnSegNdx = sender.selectedSegmentIndex
        //DBGLog(@"fnSegmentAction: selected segment = %d", self.fnSegNdx);

        //[UIView beginAnimations:nil context:NULL];
        //[UIView setAnimationBeginsFromCurrentState:YES];
        //[UIView setAnimationDuration:kAnimationDuration];
        UIView.animate(withDuration: 0.2, animations: { [self] in
            ctvovcp?.removeSVFields()
            drawSelectedPage()
        })
        //[UIView commitAnimations];
    }

    
    func noVarsAlert() {
        rTracker_resource.alert("No variables for function", msg: "A function needs variables to work on.\n\nPlease add a value (like a number, or anything other than a function) to your tracker before trying to create a function.", vc: nil)
    }
    
    
    func checkVOs() -> Bool {
        for valo in MyTracker.valObjTable {
            if valo.vtype != VOT_FUNC {
                return true
            }
        }
        return false
    }
    

    // MARK: -
    // MARK: picker support

    //
    // build list of titles for symbols,operations available for current point in fn definition string
    //

    func ftAddFnSet() {
        //var i: Int
        //for (i=FN1ARGFIRST;i>=FN1ARGLAST;i--) {
        //    [self.fnTitles addObject:[NSNumber numberWithInt:i]];   xxx // add nsnumber token, enumerated by fn class
        //}
        for i in 0..<ARG1CNT {
            let aFn1args = NSNumber(value:fn1args[i])
            fnTitles.append(aFn1args)
        }
        fnTitles.append(NSNumber(value:FNCONSTANT))  // String("\(FNCONSTANT)"))
    }

    func ftAddTimeSet() {
        //var i: Int
        for i in 0..<TIMECNT {
            let aFnTimeOps = NSNumber(value:fnTimeOps[i])
            fnTitles.append(aFnTimeOps)
        }
        //for (i=FNTIMEFIRST;i>=FNTIMELAST;i--) {
        //    [self.fnTitles addObject:[NSNumber numberWithInt:i]];   xxx
        //}
    }

    func ftAdd2OpSet() {
        //var i: Int
        for i in 0..<ARG2CNT {
            let aFn2args = NSNumber(value:fn2args[i])
            fnTitles.append(aFn2args)
            
        }
        //for (i=FN2ARGFIRST;i>=FN2ARGLAST;i--) {
        //    [self.fnTitles addObject:[NSNumber numberWithInt:i]];  xxx
        //}
    }

    func ftAddVOs() {
        for valo in MyTracker.valObjTable {
            // Only add if:
            // 1. It's not the current valueObj (vo)
            // 2. It's not referencing current tracker as its otTracker
            if valo != vo && valo.optDict["otTracker"] != MyTracker.trackerName {
                fnTitles.append(NSNumber(value: valo.vid))
            }
        }
    }

    func ftAddCloseParen() {
        var pcount = 0
        for ni in fnArray {
            let i = ni.intValue
            if i == FNPARENOPEN {
                pcount += 1
            } else if i == FNPARENCLOSE {
                pcount -= 1
            }
        }
        if pcount > 0 {
            fnTitles.append(NSNumber(value:FNPARENCLOSE))  // String(utf8String: FNPARENCLOSE) ?? "")
        }
    }

    func ftStartSet() {
        ftAddFnSet()
        ftAddTimeSet()
        fnTitles.append(NSNumber(value:FNPARENOPEN))  // String(utf8String: FNPARENOPEN) ?? "")
        ftAddVOs()
    }

    func updateFnTitles() {
        // create array fnTitles of nsnumber tokens which should be presented in picker for current list of fn being built
        fnTitles.removeAll()
        hideConstTF()
        hideClassifyTF()
        DBGLog(String("fnArray= \(fnArray)"))
        if fnArray.count == 0 {
            // state = start
            ftStartSet()
        } else {
            let last = fnArray.last!.intValue
            if last >= 0 || last <= -TMPUNIQSTART || isFnTimeOp(last) || FNCONSTANT == last {
                // state = after valObj
                ftAdd2OpSet()
                ftAddCloseParen()
            } else if isFn1Arg(last) {
                // state = after Fn1 = delta, avg, sum
                ftAddVOs()
            } else if isFn2ArgOp(last) {
                // state = after fn2op = +,-,*,/
                ftStartSet()
            } else if last == FNPARENCLOSE {
                // state = after close paren
                ftAdd2OpSet()
                ftAddCloseParen()
            } else if last == FNPARENOPEN {
                // state = after open paren
                ftStartSet()
            } else {
                dbgNSAssert(false, "lost it at updateFnTitles")
            }
        }
    }

    func fnTokenToStr(_ tok: Int) -> String {
        // convert token to str
        if isFn(tok) {
            return String("\(fnStrDict[NSNumber(value: tok)]!)")
        } else {
            for valo in MyTracker.valObjTable {
                if valo.vid == tok {
                    return valo.valueName!
                }
            }
            dbgNSAssert(false, "fnTokenToStr failed to find valObj")
            return "unknown vid"
        }
    }

    func fndRowTitle(_ row: Int) -> String {
        return fnTokenToStr(fnTitles[row].intValue) // get nsnumber(tok) from fnTitles, convert to int, convert to str to be placed in specified picker rox
    }

    func fnTokenToAttrStr(_ tok: Int) -> NSAttributedString {
        // convert token to str
        if isFn(tok) {
            return NSAttributedString(
                string: String("\(fnStrDict[NSNumber(value: tok)]!)"),
                attributes: [.foregroundColor: UIColor.systemBlue]
            )

        } else {
            for valo in MyTracker.valObjTable {
                if valo.vid == tok {
                    return NSAttributedString(
                        string: valo.valueName!,
                        attributes: [.foregroundColor: UIColor.systemGreen]
                    )
                }
            }
            dbgNSAssert(false, "fnTokenToStr failed to find valObj")
            return NSAttributedString(
                string: "unknown vid",
                attributes: [.foregroundColor: UIColor.systemRed]
            )
        }
    }

    func fndRowAttrTitle(_ row: Int) -> NSAttributedString {
        return fnTokenToAttrStr(fnTitles[row].intValue) // get nsnumber(tok) from fnTitles, convert to int, convert to str to be placed in specified picker rox
    }
    
    func fnrRowCount(_ component: Int) -> Int {
       // only allow time offset for previous side of range
        if component == 1 {
            //DBGLog(String(" returning \(votWoSelf.count + 1)"))
            return votWoSelf.count + 1 // [MyTracker.valObjTable count]+1;  // count all +1 for 'current entry'
        } else {
            //DBGLog(String(" returning \(votWoSelf.count + MAXFREP)"))
            return votWoSelf.count + MAXFREP //[MyTracker.valObjTable count] + MAXFREP;
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return 2
        } else {
            return 1
        }
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return fnrRowCount(component)
        } else {
            return fnTitles.count
        }
    }

    func pickerView(
        _ pickerView: UIPickerView,
        titleForRow row: Int,
        forComponent component: Int
    ) -> String? {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return fnrRowTitle(row)
        } else {
            // FNSEGNDX_FUNCTBLD
            return fndRowTitle(row)
        }
    }

    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            return NSAttributedString(
                string: fnrRowTitle(row),
                attributes: [.foregroundColor: UIColor.label]
            )
        } else {
            return fndRowAttrTitle(row)
        }
    }
        
    func update(forPickerRowSelect row: Int, inComponent component: Int) {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            ((ctvovcp?.wDict)?["frPkr"] as? UIPickerView)?.reloadComponent(component != 0 ? 0 : 1)
        }
    }

    func showConstTF() {
        // display constant box
        let vtf = (ctvovcp?.wDict)?[CTFKEY] as? UITextField
        vtf?.text = vo.optDict[LCKEY]
        if let aWDict = (ctvovcp?.wDict)?[CLKEY] as? UIView {
            ctvovcp?.scroll.addSubview(aWDict)
        }
        if let vtf {
            ctvovcp?.scroll.addSubview(vtf)
        }
    }

    func hideConstTF() {
        // hide constant box
        ((ctvovcp?.wDict)?[CTFKEY] as? UIView)?.removeFromSuperview()
        ((ctvovcp?.wDict)?[CLKEY] as? UIView)?.removeFromSuperview()
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if fnSegNdx == FNSEGNDX_RANGEBLD {
            let votc = votWoSelf.count //[MyTracker.valObjTable count];

            let key = String(format: "frep%ld", component)
            let vtfkey = String(format: "fr%ldTF", component)
            let pre_vkey = String(format: "frpre%ldvLab", component)
            let post_vkey = String(format: "frpost%ldvLab", component)

            ((ctvovcp?.wDict)?[pre_vkey] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?[vtfkey] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?[post_vkey] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?["calOnlyLastBtn"] as? UIView)?.removeFromSuperview()
            ((ctvovcp?.wDict)?["calOnlyLastLabel"] as? UIView)?.removeFromSuperview()

            if row == 0 {
                vo.optDict[key] = "-1"  // NSNumber(value: -1)
            } else if row <= votc {
                vo.optDict[key] = String("\(votWoSelf[row - 1].vid)")  // NSNumber(value: votWoSelf[row - 1].vid)
            } else {
                vo.optDict[key] = String("\(((row - votc) + 1) * -1)")  // NSNumber(value: ((row - votc) + 1) * -1)
                updateValTF(row, component: component)
            }
            //DBGLog(String("picker sel row \(row) \(key) now= \(vo.optDict[key])"))
        } else if fnSegNdx == FNSEGNDX_FUNCTBLD {
            //DBGLog(@"fn build row %d= %@",row,[self fndRowTitle:row]);
            // Hide all UI elements first
            hideConstTF()
            hideClassifyTF()
            
            // Show appropriate UI based on selection
            if FNCONSTANT_TITLE == fndRowTitle(row) {
                showConstTF()
            } else if "classify" == fndRowTitle(row) {
                // Show the UI and load any existing values
                showClassifyTF()
                loadClassifyValues()
            }
        }

        update(forPickerRowSelect: row, inComponent: component)
    }
    
    // MARK: - Classify function configuration
    

    
    // Show the classify UI elements (text fields)
    func showClassifyTF() {
        for i in 0...7 {
            if let aWDict = (ctvovcp?.wDict)?["classify\(i)Label"] as? UIView {
                ctvovcp?.scroll.addSubview(aWDict)
            }
            if i > 0 {
                if let vtf = (ctvovcp?.wDict)?["classifyTF\(i)"] as? UITextField {
                    vtf.text = vo.optDict["classify_\(i)"]
                    ctvovcp?.scroll.addSubview(vtf)
                }
            }
        }
    }
    
    // Remove the classify UI elements
    func hideClassifyTF() {
        for i in 0...7 {
            // Remove the text fields and labels
            ((ctvovcp?.wDict)?["classify\(i)Label"] as? UIView)?.removeFromSuperview()
            if i > 0 {
                ((ctvovcp?.wDict)?["classifyTF\(i)"] as? UIView)?.removeFromSuperview()
            }
        }
    }
    
    // Load classify values from fnArray to UI
    func loadClassifyValues() {
        // Check if we have a classify function
        // Classify token + vid + 14 values (7 pairs of flags and values)
        let currentLength = fnArray.count
        if currentLength < 16 || fnArray[currentLength-16].intValue != FN1ARGCLASSIFY {
            return
        }
        
        // Show the UI elements if not already visible
        showClassifyTF()
        
        // Start with the first flag/value pair
        var arrayIndex = currentLength - 14
        
        // Load the values into text fields
        for i in 1...7 {
            if arrayIndex < currentLength && arrayIndex + 1 < currentLength {
                let tf = (ctvovcp?.wDict)?["classifyTF\(i)"] as? UITextField
                let flag = fnArray[arrayIndex].doubleValue
                let value = fnArray[arrayIndex + 1].doubleValue
                
                if flag == 1.0 {
                    // Text match - load from optDict
                    let key = "classify_\(i)"
                    tf?.text = vo.optDict[key]
                } else if value != 0.0 {
                    // Numeric value - use the value directly
                    tf?.text = String(value)
                } else {
                    // Empty value
                    tf?.text = ""
                }
                
                arrayIndex += 2
            }
        }
    }
}
