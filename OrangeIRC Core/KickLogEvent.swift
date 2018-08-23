//
//  KickLogEvent.swift
//  OrangeIRC
//
//  Created by Andrew Hyatt on 6/30/17.
//
//

import Foundation

/// When a user is kicked from a channel
public class KickLogEvent : ModerationLogEvent {
    
    /// Attributed description
    public override var attributedDescription: NSAttributedString {
        let str = NSMutableAttributedString()
        str.append(receiver.coloredName(for: room))
        str.append(NSAttributedString(string: " \(localized("WAS_KICKED_BY")) "))
        str.append(sender.coloredName(for: room))
        str.addAttributes(LogEvent.italicAttributes, range: NSRange(location: 0, length: str.length))
        return str
    }
    
}
