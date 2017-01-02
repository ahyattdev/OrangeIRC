//
//  RoomViewController.swift
//  OrangeIRC
//
//  Created by Andrew Hyatt on 7/3/16.
//
//

import UIKit
import OrangeIRCCore

class RoomTableViewController : UITableViewController, MessageCellDelegate {
    
    let room: Room
    
    let composerButton = UIBarButtonItem(barButtonSystemItem: .compose, target: nil, action: #selector(showMessageComposer))
    let detailButton = UIBarButtonItem(title: NSLocalizedString("DETAILS", comment: "Details"), style: .plain, target: nil, action: #selector(showRoomInfo))
    
    private var heights = [CGFloat]()
    
    init(_ room: Room) {
        self.room = room
        
        super.init(style: .plain)
        
        // Can't use self before super.init, thanks Swift!
        composerButton.target = self
        detailButton.target = self
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItems = [detailButton, composerButton]
        
        updateButtons()
        
        NotificationCenter.default.addObserver(self, selector: #selector(roomDataChanged(_:)), name: Notifications.RoomDataDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadLog), name: Notifications.RoomLogDidChange, object: room)
        
        title = room.name
        navigationItem.prompt = room.server!.host
        
        let replyToSender = UIMenuItem(title: NSLocalizedString("REPLY", comment: ""), action: #selector(reply(sender:message:)))
        let replyToRecipient = UIMenuItem(title: NSLocalizedString("REPLY_TO_RECIPIENT", comment: ""), action: #selector(reply(recipient:message:)))
        
        UIMenuController.shared.menuItems = [replyToSender, replyToRecipient]
        UIMenuController.shared.update()
    }
    
    func roomDataChanged(_ notification: NSNotification) {
        updateButtons()
    }
    
    func updateButtons() {
        // Only enable the composer button when a message can be sent
        composerButton.isEnabled = room.server!.isRegistered && room.isJoined
        detailButton.isEnabled = true
    }
    
    func reloadLog() {
        // New messages are on the log, reload display
        tableView.reloadData()
        // Scroll to bottom
        tableView.scrollToRow(at: IndexPath(row: room.log.count - 1, section: 0), at: UITableViewScrollPosition.bottom, animated: true)
    }
    
    func showRoomInfo() {
        let roomInfoViewController = RoomInfoTableViewController(room)
        show(roomInfoViewController, sender: nil)
    }
    
    func showMessageComposer() {
        let composer = ComposerTableViewController(room: room, mode: .Composer)
        modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: composer), animated: true, completion: nil)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return room.log.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let logEvent = room.log[indexPath.row]
        
        
        if logEvent is UserLogEvent {
            let regularCell = UITableViewCell(style: .default, reuseIdentifier: nil)
            let userLogEvent = logEvent as! UserLogEvent
            
            var suffix = ""
            
            switch userLogEvent.self {
            case is UserJoinLogEvent:
                suffix = NSLocalizedString("JOINED_THE_ROOM", comment: "")
            case is UserPartLogEvent:
                suffix = NSLocalizedString("LEFT_THE_ROOM", comment: "")
            case is UserQuitLogEvent:
                suffix = NSLocalizedString("QUIT", comment: "")
            default:
                print("Unknown UserLogEvent, no caption found")
                break
            }
            
            let coloredName = userLogEvent.sender.coloredName(for: room)
            let attributedString = NSMutableAttributedString(attributedString: coloredName)
            // Spacer
            attributedString.append(NSAttributedString(string: " "))
            attributedString.append(NSAttributedString(string: suffix))
            regularCell.textLabel!.attributedText = attributedString
            
            return regularCell
            
        } else if let msgEvent = logEvent as? MessageLogEvent {
            let msgCell = MessageCell(message: msgEvent, room: room, showLabel: true)
            msgCell.delegate = self
            return msgCell
            
        } else {
            print("Unknown log event, could not be rendered")
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let event = room.log[indexPath.row]
        
        if let msgEvent = event as? MessageLogEvent {
            return TextViewCell.getHeight(msgEvent.contents, width: tableView.frame.width - 32, showLabel: true)
        } else {
            return super.tableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let event = room.log[indexPath.row]
        
        return event is MessageLogEvent
    }
    
    override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        let event = room.log[indexPath.row]
        
        if let msgEvent = event as? MessageLogEvent {
            if action == #selector(copy(_:)) || action == #selector(reply(sender:message:)){
                return true
            } else if action == #selector(reply(recipient:message:)), msgEvent.replyTo != nil {
                return true
            }
        }
        
        return false
    }
    
    override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if let msgEvent = room.log[indexPath.row] as? MessageLogEvent {
            
            switch action {
                
            case #selector(copy(_:)):
                let pasteBoard = UIPasteboard.general
                pasteBoard.string = msgEvent.contents
                
            case #selector(reply(sender:message:)):
                reply(sender: msgEvent.sender, message: msgEvent)
                
            case #selector(reply(recipient:message:)):
                reply(recipient: msgEvent.replyTo!, message: msgEvent)
                
            default:
                break
            }
            
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let event = room.log[indexPath.row]
        
        return event is MessageLogEvent
    }
    
    func reply(sender: User, message: MessageLogEvent) {
        let composer = ComposerTableViewController(message: message, room: room, mode: .ReplyToSender)
        modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: composer), animated: true, completion: nil)
    }
    
    func reply(recipient: User, message: MessageLogEvent) {
        let composer = ComposerTableViewController(message: message, room: room, mode: .ReplyToRecipient)
        modalPresentationStyle = .formSheet
        present(UINavigationController(rootViewController: composer), animated: true, completion: nil)
    }
    
    func showInfo(_ user: User) {
        
    }
}
