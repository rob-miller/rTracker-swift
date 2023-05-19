//  Converted to Swift 5.7.2 by Swiftify v5.7.25331 - https://swiftify.com/
//
//  CSVParser.swift
//  CSVImporter
//
//  Created by Matt Gallagher on 2009/11/30.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

//#import <Cocoa/Cocoa.h>

//
//  CSVParser.swift
//  CSVImporter
//
//  Created by Matt Gallagher on 2009/11/30.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

import UIKIt

class CSVParser: NSObject {
    var csvString: String?
    var separator: String?
    var scanner: Scanner?
    var hasHeader = false
    var fieldNames: [AnyHashable]?
    var receiver: Any?
    var receiverSelector: Selector?
    var endTextCharacterSet: CharacterSet?
    var separatorIsSingleChar = false

    //
    // initWithString:separator:hasHeader:fieldNames:
    //
    // Parameters:
    //    aCSVString - the string that will be parsed
    //    aSeparatorString - the separator (normally "," or "\t")
    //    header - if YES, treats the first row as a list of field names
    //    names - a list of field names (will have no effect if header is YES)
    //
    // returns the initialized object (nil on failure)
    //
    init(
        string aCSVString: String?,
        separator aSeparatorString: String?,
        hasHeader header: Bool,
        fieldNames names: [AnyHashable]?
    ) {
        super.init()
        csvString = aCSVString
        separator = aSeparatorString

        dbgNSAssert(
            (separator?.count ?? 0) > 0 && (separator as NSString?)?.range(of: "\"").location == NSNotFound && (separator as NSString?)?.rangeOfCharacter(from: .newlines).location == NSNotFound,
            "CSV separator string must not be empty and must not contain the double quote character or newline characters.")

        var endTextMutableCharacterSet = CharacterSet.newlines
        endTextMutableCharacterSet.insert(charactersIn: "\"")
        endTextMutableCharacterSet.insert(charactersIn: (separator as NSString?)?.substring(to: 1) ?? "")
        endTextCharacterSet = endTextMutableCharacterSet

        if (separator?.count ?? 0) == 1 {
            separatorIsSingleChar = true
        }

        hasHeader = header
        if nil != names {
            fieldNames = names
        } else {
            fieldNames = nil
        }
    }

    //
    // dealloc
    //
    // Releases instance memory.
    //


    //
    // arrayOfParsedRows
    //
    // Performs a parsing of the csvString, returning the entire result.
    //
    // returns the array of all parsed row records
    //
    func arrayOfParsedRows() -> [AnyHashable]? {
        scanner = Scanner(string: csvString ?? "")
        scanner?.charactersToBeSkipped = CharacterSet()

        let result = parseFile()
        scanner = nil

        return result
    }

    //
    // parseRowsForReceiver:selector:
    //
    // Performs a parsing of the csvString, sending the entries, 1 row at a time,
    // to the receiver.
    //
    // Parameters:
    //    aReceiver - the target that will receive each row as it is parsed
    //    aSelector - the selector that will receive each row as it is parsed
    //		(should be a method that takes a single NSDictionary argument)
    //
    func parseRows(forReceiver aReceiver: Any?, selector aSelector: Selector) {
        scanner = Scanner(string: csvString ?? "")
        scanner?.charactersToBeSkipped = CharacterSet()
        receiver = aReceiver
        receiverSelector = aSelector

        parseFile()

        scanner = nil
        receiver = nil
    }

    //
    // parseFile
    //
    // Attempts to parse a file from the current scan location.
    //
    // returns the parsed results if successful and receiver is nil, otherwise
    //	returns nil when done or on failure.
    //
    func parseFile() -> [AnyHashable]? {
        if hasHeader {

            fieldNames = parseHeader()
            if fieldNames == nil || parseLineSeparator() == nil {
                return nil
            }
        }

        var records: [AnyHashable]? = nil
        if receiver == nil {
            records = []
        }

        var record = parseRecord()
        if record == nil {
            return nil
        }

        while record {
            autoreleasepool {

                if let receiver {
                    //[receiver performSelector:receiverSelector withObject:record];
                    let imp = receiver.method(for: receiverSelector)
                    let `func`: ((Any?, Selector, [AnyHashable : Any]?) -> Void)? = imp
                    `func`?(receiver, receiverSelector!, record)
                } else {
                    if let record {
                        records?.append(record)
                    }
                }

                if parseLineSeparator() == nil {
                    break
                }

                record = parseRecord()
            }
        }

        return records
    }

    //
    // parseHeader
    //
    // Attempts to parse a header row from the current scan location.
    //
    // returns the array of parsed field names or nil on parse failure.
    //
    func parseHeader() -> [AnyHashable]? {
        var name = parseName()
        if name == nil {
            return nil
        }

        var names: [AnyHashable] = []
        while name {
            names.append(name ?? "")

            if parseSeparator() == nil {
                break
            }

            name = parseName()
        }
        return names
    }

    //
    // parseRecord
    //
    // Attempts to parse a record from the current scan location. The record
    // dictionary will use the fieldNames as keys, or FIELD_X for each column
    // X-1 if no fieldName exists for a given column.
    //
    // returns the parsed record as a dictionary, or nil on failure. 
    //
    func parseRecord() -> [AnyHashable : Any]? {
        //
        // Special case: return nil if the line is blank. Without this special case,
        // it would parse as a single blank field.
        //
        if parseLineSeparator() != nil || scanner?.isAtEnd ?? false {
            return nil
        }

        var field = parseField()
        if field == nil {
            return nil
        }

        let fieldNamesCount = fieldNames?.count ?? 0
        let fieldCount = 0

        var record = [AnyHashable : Any](minimumCapacity: (fieldNames?.count ?? 0))
        while field {
            var fieldName: String?
            if fieldNamesCount > fieldCount {
                fieldName = fieldNames?[fieldCount] as? String
            } else {
                fieldName = String(format: "FIELD_%ld", fieldCount + 1)
                fieldNames?.append(fieldName ?? "")
                fieldNamesCount += 1
            }

            record[(fieldName ?? "") + String(format: ":%ld", fieldCount)] = field ?? ""

            fieldCount += 1

            if parseSeparator() == nil {
                break
            }

            field = parseField()
        }

        return record
    }

    //
    // parseName
    //
    // Attempts to parse a name from the current scan location.
    //
    // returns the name or nil.
    //
    func parseName() -> String? {
        return parseField()
    }

    //
    // parseField
    //
    // Attempts to parse a field from the current scan location.
    //
    // returns the field or nil
    //
    func parseField() -> String? {
        let escapedString = parseEscaped()
        if let escapedString {
            return escapedString
        }

        let nonEscapedString = parseNonEscaped()
        if let nonEscapedString {
            return nonEscapedString
        }

        //
        // Special case: if the current location is immediately
        // followed by a separator, then the field is a valid, empty string.
        //
        let currentLocation = scanner?.scanLocation ?? 0
        if parseSeparator() != nil || parseLineSeparator() != nil || scanner?.isAtEnd ?? false {
            scanner?.scanLocation = currentLocation
            return ""
        }

        return nil
    }

    //
    // parseEscaped
    //
    // Attempts to parse an escaped field value from the current scan location.
    //
    // returns the field value or nil.
    //
    func parseEscaped() -> String? {
        if parseDoubleQuote() == nil {
            return nil
        }

        var accumulatedData = ""
        while true {
            var fragment = parseTextData()
            if fragment == nil {
                fragment = parseSeparator()
                if fragment == nil {
                    fragment = parseLineSeparator()
                    if fragment == nil {
                        if parseTwoDoubleQuotes() != nil {
                            fragment = "\""
                        } else {
                            break
                        }
                    }
                }
            }

            accumulatedData = accumulatedData + (fragment ?? "")
        }

        if parseDoubleQuote() == nil {
            return nil
        }

        return accumulatedData
    }

    //
    // parseNonEscaped
    //
    // Attempts to parse a non-escaped field value from the current scan location.
    //
    // returns the field value or nil.
    //
    func parseNonEscaped() -> String? {
        return parseTextData()
    }

    //
    // parseTwoDoubleQuotes
    //
    // Attempts to parse two double quotes from the current scan location.
    //
    // returns a string containing two double quotes or nil.
    //
    func parseTwoDoubleQuotes() -> String? {
        if scanner?.scanString("\"\"", into: nil) ?? false {
            return "\"\""
        }
        return nil
    }

    //
    // parseDoubleQuote
    //
    // Attempts to parse a double quote from the current scan location.
    //
    // returns @"\"" or nil.
    //
    func parseDoubleQuote() -> String? {
        if scanner?.scanString("\"", into: nil) ?? false {
            return "\""
        }
        return nil
    }

    //
    // parseSeparator
    //
    // Attempts to parse the separator string from the current scan location.
    //
    // returns the separator string or nil.
    //
    func parseSeparator() -> String? {
        if scanner?.scanString(separator ?? "", into: nil) ?? false {
            return separator
        }
        return nil
    }

    //
    // parseLineSeparator
    //
    // Attempts to parse newline characters from the current scan location.
    //
    // returns a string containing one or more newline characters or nil.
    //
    func parseLineSeparator() -> String? {
        var matchedNewlines: String? = nil
        scanner?.scanCharacters(
            from: .newlines,
            into: AutoreleasingUnsafeMutablePointer<NSString?>(mutating: &matchedNewlines))
        return matchedNewlines
    }

    //
    // parseTextData
    //
    // Attempts to parse text data from the current scan location.
    //
    // returns a non-zero length string or nil.
    //
    func parseTextData() -> String? {
        var accumulatedData = ""
        while true {
            var fragment: String?
            if let endTextCharacterSet {
                if scanner?.scanUpToCharacters(from: endTextCharacterSet, into: AutoreleasingUnsafeMutablePointer<NSString?>(mutating: &fragment)) ?? false {
                    accumulatedData = accumulatedData + (fragment ?? "")
                }
            }

            //
            // If the separator is just a single character (common case) then
            // we know we've reached the end of parseable text
            //
            if separatorIsSingleChar {
                break
            }

            //
            // Otherwise, we need to consider the case where the first character
            // of the separator is matched but we don't have the full separator.
            //
            let location = scanner?.scanLocation ?? 0
            var firstCharOfSeparator: String?
            if scanner?.scanString((separator as NSString?)?.substring(to: 1) ?? "", into: AutoreleasingUnsafeMutablePointer<NSString?>(mutating: &firstCharOfSeparator)) ?? false {
                if scanner?.scanString((separator as NSString?)?.substring(from: 1) ?? "", into: nil) ?? false {
                    scanner?.scanLocation = location
                    break
                }

                //
                // We have the first char of the separator but not the whole
                // separator, so just append the char and continue
                //
                accumulatedData = accumulatedData + (firstCharOfSeparator ?? "")
                continue
            } else {
                break
            }
        }

        if accumulatedData.count > 0 {
            return accumulatedData
        }

        return nil
    }
}