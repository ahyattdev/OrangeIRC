//
//  Message.swift
//  OrangeIRC
//
//  Created by Andrew Hyatt on 7/2/16.
//
//

import Foundation

let SPACE = " "
let SLASH = "/"
let COLON = ":"
let EXCLAMATION_MARK = "!"
let AT_SYMBOL = "@"
let CARRIAGE_RETURN = "\r\n"
let EMPTY = ""

struct Message {
    
    enum MessageParseError: Error {
        case InvalidPrefix
        case InvalidMessage
    }
    
    struct Prefix {
        
        var prefix: String
        var servername: String?
        var nickname: String?
        var user: String?
        var host: String?
        
        init(_ string: String) throws {
            self.prefix = string
            
            if string.contains(EXCLAMATION_MARK) && string.contains(AT_SYMBOL) {
                // One of the msgto formats
                let exclamationMark = string.range(of: EXCLAMATION_MARK)!
                let atSymbol = string.range(of: AT_SYMBOL)!
                self.nickname = string.substring(to: exclamationMark.lowerBound)
                self.user = string.substring(with: exclamationMark.upperBound ..< atSymbol.lowerBound)
                self.host = string.substring(from: atSymbol.upperBound)
            } else {
                self.servername = prefix
            }
        }
        
    }
    
    var message: String
    var prefix: Prefix?
    var command: String
    var target: [String]
    var parameters: String?
    
    init(_ string: String) throws {
        
        var trimmedString = string.replacingOccurrences(of: CARRIAGE_RETURN, with: EMPTY)
        
        self.message = trimmedString
        
        if trimmedString[trimmedString.startIndex] == Character(COLON) {
            // There is a prefix, and we must handle and trim it
            let indexAfterColon = trimmedString.index(after: trimmedString.startIndex)
            let indexOfSpace = trimmedString.range(of: SPACE)!.lowerBound
            let prefixString = trimmedString[indexAfterColon ..< indexOfSpace]
            self.prefix = try Prefix(prefixString)
            // Trim off the prefix
            trimmedString = trimmedString.substring(from: trimmedString.index(after: indexOfSpace))
        }
        
        if let colonSpaceRange = trimmedString.range(of: " :") {
            // There are parameters
            let commandAndTargetString = trimmedString[trimmedString.startIndex ..< colonSpaceRange.lowerBound]
            // Space seperated array
            var commandAndTargetComponents = commandAndTargetString.components(separatedBy: " ")
            self.command = commandAndTargetComponents.remove(at: 0)
            self.target = commandAndTargetComponents
            
            // If this check if not performed, this code could crash if the last character of trimmedString is a colon
            if colonSpaceRange.upperBound != trimmedString.endIndex {
                var parametersStart = trimmedString.index(after: colonSpaceRange.upperBound)
                // Fixes a bug where the first character of the parameters is cut off
                parametersStart = trimmedString.index(before: parametersStart)
                self.parameters = trimmedString[parametersStart ..< trimmedString.endIndex]
            }
        } else {
            // There are no parameters
            var spaceSeperatedArray = trimmedString.components(separatedBy: " ")
            self.command = spaceSeperatedArray.remove(at: 0)
            self.target = spaceSeperatedArray
        }
    }
    
}
