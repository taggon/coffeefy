//
//  SwiftRegex.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014-6 John Holdsworth.
//
//  $Id: //depot/SwiftRegex/SwiftRegex.swift#56 $
//
//  This code is in the public domain from:
//  https://github.com/johnno1962/SwiftRegex
//

import Foundation

extension String {

    public func index(offset: Int) -> String.Index {
        if offset == NSNotFound {
            return endIndex
        }
        else if offset < 0 {
            return index(endIndex, offsetBy: offset)
        }
        else {
            return index(startIndex, offsetBy: offset)
        }
    }

    public func substring(from: Int, to:Int) -> String {
        return substring(with: index(offset:from)..<index(offset:to))
    }

    public subscript(from: Int) -> String {
        let from = index(offset: from)
        return substring(with: from..<index( from, offsetBy: 1 ))
    }

    public subscript(from: Int, to: Int) -> String {
        return substring(from: from, to: to)
    }

    public subscript(range: Range<Int>) -> String {
        return substring(from: range.lowerBound, to: range.upperBound)
    }

    public subscript(pattern: String) -> SwiftRegex {
        return self[pattern, SwiftRegex.defaultOptions]
    }

    public subscript(pattern: String, options: NSRegularExpression.Options) -> SwiftRegex {
        return SwiftRegex(target: self.mutable, pattern: pattern, options: options)
    }

    public var mutable: NSMutableString {
        return NSMutableString(string: self)
    }

}

extension NSMutableString {

    public subscript(pattern: String) -> MutableRegex {
        return self[pattern, SwiftRegex.defaultOptions]
    }

    public subscript(pattern: String, options: NSRegularExpression.Options) -> MutableRegex {
        return MutableRegex(target: self, pattern: pattern, options: options)
    }

}

open class SwiftRegex: Sequence, IteratorProtocol {

    private static var cache = [String:NSRegularExpression]()

    static let defaultOptions: NSRegularExpression.Options = []
    static let defaultMatching: NSRegularExpression.MatchingOptions = []

    public func makeIterator() -> SwiftRegex {
        return self
    }

    public func next() -> [String?]? {
        return nextGroups()
    }

    static func error(_ msg: String) {
        print("\(self): \(msg)")
    }

    let regex: NSRegularExpression
    let target: NSMutableString
    var targetRange: NSRange

    public init(target: NSMutableString, regex: NSRegularExpression) {
        self.target = target
        targetRange = NSMakeRange(0, target.length)
        self.regex = regex
    }

    public convenience init(target: NSMutableString, pattern: String, options: NSRegularExpression.Options? = nil) {
        do {
            let regex = try SwiftRegex.cache[pattern] ?? NSRegularExpression(pattern: pattern, options: options ?? SwiftRegex.defaultOptions)
            self.init(target: target, regex: regex)
            SwiftRegex.cache[pattern] = regex
        }
        catch (let e as NSError) {
            SwiftRegex.error("Invalid regexp '\(pattern)': \(e)")
            self.init(target: target, regex: NSRegularExpression())
        }
    }

    open func targetString(match: NSTextCheckingResult, group: Int) -> String? {
        if group <= regex.numberOfCaptureGroups {
            let groupRange = match.rangeAt(group)
            return groupRange.location != NSNotFound ? target.substring(with: groupRange) : nil
        }
        SwiftRegex.error("Invalid group number \(group) > \(regex.numberOfCaptureGroups)")
        return nil
    }

    open func targetStrings(match: NSTextCheckingResult) -> [String?] {
        return (0...regex.numberOfCaptureGroups).map { targetString(match: match, group: $0) }
    }

    open func matchResults( options: NSRegularExpression.MatchingOptions? = nil ) -> [NSTextCheckingResult] {
        return regex.matches( in: target as String, options: options ?? SwiftRegex.defaultMatching, range: targetRange )
    }

    open func ranges( options: NSRegularExpression.MatchingOptions? = nil ) -> [NSRange] {
        return matchResults( options: options ).map { $0.range }
    }

    open func matches( options: NSRegularExpression.MatchingOptions? = nil ) -> [String] {
        return matchResults( options: options ).map { targetString(match: $0, group: 0) ?? "nomatch" }
    }

    open func allGroups( options: NSRegularExpression.MatchingOptions? = nil ) -> [[String?]] {
        return matchResults( options: options ).map { targetStrings(match: $0) }
    }

    public func dictionary( options: NSRegularExpression.MatchingOptions? = nil ) -> Dictionary<String,String> {
        var out = [String:String]()
        for groups in self {
            out[groups[1] ?? ""] = groups[2]
        }
        return out
    }

    open func nextMatch( options: NSRegularExpression.MatchingOptions? = nil ) -> NSTextCheckingResult? {
        if let match = regex.firstMatch(in: target as String, options: options ?? SwiftRegex.defaultMatching, range: targetRange) {
            targetRange.location = match.range.location + match.range.length
            targetRange.length = target.length - targetRange.location
            return match
        }
        targetRange = NSMakeRange(0, target.length)
        return nil
    }

    open func nextGroups( options: NSRegularExpression.MatchingOptions? = nil ) -> [String?]? {
        return nextMatch( options: options ).flatMap { targetStrings( match: $0 ) }
    }

    open subscript(group: Int) -> String? {
        return self[group, SwiftRegex.defaultMatching]
    }

    open subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> String? {
        return nextMatch(options: options).flatMap { targetString(match: $0, group: group) }
    }

    open subscript(groups: [Int]) -> [String?]? {
        return self[groups, SwiftRegex.defaultMatching]
    }

    open subscript(groups: [Int], options: NSRegularExpression.MatchingOptions) -> [String?]? {
        if let match = nextMatch(options: options) {
            return groups.map { targetString(match: match, group: $0) }
        }
        return nil
    }
    
    open subscript(groups: Range<Int>) -> [String?]? {
        return self[groups, SwiftRegex.defaultMatching]
    }

    open subscript(groups: Range<Int>, options: NSRegularExpression.MatchingOptions) -> [String?]? {
        if let match = nextMatch(options: options) {
            return (groups.lowerBound..<groups.upperBound).map { targetString(match: match, group: $0) }
        }
        return nil
    }

    open func makeMutable() -> MutableRegex {
        return MutableRegex(target: target, regex: regex)
    }

    open subscript(template: String) -> String {
        return self[template, SwiftRegex.defaultMatching]
    }

    open subscript(template: String, options: NSRegularExpression.MatchingOptions) -> String {
        let mutable = makeMutable()
        mutable ~= template
        return mutable.target as String
    }

    open subscript(templates: [String]) -> String {
        return self[templates, SwiftRegex.defaultMatching]
    }

    open subscript(templates: [String], options: NSRegularExpression.MatchingOptions) -> String {
        let mutable = makeMutable()
        mutable ~= templates
        return mutable.target as String
    }

    open subscript(replacer: @escaping (String) -> String) -> String {
        return self[replacer, SwiftRegex.defaultMatching]
    }

    open subscript(replacer: @escaping (String) -> String, options: NSRegularExpression.MatchingOptions) -> String {
        let mutable = makeMutable()
        mutable ~= replacer
        return mutable.target as String
    }

    open subscript(replacer: @escaping ([String?]) -> String) -> String {
        return self[replacer, SwiftRegex.defaultMatching]
    }

    open subscript(replacer: @escaping ([String?]) -> String, options: NSRegularExpression.MatchingOptions) -> String {
        let mutable = makeMutable()
        mutable ~= replacer
        return mutable.target as String
    }

    open var boolValue: Bool {
        return nextMatch() != nil
    }

}

open class MutableRegex : SwiftRegex {

    var fileRegex: FileRegex?

    @discardableResult
    open func substituteMatches( options: NSRegularExpression.MatchingOptions? = nil, group: Int = 0,
                                 substitution: (NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String ) -> Bool {
        let out = NSMutableString()
        var matched = false
        var pos = 0

        regex.enumerateMatches( in: target as String, options: options ?? SwiftRegex.defaultMatching, range: targetRange ) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
            if let match = match {
                let matchRange = match.rangeAt(group)
                out.append( target.substring(with: NSRange(location:pos, length:matchRange.location-pos)) )
                out.append( substitution(match, stop) )
                pos = matchRange.location + matchRange.length
                matched = true
            }
        }

        if matched {
            out.append( target.substring(with: NSRange(location:pos, length:targetRange.length-pos)) )
            target.setString(out as String)
            targetRange = NSMakeRange(0, target.length)
            fileRegex?.update()
        }
        return matched
    }

    open func replacement(for match: NSTextCheckingResult, template: String) -> String {
        return regex.replacementString( for: match, in: target as String, offset: 0, template: template )
    }

    open override subscript(group: Int) -> String? {
        get {
            return self[group, SwiftRegex.defaultMatching]
        }
        set (newValue) {
            self[group, SwiftRegex.defaultMatching] = newValue
        }
    }

    open override subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> String? {
        get {
            return super[group, options]
        }
        set (newValue) {
            substituteMatches(options: options, group: group) {
                (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
                return replacement( for: match, template: newValue ?? "nil" )
            }
        }
    }

    open subscript(group: Int) -> [String] {
        get {
            return self[group, SwiftRegex.defaultMatching]
        }
        set (newValue) {
            self[group, SwiftRegex.defaultMatching] = newValue
        }
    }

    open subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> [String] {
        get {
            return []
        }
        set (newValue) {
            var matchNumber = 0
            substituteMatches(options: options, group: group) {
                (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in

                matchNumber += 1
                if matchNumber == newValue.count {
                    stop.pointee = true
                }

                return replacement( for: match, template: newValue[matchNumber-1] )
            }
        }
    }

    open subscript(group: Int) -> (String) -> String {
        get {
            return self[group, SwiftRegex.defaultMatching]
        }
        set (newValue) {
            self[group, SwiftRegex.defaultMatching] = newValue
        }
    }

    open subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> (String) -> String {
        get {
            return { _ in
                return "" }
        }
        set (newValue) {
            substituteMatches(options: options, group: group ) {
                (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
                return newValue( targetString(match: match, group: 0) ?? "" )
            }
        }
    }

    open subscript(group: Int) -> ([String?]) -> String {
        get {
            return self[group, SwiftRegex.defaultMatching]
        }
        set (newValue) {
            self[group, SwiftRegex.defaultMatching] = newValue
        }
    }

    open subscript(group: Int, options: NSRegularExpression.MatchingOptions) -> ([String?]) -> String {
        get {
            return { _ in
                return "" }
        }
        set (newValue) {
            substituteMatches(options: options, group: group ) {
                (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
                return newValue( targetStrings(match: match) )
            }
        }
    }

}

@discardableResult
public func ~= ( left: MutableRegex, right: String ) -> Bool {
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return left.replacement( for: match, template: right )
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: [String] ) -> Bool {
    var matchNumber = 0
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in

        matchNumber += 1
        if matchNumber == right.count {
            stop.pointee = true
        }

        return left.replacement( for: match, template: right[matchNumber-1] )
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: @escaping (String) -> String ) -> Bool {
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.targetString(match: match, group: 0) ?? "nomatch" )
    }
}

@discardableResult
public func ~= ( left: MutableRegex, right: @escaping ([String?]) -> String ) -> Bool {
    return left.substituteMatches() {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.targetStrings(match: match) )
    }
}

open class FileRegex {

    let filepath: String
    let contents: NSMutableString

    public static func load( path: String ) throws -> NSMutableString {
        return try NSMutableString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue)
    }

    public static func save( path: String, contents: NSString ) {
        do {
            try contents.write(toFile: path, atomically: false, encoding: String.Encoding.utf8.rawValue)
        }
        catch (let e as NSError) {
            print("FileRegex: Error writing to \(path): \(e)")
        }
    }

    public init( path: String ) throws {
        filepath = path
        contents = try FileRegex.load(path: path)
    }

    open subscript( pattern: String ) -> MutableRegex {
        let regex = MutableRegex( target: contents, pattern: pattern )
        regex.fileRegex = self // retains until after substitution
        return regex
    }

    open func update() {
        FileRegex.save( path: filepath, contents: contents )
    }

}
