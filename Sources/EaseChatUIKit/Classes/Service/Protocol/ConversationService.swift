//
//  ChannelService.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/1.
//

import Foundation

@objc public protocol ConversationService: NSObjectProtocol {
    
    /// Bind channel changed listener
    /// - Parameter listener: ``ChannelServiceListener``
    func bindConversationEventsListener(listener: ConversationServiceListener)
    
    /// Unbind channel changed listener
    /// - Parameter listener: ``ChannelServiceListener``
    func unbindConversationEventsListener(listener: ConversationServiceListener)
    
    /// Register emergency listener
    /// - Parameter listener: ``ConversationEmergencyListener``
    func registerEmergencyListener(listener: ConversationEmergencyListener)
    
    /// Unregister emergency listener
    /// - Parameter listener: ``ConversationEmergencyListener``
    func unregisterEmergencyListener(listener: ConversationEmergencyListener)
    
    /// Get all conversations from database.
    func loadExistConversations()
    
    /// Get the session where the server is set to silent state
    /// - Parameters:
    ///   - conversationIds: `[String]`
    ///   - completion: Callback. If successful, the silent state corresponding to the session ID will be returned. If failed, the failure reason will be returned.
    func fetchSilentMode(conversationIds: [String],completion: @escaping (Dictionary<String,SilentModeResult>?,ChatError?) -> Void)
    
    /// Set a session to silent state
    /// - Parameters:
    ///   - conversationId: The id of the conversation.
    ///   - completion: Callback. If successful, the silent state corresponding to the session ID will be returned. If failed, the failure reason will be returned.
    func setSilentMode(conversationId: String,completion: @escaping (SilentModeResult?,ChatError?) -> Void)
    
    /// Clear the quiesce status of a session
    /// - Parameters:
    ///   - conversationId: The id of the conversation.
    ///   - completion: Callback. If successful, the silent state corresponding to the session ID will be returned. If failed, the failure reason will be returned.
    func clearSilentMode(conversationId: String,completion: @escaping (SilentModeResult?,ChatError?) -> Void)
    
    /// Fetch conversations from server.
    /// - Parameters:
    ///   - completion: Callback, including session list results and error information. If successful, the session list will be returned. If failed, error information will be returned.
    func fetchAllConversations(completion: ((CursorResult<ConversationInfo>?,ChatError?) -> Void)?)
    
    /// Fetch pinned conversations from server.
    /// - Parameters:
    ///   - cursor: Paging cursor.
    ///   - pageSize: The size number of current page.
    ///   - completion: Callback, including session list results and error information. If successful, the session list will be returned. If failed, error information will be returned.
    func fetchPinnedConversations(cursor: String, pageSize:UInt8, completion: @escaping (CursorResult<ConversationInfo>?,ChatError?) -> Void)
    
    /// Pin a conversation to the top
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - completion: Callback. If successful,error is empty. If failed, error information will be returned.
    func pin(conversationId: String,completion: @escaping (ChatError?) -> Void)
    
    /// Unpin a conversation.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - completion: Callback. If successful,error is empty. If failed, error information will be returned.
    func unpin(conversationId: String,completion: @escaping (ChatError?) -> Void)
    
    /// Delete a conversation exist in db&server.
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - completion: Callback. If successful,error is empty. If failed, error information will be returned.
    func deleteConversation(conversationId: String,completion: @escaping (ChatError?) -> Void)
    
    /// Mark all of the history messages as already read.
    func markAllMessagesAsRead(conversationId: String)
    
    /// Load a session and create one if it does not exist
    /// - Parameters:
    ///   - conversationId: The ID of the conversation.
    ///   - type: The ``ChatConversationType`` of the conversation.
    func loadIfNotExistCreate(conversationId: String,type: ChatConversationType) -> ChatConversation?
}

@objc public protocol ConversationServiceListener: NSObjectProtocol {
    
    /// When conversation list updated.
    /// - Parameter list: Array of session objects.
    func onChatConversationListDidChanged(list: [ConversationInfo])
    
    /// The read status of the conversation message changes.
    /// - Parameter info: The info of the conversation.
    func onConversationMessageAlreadyReadOnOtherDevice(info: ConversationInfo)
    
    /// The last message of conversation changes.
    /// - Parameters:
    ///   - message: ``ChatMessage``
    ///   - info: ``ConversationInfo``
    func onConversationLastMessageUpdate(message: ChatMessage,info: ConversationInfo)
}

@objc public enum ConversationEmergencyType: UInt8 {
    case pin
    case read
    case unpin
    case delete
    case setSilent
    case clearSilent
    case fetchSilent
    case fetchPinned
    case loadAllConversationFirstLoadUIKit
}

@objc public protocol ConversationEmergencyListener: NSObjectProtocol {
    
    /// You'll receive the result on conversation service request successful or failure.
    /// - Parameters:
    ///   - error: .Success ``ChatError`` is nil.
    ///   - type: ``ConversationEmergencyType``
    func onResult(error: ChatError?,type: ConversationEmergencyType)
    
    /// The last message of conversation changes.
    /// - Parameters:
    ///   - message: ``ChatMessage``
    ///   - info: ``ConversationInfo``
    func onConversationLastMessageUpdate(message: ChatMessage,info: ConversationInfo)
    
    /// You'll receive the result on some conversation last message update.
    /// - Parameter unreadCount: Total unread count.
    func onConversationsUnreadCountUpdate(unreadCount: UInt)
}
