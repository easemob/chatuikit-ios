//
//  ChatService.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/1.
//

import Foundation


/// The status of ``ChatMessage``.
@objc public enum ChatMessageStatus: UInt {
    case sending
    case succeed
    case failure
    case delivered
    case read
}


public let EaseChatUIKit_alert_message = "chatUIKit_alert_message"

public let EaseChatUIKit_user_card_message = "userCard"

@objc public protocol ChatService: NSObjectProtocol {
    
    /// Bind message changed listener
    /// - Parameter listener: ``ChatResponseListener``
    func bindChatEventsListener(listener: ChatResponseListener)
    
    /// Unbind message changed listener
    /// - Parameter listener: ``ChatResponseListener``
    func unbindChatEventsListener(listener: ChatResponseListener)
    
    /// Send message to someone.
    /// - Parameters:
    ///   - body: ``ChatMessage``
    ///   - completion: Callback, returns message if successful, returns error if failed
    func send(message: ChatMessage,completion: @escaping (ChatError?,ChatMessage?) -> Void)
    
    /// Edit text message content.
    /// - Parameters:
    ///   - messageId: ID of the message.
    ///   - text: Replacement king of ``String``.
    ///   - completion: Callback, returns message if successful, returns error if failed
    func edit(messageId: String,text: String,completion: @escaping (ChatError?,ChatMessage?) -> Void)
    
    /// Recall a message succeed.
    /// - Parameters:
    ///   - messageId: ID of the message.
    ///   - completion: Callback, returns message if successful, returns error if failed
    func recall(messageId: String,completion: @escaping (ChatError?) -> Void)

    /// Remove a message from database.
    /// - Parameter messageId: The id of the message.
    func removeLocalMessage(messageId: String)
    
    /// Remove all of the history messages from database.
    func removeHistoryMessages()
    
    /// Mark a message as already read state.
    /// - Parameter messageId: The id of the message.
    func markMessageAsRead(messageId: String)
    
    /// Mark all of the history messages as already read.
    func markAllMessagesAsRead()
    
    /// Load messages from database.
    /// - Parameters:
    ///   - messageId: The start id of the message.
    ///   - pageSize: The size number.
    ///   - completion: Request a callback, returning an array of message objects if successful, or an error if failed
    func loadMessages(start messageId: String,pageSize: UInt,searchMessage: Bool,completion: @escaping (ChatError?,[ChatMessage]) -> Void)
    
    /// Load messages from server.
    /// - Parameters:
    ///   - conversationId: The id of the ChatThread.
    ///   - messageId: The start id of the message.
    ///   - pageSize: The size number.
    ///   - completion: Request a callback, returning an array of message objects if successful, or an error if failed
    func fetchChatThreadHistoryMessages(conversationId: String, start messageId: String, pageSize: UInt, completion: @escaping (ChatError?,[ChatMessage]) -> Void)
    
    
    /// Search message from database.
    /// - Parameters:
    ///   - keyword: Search keyword.
    ///   - pageSize: The size number.
    ///   - userId: The id of the user.
    ///   - completion: Request a callback, returning an array of message objects if successful, or an error if failed
    func searchMessage(keyword: String,pageSize: UInt,userId: String,completion: @escaping (ChatError?,[ChatMessage]) -> Void)
    
    /// Translate the message text.
    /// - Parameters:
    ///   - message: ``ChatMessage``
    ///   - completion: Request a callback, returning an array of message objects if successful, or an error if failed
    func translateMessage(message: ChatMessage,completion: @escaping (ChatError?,ChatMessage?) -> Void)
    
    /// Operation reaction api.
    /// - Parameters:
    ///   - reaction: ``String``
    ///   - message: ``ChatMessage``
    ///   - completion: Callback, returns error whether successful error is `nil`, or error occur.
    func reaction(reaction: String, message: ChatMessage, completion: @escaping (ChatError?) -> Void)
    
    /// Stickied a message on top.
    /// - Parameters:
    ///   - messageId: ID of the message.
    ///   - completion: Callback, returns error whether successful error is `nil`, or error occur.
    func pinMessage(messageId: String, completion: @escaping (ChatError?) -> Void)
    
    /// Remove the stickied message.
    /// - Parameters:
    ///   - messageId: ID of the message.
    ///   - completion: Callback, returns error whether successful error is `nil`, or error occur.
    func unpinMessage(messageId: String, completion: @escaping (ChatError?) -> Void)
    
    /// Get all of the stickied messages.
    /// - Parameters:
    ///   - conversationId: ID of the conversation.
    ///   - completion: Callback, returns an array of message objects if successful, or an error if failed
    func pinnedMessages(conversationId: String, completion: @escaping ([ChatMessage]?, ChatError?) -> Void)
}

@objc public protocol ChatResponseListener: NSObjectProtocol {
    
    /// When cmd message received.
    /// - Parameter message: ``ChatMessage``
    func onCMDMessageDidReceived(message: ChatMessage)
    
    /// When message received.
    /// - Parameter message: ``ChatMessage``
    func onMessageDidReceived(message: ChatMessage)
    
    /// When message recalled.
    /// - Parameter recallInfo: ``ChatMessage``
    func onMessageDidRecalled(recallInfo: RecallInfo)
    
    /// When message edited.
    /// - Parameter message: ``ChatMessage``
    func onMessageDidEdited(message: ChatMessage)
    
    /// When status of message changed.
    /// - Parameters:
    ///   - message: ``ChatMessage``
    ///   - status: ``ChatMessageStatus``
    ///   - error: ``ChatError``
    func onMessageStatusDidChanged(message: ChatMessage,status: ChatMessageStatus,error: ChatError?)
    
    /// When status of message attachment changed.
    /// - Parameters:
    ///   - message: ``ChatMessage``
    ///   - error: ``ChatError``
    func onMessageAttachmentStatusChanged(message: ChatMessage,error: ChatError?)
    
    /// When reaction of message changed.
    /// - Parameter changes: ``MessageReactionChange``
    func onMessageReactionChanged(changes: [MessageReactionChange])
    
    /// When message stickied top the method called.
    /// - Parameters:
    ///   - conversationId: ID of the conversation
    ///   - messageId: ID of the message.
    ///   - operation: ``MessagePinOperation``
    ///   - info: ``MessagePinInfo``
    func onMessageStickiedTop(conversationId: String, messageId: String, operation: MessagePinOperation, info: MessagePinInfo)
    
    /// Update messages read state on received channel ack.
    /// - Parameter conversationId: The ID of the conversation.
    func messagesAlreadyRead(conversationId: String)
}
