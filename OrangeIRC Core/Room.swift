//
//  Room.swift
//  OrangeIRC
//
//  Created by Andrew Hyatt on 7/3/16.
//
//

import Foundation

public class Room : NSObject, NSCoding {
    
    struct Coding {
        
        // To prevent this struct from being initialized
        private init() { }
        
        static let Name = "Name"
        // We can't call it Type, because that would be a keyword
        static let RoomType = "Type"
        static let AutoJoin = "AutoJoin"
        
    }
    
    
    // Preserved variables
    public var type: RoomType
    public var name: String
    public var autoJoin = false
    
    // Should be set by the AppDelegate when the room is loaded or created
    public var server: Server?
    
    public var log = [LogEvent]()
    
    public var users = [User]()
    
    public var topic: String?
    
    public var hasTopic = false
    
    public var isJoined = false
    
    
    // Set for the connect and join button
    public var joinOnConnect = false
    
    // Don't display the users list while it is still being populated
    public var hasCompleteUsersList = false
    
    public init(name: String, type: RoomType) {
        self.name = name
        self.type = type
        super.init()
    }
    
    public convenience init(name: String, type: RoomType, server: Server) {
        self.init(name: name, type: type)
        self.server = server
    }
    
    public required convenience init?(coder: NSCoder) {
        guard let name = coder.decodeObject(forKey: Coding.Name) as? String,
            let rawType = coder.decodeObject(forKey: Coding.RoomType) as? String else {
            return nil
        }
        
        guard let type = RoomType(rawValue: rawType) else {
            return nil
        }
        
        self.init(name: name, type: type)
        
        autoJoin = coder.decodeBool(forKey: Coding.AutoJoin)
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.name, forKey: Coding.Name)
        aCoder.encode(self.type.rawValue, forKey: Coding.RoomType)
        aCoder.encode(autoJoin, forKey: Coding.AutoJoin)
    }
    
    public func send(message: String) {
        // Splits the message up into 512 byte chunks
        var message = message
        var messageParts = [String]()
        let commandPrefix = "\(Command.PRIVMSG) \(self.name) :"
        let MAX = 510 - commandPrefix.utf8.count
        
        while !message.isEmpty {
            if message.utf8.count > MAX {
                let range = message.utf8.startIndex ..< message.utf8.index(message.utf8.startIndex, offsetBy: MAX)
                let part = message.utf8[range]
                messageParts.append(String(describing: part))
                
                // For some reason, we cant remove range in the UTF8View
                for _ in 0 ..< MAX {
                    _ = message.utf8.popFirst()
                }
            } else {
                let range = message.utf8.startIndex ..< message.utf8.endIndex
                let part = String(message.utf8[range])
                messageParts.append(part!)
                message = ""
            }
            
            for part in messageParts {
                server!.write(string: "\(commandPrefix)\(part)")
                guard let myUser = user(name: server!.nickname) else {
                    print("Failed to add a message we sent to the log")
                    continue
                }
                let logEvent = MessageLogEvent(contents: part, sender: myUser)
                log.append(logEvent)
                server!.delegate?.recieved(logEvent: logEvent, for: self)
            }
        }
    }
    
    func addUser(nick: String) {
        // Because they got rid of parameters being vars
        var vnick = nick
        let prefix = nick.substring(to: nick.index(after: nick.startIndex))
        
        var mode = User.Mode(rawValue: prefix)
        if mode == nil {
            mode = User.Mode.None
        } else {
            vnick.remove(at: nick.startIndex)
        }
        
        let user = User(name: vnick, mode: mode!)
        
        if user.name == server!.nickname {
            user.isSelf = true
        }
        
        let otherUser = self.user(name: user.name)
        if otherUser == nil {
            // So there are no duplicates added
            users.append(user)
        }
    }
    
    func user(name: String) -> User? {
        for user in users {
            if user.name == name {
                return user
            }
        }
        return nil
    }
    
}
