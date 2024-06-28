//
//  ChatServiceImplement.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/6.
//

import UIKit

@objcMembers public class ChatServiceImplement: NSObject {
    private var responseDelegates: NSHashTable<ChatResponseListener> = NSHashTable<ChatResponseListener>.weakObjects()
    
    public private(set) var to = ""
    
    @objc required public init(to: String) {
        super.init()
        self.to = to
        ChatClient.shared().chatManager?.add(self, delegateQueue: nil)
    }
    
    deinit {
        ChatClient.shared().chatManager?.remove(self)
    }
}

extension ChatServiceImplement: ChatService {
    public func fetchChatThreadHistoryMessages(conversationId: String, start messageId: String, pageSize: UInt, completion: @escaping (ChatError?, [ChatMessage]) -> Void) {
        ChatClient.shared().chatManager?.asyncFetchHistoryMessages(fromServer: conversationId, conversationType: .groupChat, startMessageId: messageId, fetch: .down, pageSize: Int32(pageSize), completion: { result, error in
            completion(error, result?.list ?? [])
        })
    }
    
    
    public func reaction(reaction: String, message: ChatMessage, completion: @escaping (ChatError?) -> Void) {
        let messageReaction = ChatClient.shared().chatManager?.getMessageWithMessageId(message.messageId)?.reactionList?.first(where: { $0.reaction ?? "" == reaction })
        if messageReaction == nil {
            ChatClient.shared().chatManager?.addReaction(reaction, toMessage: message.messageId, completion: { error in
                completion(error)
            })
        } else {
            if messageReaction!.isAddedBySelf {
                ChatClient.shared().chatManager?.removeReaction(reaction, fromMessage: message.messageId, completion: { error in
                    completion(error)
                })
            } else {
                ChatClient.shared().chatManager?.addReaction(reaction, toMessage: message.messageId, completion: { error in
                    completion(error)
                })
            }
        }
    }
    
    public func edit(messageId: String, text: String, completion: @escaping (ChatError?, ChatMessage?) -> Void) {
        let rawMessage = ChatClient.shared().chatManager?.getMessageWithMessageId(messageId)
        let body = ChatTextMessageBody(text: text)
        if let rawBody = rawMessage?.body as? ChatTextMessageBody {
            body.targetLanguages = rawBody.targetLanguages
        }
        ChatClient.shared().chatManager?.modifyMessage(messageId, body: body, completion: { error, message in
            completion(error,message)
        })
    }
    
    public func recall(messageId: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().chatManager?.recallMessage(withMessageId: messageId, completion: { error in
            completion(error)
        })
    }
    
    public func bindChatEventsListener(listener: ChatResponseListener) {
        if self.responseDelegates.contains(listener) {
            return
        }
        self.responseDelegates.add(listener)
    }
    
    public func unbindChatEventsListener(listener: ChatResponseListener) {
        if self.responseDelegates.contains(listener) {
            self.responseDelegates.remove(listener)
        }
    }
    
    public func send(message: ChatMessage, completion: @escaping (ChatError?, ChatMessage?) -> Void) {
        let message = message
        ChatClient.shared().chatManager?.send(message, progress: nil, completion: { [weak self] message, error in
//            self?.pushSendNotification(message: message)
            completion(error,message)
        })
    }
    
    private func pushSendNotification(message: ChatMessage?) {
        if let conversationId = message?.conversationId {
            NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_Conversation_last_message_need_update"), object: conversationId)
        }
    }
    
    public func removeLocalMessage(messageId: String) {
        ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.deleteMessage(withId: messageId, error: nil)
        
    }
    
    public func removeHistoryMessages() {
        ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.deleteAllMessages(nil)
    }
    
    public func markMessageAsRead(messageId: String) {
        ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.markMessageAsRead(withId: messageId, error: nil)
    }
    
    public func markAllMessagesAsRead() {
        ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.markAllMessages(asRead: nil)
    }
    
    public func loadMessages(start messageId: String, pageSize: UInt, searchMessage: Bool, completion: @escaping (ChatError?, [ChatMessage]) -> Void) {
        if EaseChatUIKitContext.shared?.chatCache == nil {
            EaseChatUIKitContext.shared?.chatCache = [String:EaseProfileProtocol]()
        }
        if EaseChatUIKitClient.shared.option.option_UI.loadLocalHistoryMessages {
            ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.loadMessagesStart(fromId: messageId, count: Int32(pageSize), searchDirection: searchMessage ? .down:.up,completion: { messages, error in
                if error == nil,let messages = messages {
                    for message in messages {
                        if let dic = message.ext?["ease_chat_uikit_user_info"] as? Dictionary<String,Any> {
                            if let user = EaseChatUIKitContext.shared?.chatCache?[message.from] as? EaseProfile,user.modifyTime < message.timestamp {
                                let user = EaseProfile()
                                user.setValuesForKeys(dic)
                                if user.id.isEmpty {
                                    user.id = message.from
                                }
                                user.modifyTime = message.timestamp
                                EaseChatUIKitContext.shared?.chatCache?[message.from] = user
                            } else {
                                let user = EaseProfile()
                                user.setValuesForKeys(dic)
                                if user.id.isEmpty {
                                    user.id = message.from
                                }
                                user.modifyTime = message.timestamp
                                EaseChatUIKitContext.shared?.chatCache?[message.from] = user
                            }
                        }
                        if let dic = message.ext?["ease_chat_uikit_text_url_preview"] as? Dictionary<String,String>,let url = dic["url"] {
                            let content = URLPreviewManager.HTMLContent()
                            if let description = dic["description"] {
                                content.descriptionHTML = description
                            }
                            if let imageURL = dic["imageUrl"] {
                                content.imageURL = imageURL
                            }
                            if let title = dic["title"] {
                                content.title = title
                                URLPreviewManager.caches[url] = content
                            }
                           
                        }
                    }
                }
                completion(error,messages ?? [])
            })
        } else {
            let type = ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.type ?? .chat
            ChatClient.shared().chatManager?.asyncFetchHistoryMessages(fromServer: self.to, conversationType: type, startMessageId: messageId, fetch: searchMessage ? .down:.up, pageSize: Int32(pageSize),completion: { result, error in
                if error == nil,let messages = result?.list {
                    for message in messages {
                        if let dic = message.ext?["ease_chat_uikit_user_info"] as? Dictionary<String,Any> {
                            if let user = EaseChatUIKitContext.shared?.chatCache?[message.from] as? EaseProfile,user.modifyTime < message.timestamp {
                                let user = EaseProfile()
                                user.setValuesForKeys(dic)
                                if user.id.isEmpty {
                                    user.id = message.from
                                }
                                user.modifyTime = message.timestamp
                                EaseChatUIKitContext.shared?.chatCache?[message.from] = user
                            } else {
                                let user = EaseProfile()
                                user.setValuesForKeys(dic)
                                if user.id.isEmpty {
                                    user.id = message.from
                                }
                                user.modifyTime = message.timestamp
                                EaseChatUIKitContext.shared?.chatCache?[message.from] = user
                            }
                        }
                    }
                }
                completion(error,result?.list ?? [])
            })
        }
    }
    
    public func searchMessage(keyword: String, pageSize: UInt, userId: String, completion: @escaping (ChatError?, [ChatMessage]) -> Void) {
        ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.loadMessages(withKeyword: keyword, timestamp: -1, count: Int32(pageSize), fromUser: userId, searchDirection: .up, scope: .content, completion: { messages, error in
            completion(error,messages ?? [])
        })
    }
    
    public func translateMessage(message: ChatMessage, completion: @escaping (ChatError?, ChatMessage?) -> Void) {
        ChatClient.shared().chatManager?.translate(message, targetLanguages: [Appearance.chat.targetLanguage.rawValue], completion: { message,error in
            completion(error,message)
        })
    }
    
    public func pinMessage(messageId: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().chatManager?.pinMessage(messageId, completion: { message,error in
            completion(error)
        })
    }
    
    public func unpinMessage(messageId: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().chatManager?.unpinMessage(messageId, completion: { message,error in
            completion(error)
        })
    }
    
    public func pinnedMessages(conversationId: String, completion: @escaping ([ChatMessage]?, ChatError?) -> Void) {
        ChatClient.shared().chatManager?.getPinnedMessages(fromServer: conversationId, completion: { messages, error in
            completion(messages,error)
        })
    }
}

extension ChatServiceImplement: ChatEventsListener {
    
    public func cmdMessagesDidReceive(_ aCmdMessages: [ChatMessage]) {
        for listener in self.responseDelegates.allObjects {
            for message in aCmdMessages {
                listener.onCMDMessageDidReceived(message: message)
            }
        }
    }
    
    public func onMessagePinChanged(_ messageId: String, conversationId: String, operation pinOperation: MessagePinOperation, pinInfo: MessagePinInfo) {
        for listener in self.responseDelegates.allObjects {
            listener.onMessageStickiedTop(conversationId: conversationId, messageId: messageId, operation: pinOperation, info: pinInfo)
        }
    }
    
    public func messagesDidReceive(_ aMessages: [ChatMessage]) {
        for listener in self.responseDelegates.allObjects {
            for message in aMessages {
                listener.onMessageDidReceived(message: message)
            }
        }
    }
    
    public func messagesInfoDidRecall(_ aRecallMessagesInfo: [RecallInfo]) {
        for listener in self.responseDelegates.allObjects {
            for info in aRecallMessagesInfo {
                listener.onMessageDidRecalled(recallInfo: info)
            }
        }
    }
    
    public func messageStatusDidChange(_ aMessage: ChatMessage, error aError: ChatError?) {
        for listener in self.responseDelegates.allObjects {
            listener.onMessageStatusDidChanged(message: aMessage, status: aError == nil ? .succeed:.failure, error: aError)
        }
    }
    
    public func messageAttachmentStatusDidChange(_ aMessage: ChatMessage, error aError: ChatError?) {
        for listener in self.responseDelegates.allObjects {
            listener.onMessageAttachmentStatusChanged(message: aMessage, error: aError)
        }
    }
    
    public func messageReactionDidChange(_ changes: [MessageReactionChange]) {
        for listener in self.responseDelegates.allObjects {
            listener.onMessageReactionChanged(changes: changes)
        }
    }
    
    public func messagesDidDeliver(_ aMessages: [ChatMessage]) {
        for aMessage in aMessages {
            for listener in self.responseDelegates.allObjects {
                listener.onMessageStatusDidChanged(message: aMessage, status: .delivered, error: nil)
            }
        }
    }
    
    public func messagesDidRead(_ aMessages: [ChatMessage]) {
        for aMessage in aMessages {
            for listener in self.responseDelegates.allObjects {
                listener.onMessageStatusDidChanged(message: aMessage, status: .read, error: nil)
            }
        }
    }
    
    public func onMessageContentChanged(_ message: ChatMessage, operatorId: String, operationTime: UInt) {
        for listener in self.responseDelegates.allObjects {
            listener.onMessageDidEdited(message: message)
        }
    }
    
    public func onConversationRead(_ from: String, to: String) {
        if EaseChatUIKitContext.shared?.currentUserId ?? "" != from {
            for listener in self.responseDelegates.allObjects {
                listener.messagesAlreadyRead(conversationId: from)
            }
        } else {
           //如果是多设备服务端会投递对方已读的状态给其他设备
        }
    }
    
}

