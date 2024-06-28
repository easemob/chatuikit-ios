//
//  ChatThreadViewModel.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/1/24.
//

import UIKit

@objc public enum ChatTopicOptions: UInt {
    case leave
    case destroy
    
}

@objcMembers open class ChatThreadViewModel: NSObject {
    
    public private(set) var to = ""
    
    public private(set) var chatThread: GroupChatThread?
        
    public private(set) weak var driver: IMessageListViewDriver?
    
    public private(set) var chatService: ChatService?
    
    public private(set) var groupService: GroupService? = GroupServiceImplement()
        
    public private(set) var multiService: MultiDeviceService? = MultiDeviceServiceImplement()
    
    var handlers: NSHashTable<MessageListDriverEventsListener> = NSHashTable<MessageListDriverEventsListener>.weakObjects()
    
    @objc public required init(chatThread: GroupChatThread?) {
        self.to = chatThread?.threadId ?? ""
        self.chatThread = chatThread
        self.chatService = ChatServiceImplement(to: self.to)
        super.init()
        self.chatService?.bindChatEventsListener(listener: self)
        self.multiService?.bindMultiDeviceListener(listener: self)
        self.groupService?.bindGroupChatThreadEventListener(listener: self)
        if let groupId = chatThread?.parentId {
            let group = ChatGroup(id: groupId)
            if group == nil || group?.owner.isEmpty ?? true {
                self.requestGroupDetail()
            }
        }
    }
    
    /// Bind ``IMessageListViewDriver``
    /// - Parameters:
    ///   - driver: ``IMessageListViewDriver``
    ///   - create: Whether to create a new thread
    @objc(bindWithDriver:create:)
    open func bindDriver(driver: IMessageListViewDriver,create: Bool) {
        self.driver = driver
        driver.addActionHandler(actionHandler: self)
        if create == false {
            self.loadMessages()
        } else {
            self.driver?.updateThreadLoadMessagesFinished(finished: true)
            self.threadCreateAlert()
        }
    }
    
    @objc open func threadCreateAlert() {
        let id = self.chatThread?.owner ?? ""
        let nickname = EaseChatUIKitContext.shared?.chatCache?[id]?.nickname ?? ""
        if let createMessage = self.constructMessage(text: "\(nickname)"+"CreateThreadAlert".chat.localize, type: .alert) {
            var threadMessages = self.driver?.dataSource ?? []
            createMessage.localTime = Int64(self.chatThread?.createAt ?? Int(Date().timeIntervalSince1970))
            createMessage.timestamp = Int64(self.chatThread?.createAt ?? Int(Date().timeIntervalSince1970))
            threadMessages.insert(createMessage, at: 0)
            self.driver?.refreshMessages(messages: threadMessages)
        }
    }
    
    /// Add events listener of the message list.
    /// - Parameter listener: ``MessageListDriverEventsListener``
    @objc public func addEventsListener(_ listener: MessageListDriverEventsListener) {
        if self.handlers.contains(listener) {
            return
        }
        self.handlers.add(listener)
    }
    
    /// Remove events listener of the message list.
    /// - Parameter listener: ``MessageListDriverEventsListener``
    @objc public func removeEventsListener(_ listener: MessageListDriverEventsListener) {
        if self.handlers.contains(listener) {
            self.handlers.remove(listener)
        }
    }
    
    open func requestGroupDetail() {
        ChatClient.shared().groupManager?.getGroupSpecificationFromServer(withId: self.chatThread?.parentId ?? "", completion: { group, error in
            if error == nil {
                
            } else {
                consoleLogInfo("requestGroupDetail error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    @objc open func loadMessages() {
        let firstMessageId = self.driver?.dataSource.last?.messageId ?? ""
        self.chatService?.fetchChatThreadHistoryMessages(conversationId: self.to, start: firstMessageId, pageSize: 20, completion: { [weak self] error, messages in
            if error == nil {
                if messages.count < 20 {
                    self?.driver?.updateThreadLoadMessagesFinished(finished: true)
                }
                if (self?.driver?.firstMessageId ?? "").isEmpty {
                    self?.driver?.refreshMessages(messages: messages)
                    if firstMessageId.isEmpty {
                        self?.threadCreateAlert()
                    }
                } else {
                    self?.driver?.insertMessages(messages: messages)
                }
            } else {
                consoleLogInfo("chat thread loadMessages error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }

    /// Send message with text&type&extension info.
    /// - Parameters:
    ///   - text: If it is a text message, this parameter is the text message content. If it is a location message, it is address,longitude&latitude save as extensionInfo. If it is a merged and forwarded message, it is the summary. If it is other messages, it is the path.
    ///   - type: ``MessageCellStyle``
    ///   - extensionInfo: Extended information to be carried in the message.
    @objc(sendMessageWithText:type:extensionInfo:)
    public func sendMessage(text: String,type: MessageCellStyle,extensionInfo: Dictionary<String,Any> = [:]) {
        if let message = self.constructMessage(text: text, type: type,extensionInfo: extensionInfo) {
            self.driver?.showMessage(message: message)
            self.chatService?.send(message: message) { [weak self] error, message in
                if error == nil {
                    if let message = message {
                        self?.driver?.updateMessageStatus(message: message, status: .succeed)
                    }
                } else {
                    consoleLogInfo("send text message failure:\(error?.errorDescription ?? "")", type: .error)
                    if let message = message {
                        self?.driver?.updateMessageStatus(message: message, status: .failure)
                    }
                }
            }
        }
    }
    
    open func sendFirstMessage(message: ChatMessage) {
        self.driver?.showMessage(message: message)
        self.chatService?.send(message: message) { [weak self] error, message in
            if error == nil {
                if let message = message {
                    self?.driver?.updateMessageStatus(message: message, status: .succeed)
                }
            } else {
                consoleLogInfo("send text message failure:\(error?.errorDescription ?? "")", type: .error)
                if let message = message {
                    self?.driver?.updateMessageStatus(message: message, status: .failure)
                }
            }
        }
    }
    
    @objc open func constructMessage(text: String,type: MessageCellStyle,extensionInfo: Dictionary<String,Any> = [:]) -> ChatMessage? {
        
        var ext = extensionInfo
        let json = EaseChatUIKitContext.shared?.currentUser?.toJsonObject() ?? [:]
        ext.merge(json) { _, new in
            new
        }
        var chatMessage = ChatMessage()
        switch type {
        case .text:
            chatMessage = ChatMessage(conversationID: self.to, body: ChatTextMessageBody(text: text), ext: ext)
        case .image:
            let displayName = text.components(separatedBy: "/").last ?? "\(Date().timeIntervalSince1970).jpeg"
            let imageBody = ChatImageMessageBody(localPath: text, displayName:  displayName.components(separatedBy: ".").count < 1 ? displayName+"jpeg":displayName)
            imageBody.size = UIImage(contentsOfFile: text)?.size ?? .zero
            chatMessage = ChatMessage(conversationID: self.to, body: imageBody, ext: ext)
        case .voice:
            let body = ChatAudioMessageBody(localPath: text, displayName: "\(Int(Date().timeIntervalSince1970*1000)).amr")
            if let duration = extensionInfo["duration"] as? Int {
                body.duration = Int32(duration)
            }
            chatMessage = ChatMessage(conversationID: self.to, body: body, ext: ext)
        case .video:
            let body = ChatVideoMessageBody(localPath: text, displayName: text.components(separatedBy: "/").last ?? "\(Date().timeIntervalSince1970).mp4")
            if let duration = extensionInfo["duration"] as? Int {
                body.duration = Int32(duration)
            }
            chatMessage = ChatMessage(conversationID: self.to, body: body, ext: ext)
        case .file:
            chatMessage = ChatMessage(conversationID: self.to, body: ChatFileMessageBody(localPath: text, displayName: text.components(separatedBy: "/").last ?? "\(Date().timeIntervalSince1970)"), ext: ext)
        case .contact:
            var ext = extensionInfo
            var customExt = [String:String]()
            if let userId =  extensionInfo["uid"] as? String {
                customExt["uid"] = userId
                ext.removeValue(forKey: "uid")
            }
            if let avatar =  extensionInfo["avatar"] as? String {
                customExt["avatar"] = avatar
                ext.removeValue(forKey: "avatar")
            }
            if let nickname =  extensionInfo["nickname"] as? String {
                customExt["nickname"] = nickname
                ext.removeValue(forKey: "nickname")
            }
            chatMessage = ChatMessage(conversationID: self.to, body: ChatCustomMessageBody(event: text, customExt: customExt), ext: ext)
        case .alert:
            ext["something"] = text
            chatMessage = ChatMessage(conversationID: self.to, body: ChatCustomMessageBody(event: EaseChatUIKit_alert_message, customExt: nil), ext: ext)
        case .combine:
            chatMessage = ChatMessage(conversationID: self.to, body: ChatCombineMessageBody(title: "[\("Chat History".chat.localize)]", summary: text, compatibleText: "Current version doesn't support.", messageIdList: []), ext: ext)
        case .location:
            var ext = extensionInfo
            var latitude: Double = 0
            var longitude: Double = 0
            if let value =  extensionInfo["latitude"] as? Double {
                latitude = value
                ext.removeValue(forKey: "latitude")
            }
            if let value =  extensionInfo["longitude"] as? Double {
                longitude = value
                ext.removeValue(forKey: "longitude")
            }
            chatMessage = ChatMessage(conversationID: self.to, body: ChatLocationMessageBody(latitude: latitude, longitude: longitude, address: text), ext: ext)
        default:
            break
        }
        chatMessage.chatType = .groupChat
        chatMessage.isChatThreadMessage = true
        return chatMessage
    }
    
    /// Call the corresponding method in ViewModel to handle the specified message.
    /// - Parameters:
    ///   - operation: ``MessageOperation``
    ///   - message: ``ChatMessage``
    ///   - text: Edit text to be passed when editing a message
    @objc(processMessageWithOperation:message:edieText:)
    open func processMessage(operation: MessageOperation,message: ChatMessage,edit text: String = "") {
        switch operation {
        case .edit: self.editMessage(message: message, content: text)
        case .copy: self.copyMessage(message: message)
        case .reply: self.replyMessage(message: message)
        case .recall: self.recallMessage(message: message)
        case .delete: self.deleteMessage(message: message)
        case .translate: self.translateMessage(message: message)
        case .originalText: self.showOriginalText(message: message)
        default: break
        }
    }
    
    @objc open func translateMessage(message: ChatMessage) {
        if message.translation == nil {
            self.chatService?.translateMessage(message: message, completion: { error, message in
                if error == nil,let raw = message {
                    self.driver?.processMessage(operation: .translate, message: raw)
                }
            })
        } else {
            self.driver?.processMessage(operation: .translate, message: message)
        }
    }
    
    @objc open func showOriginalText(message: ChatMessage) {
        self.driver?.processMessage(operation: .originalText, message: message)
    }
    
    @objc open func editMessage(message: ChatMessage,content: String = "") {
        self.chatService?.edit(messageId: message.messageId, text: content, completion: { [weak self] error, editMessage in
            if error == nil,let raw = editMessage {
                self?.driver?.processMessage(operation: .edit, message: raw)
            } else {
                consoleLogInfo("edit message error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    @objc open func copyMessage(message: ChatMessage) {
        self.driver?.processMessage(operation: .copy, message: message)
    }
    
    @objc open func replyMessage(message: ChatMessage) {
        self.driver?.processMessage(operation: .reply, message: message)
    }
    
    @objc open func recallMessage(message: ChatMessage) {
        self.chatService?.recall(messageId: message.messageId, completion: { [weak self] error in
            if error == nil {
                self?.recallAction(message: message)
            } else {
                consoleLogInfo("recall message error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    @objc open func recallAction(message: ChatMessage) {
        if let recall = self.constructMessage(text: "recalled a message".chat.localize, type: .alert, extensionInfo: [:]) {
            recall.messageId = message.messageId
            recall.timestamp = message.timestamp
            recall.from = message.from
            ChatClient.shared().chatManager?.getConversationWithConvId(message.conversationId)?.insert(recall, error: nil)
            self.driver?.processMessage(operation: .recall, message: recall)
        }
    }
    
    @objc open func deleteMessage(message: ChatMessage) {
        if let conversation = ChatClient.shared().chatManager?.getConversation(self.to, type: .groupChat, createIfNotExist: true, isThread: true) {
            ChatClient.shared().chatManager?.removeMessagesFromServer(with: conversation, messageIds: [message.messageId], completion: { [weak self] error in
                if error != nil {
                    consoleLogInfo("delete message error:\(error?.errorDescription ?? "")", type: .error)
                } else {
                    self?.driver?.processMessage(operation: .delete, message: message)
                }
            })
        }
        
    }
    
    open func operationTopic(option: ChatTopicOptions,completion: @escaping (Bool) -> Void) {
        switch option {
        case .leave: self.leaveChatTopic(completion: completion)
        case .destroy: self.destroyChatTopic(completion: completion)
        }
    }
    
    open func leaveChatTopic(completion: @escaping (Bool) -> Void) {
        ChatClient.shared().threadManager?.leaveChatThread(self.to, completion: { error in
            completion(error == nil)
            if error != nil {
                consoleLogInfo("leave chat topic error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    open func destroyChatTopic(completion: @escaping (Bool) -> Void) {
        ChatClient.shared().threadManager?.destroyChatThread(self.to, completion: { error in
            completion(error == nil)
            if error != nil {
                consoleLogInfo("destroy chat topic error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    open func deleteMessages(messages: [ChatMessage]) {
        
        if var dataSource = self.driver?.dataSource {
            let deleteIds = messages.map { $0.messageId }
            if let conversation = ChatClient.shared().chatManager?.getConversation(self.to, type: .groupChat, createIfNotExist: true, isThread: true) {
                ChatClient.shared().chatManager?.removeMessagesFromServer(with: conversation, messageIds: deleteIds,completion: { [weak self] error in
                    if error == nil {
                        for message in messages {
                            dataSource.removeAll(where: { $0.messageId == message.messageId })
                        }
                        self?.driver?.refreshMessages(messages: dataSource)
                    } else {
                        consoleLogInfo("delete topic messages error:\(error?.errorDescription ?? "")", type: .error)
                    }
                })
            }
            self.driver?.refreshMessages(messages: dataSource)
        }
    }
}

extension ChatThreadViewModel: MessageListViewActionEventsDelegate {
    public func onMessageListLoadMore() {
        self.loadMessages()
    }
    
    
    public func onMoreMessagesClicked() {
        ChatClient.shared().chatManager?.getConversationWithConvId(self.to)?.markAllMessages(asRead: nil)
//        ChatClient.shared().chatManager?.ackConversationRead(self.to)
    }
    
    public func onMessageMultiSelectBarClicked(operation: MessageMultiSelectedBottomBarOperation) {
        for handler in self.handlers.allObjects {
            handler.onMessageMultiSelectBarClicked(operation: operation)
        }
    }
    
    
    public func onMessageTopicClicked(entity: MessageEntity) {
        self.messageTopicClicked(entity: entity)
    }
    
    @objc open func messageTopicClicked(entity: MessageEntity) {
        
    }
    
    public func onMessageReactionClicked(reaction: MessageReaction?, entity: MessageEntity) {
        self.messageReactionClicked(reaction: reaction, entity: entity)
    }
    
    @objc open func messageReactionClicked(reaction: MessageReaction?, entity: MessageEntity) {
        if reaction == nil {
            //show reactions user list
            for handler in self.handlers.allObjects {
                handler.onMessageMoreReactionAreaClicked?(entity: entity)
            }
        
        } else {
            guard let reaction = reaction else { return }
            guard let emoji = reaction.reaction else { return }
            self.operationReaction(emoji: emoji, message: entity.message)
        }
    }
    
    @objc open func operationReaction(emoji: String,message: ChatMessage) {
        self.chatService?.reaction(reaction: emoji, message: message, completion: { error in
            if error == nil {
                self.driver?.reloadReaction(message: ChatClient.shared().chatManager?.getMessageWithMessageId(message.messageId) ?? message)
            } else {
                consoleLogInfo("reaction error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    
    public func onMessageVisible(entity: MessageEntity) {
        self.messageVisibleMark(entity: entity)
    }
    
    @objc open func messageVisibleMark(entity: MessageEntity) {
        let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(self.to)
        if !entity.message.isRead {
            if conversation?.type ?? .chat == .chat {
                switch entity.message.body.type {
                case .text,.location,.custom,.image:
                    conversation?.markMessageAsRead(withId: entity.message.messageId, error: nil)
//                    ChatClient.shared().chatManager?.sendMessageReadAck(entity.message.messageId, toUser: self.to)
                default:
                    break
                }
            }
        }
    }
    
    public func onFailureMessageRetrySend(entity: MessageEntity) {
        self.retrySendMessage(entity: entity)
    }
    
    @objc open func retrySendMessage(entity: MessageEntity) {
        self.driver?.updateMessageStatus(message: entity.message, status: .sending)
        self.chatService?.send(message: entity.message, completion: { error, message in
            if error == nil {
                self.driver?.updateMessageStatus(message: entity.message, status: .succeed)
            } else {
                self.driver?.updateMessageStatus(message: entity.message, status: .failure)
                consoleLogInfo("onFailureMessageRetrySend fail messageId:\(entity.message.messageId) error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    public func onMessageListPullRefresh() {
        self.loadMessages()
    }
    
    public func onMessageReplyClicked(message: MessageEntity) {
        
    }
        
    public func onMessageContentClicked(message: MessageEntity) {
        self.onMessageBubbleClicked(message: message)
    }
    
    @objc open func onMessageBubbleClicked(message: MessageEntity) {
        let bodyType = message.message.body.type
        
        if bodyType == .voice || bodyType == .file || bodyType == .video || bodyType == .combine || bodyType == .image {
            if !FileManager.default.fileExists(atPath: (message.message.body as? ChatFileMessageBody)?.localPath ?? "") {
                self.downloadMessageAttachment(message: message)
            } else {
                if bodyType != .voice {
                    for handler in self.handlers.allObjects {
                        handler.onMessageBubbleClicked(message: message)
                    }
                } else {
                    if bodyType == .voice {
                        self.driver?.stopAudioMessagesPlay()
                        self.audioMessagePlay(message: message)
                    }
                }
            }
        } else {
            for handler in self.handlers.allObjects {
                handler.onMessageBubbleClicked(message: message)
            }
        }
    }
    
    @objc open func audioMessagePlay(message: MessageEntity) {
        message.playing = !message.playing
        message.message.isListened = true
        let body = (message.message.body as? ChatAudioMessageBody)
        if let duration = body?.duration {
            if duration > 0 {
                if message.playing {
                    if let path = body?.localPath,FileManager.default.fileExists(atPath: path) {
                        if AudioTools.canPlay(url: URL(fileURLWithPath: path)) {
                            AudioTools.shared.stopPlaying()
                            self.driver?.updateAudioMessageStatus(message: message.message, play: true)
                            AudioTools.shared.playRecording(path: path) { [weak self] in
                                if let body = message.message.body as? ChatFileMessageBody {
                                    if body.localPath == $0 {
                                        self?.driver?.updateAudioMessageStatus(message: message.message, play: false)
                                    }
                                }
                            }
                        } else {
                            self.driver?.stopAudioMessagesPlay()
                            let tuple = MediaConvertor.convertAMRToWAV(url: URL(fileURLWithPath: path))
                            if tuple.0 != nil,tuple.1 != nil {
                                body?.localPath = tuple.1
                                ChatClient.shared().chatManager?.update(message.message)
                                self.audioMessagePlay(message: message)
                            }
                        }
                    }
                } else {
                    self.driver?.updateAudioMessageStatus(message: message.message, play: false)
                    AudioTools.shared.stopPlaying()
                }
            }
        }
        
        ChatClient.shared().chatManager?.update(message.message)
    }
    
    @objc open func downloadMessageAttachment(message: MessageEntity) {
        for handler in self.handlers.allObjects {
            handler.onMessageAttachmentLoading(loading: true)
        }
        ChatClient.shared().chatManager?.downloadMessageAttachment(message.message, progress: nil,completion: { [weak self] attachMessage, error in
            guard let `self` = self else { return }
            for handler in self.handlers.allObjects {
                handler.onMessageAttachmentLoading(loading: false)
            }
            if error == nil,let attachment = attachMessage {
                if attachment.body.type == .video {
                    self.cacheFrame(attachMessage: message.message)
                }
                if attachment.body.type == .voice {
                    self.driver?.stopAudioMessagesPlay()
                    self.audioMessagePlay(message: message)
                }
                if message.message.body.type == .image {
                    self.cacheImage(message: message.message)
                }
                message.message = attachment
                for handler in self.handlers.allObjects {
                    handler.onMessageBubbleClicked(message: message)
                }
            } else {
                consoleLogInfo("onMessageReplyClicked download error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    @objc open func cacheImage(message: ChatMessage) {
        if let body = (message.body as? ChatImageMessageBody) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: body.localPath))
                try FileManager.default.removeItem(atPath: body.localPath)
                let image = UIImage(data: data)
                if image?.imageOrientation == .up {
                    body.localPath += ".jpeg"
                } else {
                    body.localPath += ".png"
                }
                try data.write(to: URL(fileURLWithPath: body.localPath))
                ChatClient.shared().chatManager?.update(message)
            } catch {
                consoleLogInfo("download image then rewrite format path load error:\(error.localizedDescription)", type: .error)
            }
        }
    }
    
    @objc open func cacheFrame(attachMessage: ChatMessage) {
        if let body = attachMessage.body as? ChatVideoMessageBody {
            if let path = body.localPath {
                if var thumbnailLocalPath = path.components(separatedBy: ".").first,let type = path.components(separatedBy: ".").last {
                    thumbnailLocalPath = thumbnailLocalPath + "-thumbnail" + type
                    body.thumbnailLocalPath = thumbnailLocalPath
                    MediaConvertor.firstFrame(from: path) { image in
                        if let data = image?.pngData()  {
                            ChatClient.shared().chatManager?.update(attachMessage)
                            MediaConvertor.writeFile(to: thumbnailLocalPath, data: data)
                        }
                    }
                    
                }
            }
        }
    }
    
    public func onMessageContentLongPressed(message: MessageEntity) {
        for handler in self.handlers.allObjects {
            handler.onMessageBubbleLongPressed(message: message)
        }
    }
    
    public func onMessageAvatarClicked(profile: EaseProfileProtocol) {
        for handler in self.handlers.allObjects {
            handler.onMessageAvatarClicked(user: profile)
        }
    }
    
    public func onMessageAvatarLongPressed(profile: EaseProfileProtocol) {
        self.onMessageAvatarLongPressed(profile: profile)
    }
    
    @objc open func messageAvatarLongPressed(profile: EaseProfileProtocol) {
        
    }
    
    public func onInputBoxEventsOccur(action type: MessageInputBarActionType, attributeText: NSAttributedString?) {
        self.processInputEvents(action: type, attributeText: attributeText)
    }
    
    @objc open func processInputEvents(action type: MessageInputBarActionType, attributeText: NSAttributedString?) {
        switch type {
        case .send:
            if let attribute = attributeText {
                self.willSendMessage(attributeText: attribute)
            }
        default: break
        }
        
        for handler in self.handlers.allObjects {
            handler.onInputBoxEventsOccur(action: type, attributeText: attributeText)
        }
    }
    
    @objc open func willSendMessage(attributeText: NSAttributedString) {
        var mentionIds = [String]()
        let text = attributeText.toString()
        var extensionInfo = Dictionary<String,Any>()
        for handler in self.handlers.allObjects {
            extensionInfo.merge(handler.onMessageWillSendFillExtensionInfo()) { (current, _) in current
            }
        }
        attributeText.enumerateAttributes(in: NSRange(location: 0, length: attributeText.length), options: []) { (attributes, blockRange, stop) in
            let key = NSAttributedString.Key("mentionInfo")
            if let mentionInfo = attributes[key] as? EaseProfileProtocol {
                mentionIds.append(mentionInfo.id)
            }
        }
        if mentionIds.contains("All") {
            extensionInfo["em_at_list"] = "All"
        } else {
            extensionInfo["em_at_list"] = mentionIds
        }
        if let replyId = self.driver?.replyMessageId,let message = ChatClient.shared().chatManager?.getMessageWithMessageId(replyId) {
            let msgTypeDict: [ChatMessageBodyType: String] = [ .text: "txt", .image: "img", .video: "video", .voice: "audio", .custom: "custom", .cmd: "cmd", .file: "file", .location: "location", .combine: "combine" ]

            extensionInfo["msgQuote"] = [ "msgID": message.messageId, "msgPreview": message.showContent, "msgSender": message.from, "msgType": msgTypeDict[message.body.type] ?? "" ]
        }
        self.sendMessage(text: text, type: .text,extensionInfo: extensionInfo)
    }
}

extension ChatThreadViewModel: ChatResponseListener {
    public func onCMDMessageDidReceived(message: ChatMessage) {
        
    }
    
    public func onMessageStickiedTop(conversationId: String, messageId: String, operation: MessagePinOperation, info: MessagePinInfo) {
        
    }
    
    public func onMessageDidReceived(message: ChatMessage) {
        self.messageDidReceived(message: message)
    }
    
    /**
     Handles the received message and performs necessary actions based on the message type.
     
     - Parameters:
         - message: The received ChatMessage object.
     */
    @objc open func messageDidReceived(message: ChatMessage) {
        if message.conversationId == self.to {
            if let alreadyShow = self.driver?.dataSource.contains(where: { $0.messageId == message.messageId }),alreadyShow {
                return
            }
            if let dic = message.ext?["ease_chat_uikit_user_info"] as? Dictionary<String,Any> {
                let profile = EaseProfile()
                profile.setValuesForKeys(dic)
                profile.id = message.from
                profile.modifyTime = message.timestamp
                EaseChatUIKitContext.shared?.chatCache?[message.from] = profile
            }
            let entity = message
            entity.direction = message.direction
//            if let scrolledBottom = self.driver?.scrolledBottom,scrolledBottom {
//                let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(self.to)
//                conversation?.markMessageAsRead(withId: message.messageId, error: nil)
//                if conversation?.type ?? .chat == .chat {
//                    switch message.body.type {
//                    case .text,.location,.custom,.image:
//                        ChatClient.shared().chatManager?.sendMessageReadAck(message.messageId, toUser: self.to)
//                    default:
//                        break
//                    }
//                }
//            }
            self.driver?.showMessage(message: entity)
        }
    }
    
    public func onMessageDidRecalled(recallInfo: RecallInfo) {
        self.messageDidRecalled(recallInfo: recallInfo)
    }
    
    /**
     Handles the event when a message is recalled.
     
     - Parameters:
        - recallInfo: The recall information containing the recalled message.
     */
    @objc open func messageDidRecalled(recallInfo: RecallInfo) {
        if let recallMessage = recallInfo.recallMessage,recallMessage.conversationId == self.to {
            recallMessage.from = recallInfo.recallBy
            self.recallAction(message: recallMessage)
        } else {
            if let recall = self.constructMessage(text: "recalled a message".chat.localize, type: .alert, extensionInfo: [:]) {
                recall.messageId = recallInfo.recallMessageId
                recall.timestamp = Int64(Date().timeIntervalSince1970*1000)
                recall.from = recallInfo.recallBy
                self.driver?.processMessage(operation: .recall, message: recall)
            }
        }
    }
    
    public func onMessageDidEdited(message: ChatMessage) {
        if message.conversationId == self.to {
            self.messageDidEdited(message: message)
        }
    }
    
    /**
     Notifies the view model that a message has been edited.
     
     - Parameters:
        - message: The edited message.
     */
    @objc open func messageDidEdited(message: ChatMessage) {
        if message.conversationId == self.to {
            self.driver?.updateMessageAttachmentStatus(message: message)
        }
    }
    
    public func onMessageStatusDidChanged(message: ChatMessage, status: ChatMessageStatus, error: ChatError?) {
        self.messageStatusChanged(message: message, status: status, error: error)
    }
    
    /**
     Notifies the message list view model when the status of a chat message has changed.
     
     - Parameters:
        - message: The chat message whose status has changed.
        - status: The new status of the chat message.
        - error: An optional error associated with the status change.
     */
    @objc open func messageStatusChanged(message: ChatMessage, status: ChatMessageStatus, error: ChatError?) {
        if message.conversationId == self.to {
            self.driver?.updateMessageStatus(message: message, status: status)
        }
    }
    
    public func onMessageAttachmentStatusChanged(message: ChatMessage, error: ChatError?) {
        self.messageAttachmentStatusChanged(message: message, error: error)
    }
    
    /**
     Handles the change in attachment status of a chat message.
     
     - Parameters:
        - message: The chat message whose attachment status has changed.
        - error: An optional ChatError object indicating any error that occurred during the attachment status change.
     */
    @objc open func messageAttachmentStatusChanged(message: ChatMessage, error: ChatError?) {
        if message.conversationId == self.to {
            if error == nil {
                self.driver?.updateMessageAttachmentStatus(message: message)
            } else {
                consoleLogInfo("onMessageAttachmentStatusChanged error:\(error?.errorDescription ?? "")", type: .error)
            }
        }
    }
    
    public func onMessageReactionChanged(changes: [MessageReactionChange]) {
        self.messageReactionChanged(changes: changes)
    }
    
    @objc open func messageReactionChanged(changes: [MessageReactionChange]) {
        var messageIds = Set<String>()
        for change in changes {
            if let messageId = change.messageId,change.conversationId == self.to {
                messageIds.insert(messageId)
            }
        }
        for messageId in messageIds {
            if let message = ChatClient.shared().chatManager?.getMessageWithMessageId(messageId) {
                self.driver?.reloadReaction(message: message)
            }
        }
    }
    
    public func messagesAlreadyRead(conversationId: String) {
        self.driver?.readAllMessages()
    }
}

extension ChatThreadViewModel: GroupChatThreadEventListener {
    
    public func onGroupChatThreadEventOccur(type: GroupChatThreadEventType, event: GroupChatThreadEvent) {
        if self.to == event.chatThread.threadId {
            switch type {
            case .destroyed,.userKicked:
                for handler in self.handlers.allObjects {
                    handler.onUserQuitTopic?()
                }
            case .updated:
                for handler in self.handlers.allObjects {
                    handler.onChatThreadUpdated?(chatThread: event.chatThread)
                }
            default:
                break
            }
        }
    }
    
    public func onAttributesChangedOfGroupMember(groupId: String, userId: String, operatorId: String, attributes: Dictionary<String, String>) {
        
    }

}

extension ChatThreadViewModel: MultiDeviceListener {
    
    public func onGroupEventDidChanged(event: MultiDeviceEvent, groupId: String, users: [String]) {
        switch event {
        case .groupDestroy,.chatThreadKick,.chatThreadDestroy,.chatThreadLeave,.groupLeave:
            for handler in self.handlers.allObjects {
                handler.onUserQuitTopic?()
            }
        default:
            break
        }
    }
    
}
