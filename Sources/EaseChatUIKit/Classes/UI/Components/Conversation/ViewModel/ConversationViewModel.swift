//
//  ConversationViewModel.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/14.
//

import Foundation
import AudioToolbox


/// Bind service and driver
@objc open class ConversationViewModel: NSObject {
    
    /// Map to store session settings do not disturb.
    @UserDefault("EaseChatUIKit_conversation_mute_map", defaultValue: Dictionary<String,Dictionary<String,Int>>()) public private(set) var muteMap
    
    /// When conversation clicked.
    @objc public var toChat: ((IndexPath,ConversationInfo) -> Void)?
    
    @objc public var chatId = ""
    
    public required override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(loadExistLocalDataIfEmptyFetchServer), name: Notification.Name("New Friend Chat"), object: nil)
        NotificationCenter.default.addObserver(forName: Notification.Name(rawValue: "EaseChatUIKitContextUpdateCache"), object: nil, queue: .main) { [weak self] notify in
            guard let `self` = self else { return }
            if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                self.driver?.refreshList(infos: self.mapper(objects: infos))
            }
        }
        
        
        NotificationCenter.default.addObserver(forName: Notification.Name("EaseUIKit_do_not_disturb_changed"), object: nil, queue: .main) { [weak self] notify in
            if let userInfo = notify.userInfo {
                if let id = userInfo["id"] as? String {
                    if let doNotDisturb = userInfo["value"] as? Bool {
                        let info = ComponentsRegister.shared.Conversation.init()
                        info.id = id
                        self?.driver?.swipeMenuOperation(info: info, type: doNotDisturb == true ? .mute:.unmute)
                    }
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("EaseChatUIKitUnreadCountChanged"), object: nil, queue: .main) { _ in
            if let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(self.chatId), let info  = self.mapper(objects: [conversation]).first  {
                self.calculateUnreadCount(info: info)
            }

        }
    }
    
    public private(set) weak var driver: IConversationListDriver?
    
    public private(set) var service: ConversationServiceImplement? = ConversationServiceImplement()
    
    
    public private(set) var multiService: MultiDeviceService?  = MultiDeviceServiceImplement()
    
    /// Bind UI driver and service
    /// - Parameters:
    ///   - driver: The object of conform``IConversationListDriver``.
    @objc open func bind(driver: IConversationListDriver) {
        self.driver = driver
        self.service?.unbindConversationEventsListener(listener: self)
        self.service?.bindConversationEventsListener(listener: self)
        self.multiService?.unbindMultiDeviceListener(listener: self)
        self.multiService?.bindMultiDeviceListener(listener: self)
        self.driver?.addActionHandler(actionHandler: self)
        self.loadExistLocalDataIfEmptyFetchServer()
    }
    
    /// Register to monitor when certain emergencies occur
    /// - Parameter listener: ``ConversationEmergencyListener``
    @objc open func registerEventsListener(listener: ConversationEmergencyListener) {
        self.service?.unregisterEmergencyListener(listener: listener)
        self.service?.registerEmergencyListener(listener: listener)
    }
    
    /// When you don’t want to listen to the registered events above, you can use this method to clear the registration.
    /// - Parameter listener: ``ConversationEmergencyListener``
    @objc open func unregisterEventsListener(listener: ConversationEmergencyListener) {
        self.service?.unregisterEmergencyListener(listener: listener)
    }
    
    /// Load all sessions that exist locally. If they do not exist, load them from the server.
    @objc open func loadExistLocalDataIfEmptyFetchServer() {
        self.service?.loadExistConversations()
    }
    
    
    /// Load the session in the local database and create one if it does not exist
    /// - Parameters:
    ///   - profile: ``EaseProfileProtocol``
    ///   - text: Welcome message.
    /// - Returns: ``ConversationInfo`` object.
    @objc(loadIfNotExistCreateWithProfile:type:text:)
    open func loadIfNotExistCreate(profile: EaseProfileProtocol,type: ChatConversationType,text: String) -> ConversationInfo? {
        if let conversation = self.service?.loadIfNotExistCreate(conversationId: profile.id,type: type) {
            if let info = self.mapper(objects: [conversation]).first,!info.id.isEmpty {
                if conversation.type == .groupChat {
                    let content = "Group".chat.localize + " \(text) " + "has been created.".chat.localize
                    conversation.insert(self.welcomeMessage(conversationId: info.id,text: content), error: nil)
                }
                self.loadExistLocalDataIfEmptyFetchServer()
                return info
            }
            return nil
        }
        return nil
    }
    
    @objc open func welcomeMessage(conversationId: String,text: String) -> ChatMessage {
        ChatMessage(conversationID: conversationId, body: ChatCustomMessageBody(event: EaseChatUIKit_alert_message, customExt: nil), ext: text.isEmpty ? nil:["something":text])
    }
    
    @objc open func destroyed() {
        self.driver?.removeActionHandler(actionHandler: self)
        self.service?.unbindConversationEventsListener(listener: self)
        self.multiService?.unbindMultiDeviceListener(listener: self)
        self.driver = nil
        self.service = nil
        self.multiService = nil
    }
    
    deinit {
        destroyed()
    }
}

//MARK: - ConversationListActionEventsDelegate
extension ConversationViewModel: ConversationListActionEventsDelegate {
    
    public func onConversationListOccurErrorWhenFetchServer() {
        self.loadExistLocalDataIfEmptyFetchServer()
    }
    
    public func onConversationListEndScrollNeededDisplayInfos(ids: [String]) {
        self.requestDisplayProfiles(ids: ids)
    }
    
    @objc open func requestDisplayProfiles(ids: [String]) {
        var privateChats = [String]()
        var groupChats = [String]()
        for id in ids {
            if let conversation = ChatClient.shared().chatManager?.getConversationWithConvId(id) {
                if conversation.type == .chat {
                    privateChats.append(id)
                } else {
                    groupChats.append(id)
                }
            }
        }
        if EaseChatUIKitContext.shared?.userProfileProvider != nil {
            let userIds = privateChats.map { $0 }
            Task(priority: .background) { [weak self] in
                guard let `self` = self else { return }
                let profiles = await EaseChatUIKitContext.shared?.userProfileProvider?.fetchProfiles(profileIds: userIds) ?? []
                self.cacheUser(profiles: profiles)
                DispatchQueue.main.async {
                    self.renderDriver(infos: profiles)
                }
            }
        }
        if EaseChatUIKitContext.shared?.groupProfileProvider != nil {
            let groupIds = groupChats
            Task(priority: .background) { [weak self] in 
                guard let `self` = self else { return }
                let profiles = await EaseChatUIKitContext.shared?.groupProfileProvider?.fetchGroupProfiles(profileIds: groupIds) ?? []
                self.cacheGroup(profiles: profiles)
                DispatchQueue.main.async {
                    self.driver?.refreshProfiles(infos: profiles)
                }
            }
        }
        if EaseChatUIKitContext.shared?.userProfileProviderOC != nil {
            EaseChatUIKitContext.shared?.userProfileProviderOC?.fetchProfiles(profileIds: privateChats, completion: { [weak self] profiles in
                self?.cacheUser(profiles: profiles)
                DispatchQueue.main.async {
                    self?.driver?.refreshProfiles(infos: profiles)
                }
            })
        }
        if EaseChatUIKitContext.shared?.groupProfileProviderOC != nil {
            EaseChatUIKitContext.shared?.groupProfileProviderOC?.fetchGroupProfiles(profileIds: groupChats, completion: { [weak self] profiles in
                self?.cacheGroup(profiles: profiles)
                DispatchQueue.main.async {
                    self?.driver?.refreshProfiles(infos: profiles)
                }
            })
        }
        
    }
    
    @objc open func cacheUser(profiles: [EaseProfileProtocol]) {
        for profile in profiles {
            EaseChatUIKitContext.shared?.userCache?[profile.id]?.nickname = profile.nickname
            EaseChatUIKitContext.shared?.userCache?[profile.id]?.remark = profile.remark
            EaseChatUIKitContext.shared?.userCache?[profile.id]?.avatarURL = profile.avatarURL
        }
    }
    
    @objc open func cacheGroup(profiles: [EaseProfileProtocol]) {
        for profile in profiles {
            EaseChatUIKitContext.shared?.groupCache?[profile.id]?.nickname = profile.nickname
            EaseChatUIKitContext.shared?.groupCache?[profile.id]?.avatarURL = profile.avatarURL
            EaseChatUIKitContext.shared?.groupCache?[profile.id]?.remark = profile.remark
        }
    }
    
    @objc open func renderDriver(infos: [EaseProfileProtocol]) {
        self.driver?.refreshProfiles(infos: infos)
    }
    
    public func onConversationListRefresh() {
        if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
            self.driver?.refreshList(infos: self.mapper(objects: infos))
        }
    }
    
    @objc open func pin(info: ConversationInfo) {
        self.service?.pin(conversationId: info.id) { [weak self] error in
            guard let `self` = self else { return }
            if error != nil {
                consoleLogInfo("onConversationSwipe pin:\(error?.errorDescription ?? "")", type: .error)
            } else {
                if let idx = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .pin }) {
                    Appearance.conversation.swipeLeftActions[idx] = .unpin
                }
                if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                    self.driver?.refreshList(infos: self.mapper(objects: infos))
                }
            }
        }
    }
    
    @objc open func unpin(info: ConversationInfo) {
        self.service?.unpin(conversationId: info.id) { [weak self] error in
            guard let `self` = self else { return }
            if error != nil {
                consoleLogInfo("onConversationSwipe unpin:\(error?.errorDescription ?? "")", type: .error)
            } else {
                if let idx = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .unpin }) {
                    Appearance.conversation.swipeLeftActions[idx] = .pin
                }
                if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                    self.driver?.refreshList(infos: self.mapper(objects: infos))
                }
            }
        }
    }
    
    @objc open func mute(info: ConversationInfo) {
        self.service?.setSilentMode(conversationId: info.id) { [weak self] _, error in
            if error != nil {
                consoleLogInfo("onConversationSwipe mute:\(error?.errorDescription ?? "")", type: .error)
            } else {
                let currentUser = EaseChatUIKitContext.shared?.currentUserId ?? ""
                var conversationMap = self?.muteMap[currentUser]
                if conversationMap != nil {
                    conversationMap?[info.id] = 1
                } else {
                    conversationMap = [info.id:1]
                }
                self?.muteMap[currentUser] = conversationMap
                self?.driver?.swipeMenuOperation(info: info, type: .mute)
            }
        }
    }
    
    @objc open func delete(info: ConversationInfo) {
        self.service?.deleteConversation(conversationId: info.id) { [weak self] error in
            guard let `self` = self else { return }
                if error != nil {
                    consoleLogInfo("onConversationSwipe delete:\(error?.errorDescription ?? "")", type: .error)
                } else {
                    if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                        self.driver?.refreshList(infos: self.mapper(objects: infos))
                    }
                }
            }
    }
    
    @objc open func unmute(info: ConversationInfo) {
        self.service?.clearSilentMode(conversationId: info.id) { [weak self] _, error in
            if error != nil {
                consoleLogInfo("onConversationSwipe unmute:\(error?.errorDescription ?? "")", type: .error)
            } else {
                let currentUser = EaseChatUIKitContext.shared?.currentUserId ?? ""
                var conversationMap = self?.muteMap[currentUser]
                if conversationMap != nil {
                    conversationMap?[info.id] = 0
                } else {
                    conversationMap = [info.id:0]
                }
                self?.muteMap[currentUser] = conversationMap
                self?.driver?.swipeMenuOperation(info: info, type: .unmute)
            }
        }
    }
    
    @objc open func read(info: ConversationInfo) {
        info.unreadCount = 0
        self.driver?.swipeMenuOperation(info: info, type: .read)
        self.service?.markAllMessagesAsRead(conversationId: info.id)
    }
    
    public func onConversationSwipe(type: UIContextualActionType, info: ConversationInfo) {
        if let hooker = ComponentViewsActionHooker.shared.conversation.swipeAction {
            hooker(type, info)
        } else {
            switch type {
            case .pin: self.pin(info: info)
            case .unpin: self.unpin(info: info)
            case .mute: self.mute(info: info)
            case .unmute: self.unmute(info: info)
            case .delete: self.delete(info: info)
            case .read: self.read(info: info)
            case .more: self.moreAction(info: info)
            }
        }
    }
    
    public func onConversationDidSelected(indexPath: IndexPath, info: ConversationInfo) {
        self.conversationDidSelected(indexPath: indexPath, info: info)
    }
    
    @objc open func conversationDidSelected(indexPath: IndexPath, info: ConversationInfo) {
        self.chatId = info.id
        self.service?.markAllMessagesAsRead(conversationId: info.id)
        ChatClient.shared().chatManager?.ackConversationRead(info.id)
        self.driver?.swipeMenuOperation(info: info, type: .read)
        self.toChat?(indexPath,info)
        if let conversationService = self.service {
            if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                let items = self.mapper(objects: infos)
                var count = UInt(0)
                for item in items where item.doNotDisturb == false {
                    count += item.unreadCount
                }
                conversationService.notifyUnreadCount(count: count)
            }

        }
        
    }
    
    public func onConversationLongPressed(indexPath: IndexPath, info: ConversationInfo) {
        if let hooker = ComponentViewsActionHooker.shared.conversation.longPressed {
            hooker(indexPath,info)
        } else {
            consoleLogInfo("onConversationLongPressed", type: .debug)
            self.conversationLongPressed(indexPath: indexPath, info: info)
        }
    }
    
    @objc open func conversationLongPressed(indexPath: IndexPath, info: ConversationInfo) {
    }
    
    @objc open func moreAction(info: ConversationInfo) {
        DialogManager.shared.showMessageActions(actions: Appearance.conversation.moreActions) { item  in
            //According to item tag
/// -            switch item.tag {
/// -            case "xxx":
/// -            default: break
/// -            }
            item.action?(item,info)
        }
    }
}


//MARK: - ConversationServiceListener
extension ConversationViewModel: ConversationServiceListener {
    public func onConversationLastMessageUpdate(message: ChatMessage, info: ConversationInfo) {
        self.conversationLastMessageUpdate(message: message, info: info)
    }
    
    @objc open func conversationLastMessageUpdate(message: ChatMessage, info: ConversationInfo) {
        self.calculateUnreadCount(info: info)
    }
    
    @objc open func calculateUnreadCount(info: ConversationInfo) {
        if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
            let items = self.mapper(objects: infos)
            var count = UInt(0)
            for item in items where item.doNotDisturb == false {
                count += item.unreadCount
            }
            self.service?.notifyUnreadCount(count: count)
            self.driver?.refreshList(infos: items)
            if !info.doNotDisturb,EaseChatUIKitClient.shared.option.option_UI.soundOnReceivedNewMessage,UIApplication.shared.applicationState == .active,self.chatId != info.id {
                self.playNewMessageSound()
            }
        }
    }
    
    @objc open func playNewMessageSound() {
        let audioPath = NSURL(fileURLWithPath: Appearance.chat.newMessageSoundPath)
        var soundID: SystemSoundID = 0
        let completion: @convention(c) (SystemSoundID, UnsafeMutableRawPointer?) -> Void = { soundId, pointer in
            AudioServicesDisposeSystemSoundID(soundId)
            }
        AudioServicesCreateSystemSoundID(audioPath, &soundID) // Register the sound completion callback.
        AudioServicesAddSystemSoundCompletion(soundID, nil, nil, completion, nil)
    }
    
    
    public func onChatConversationListDidChanged(list: [ConversationInfo]) {
        self.driver?.refreshList(infos: list)
        if list.count < 10 {
            self.requestDisplayProfiles(ids: list.map({ $0.id }))
        }
    }
    
    public func onConversationMessageAlreadyReadOnOtherDevice(info: ConversationInfo) {
        self.conversationMessageAlreadyReadOnOtherDevice(info: info)
    }
    
    @objc open func conversationMessageAlreadyReadOnOtherDevice(info: ConversationInfo) {
        info.unreadCount = 0
        self.service?.markAllMessagesAsRead(conversationId: info.id)
        self.driver?.swipeMenuOperation(info: info, type: .read)
    }
}

//MARK: - MultiDeviceListener
extension ConversationViewModel: MultiDeviceListener {
    public func onConversationEventDidChanged(event: MultiDeviceEvent, conversationId: String, conversationType: ChatConversationType) {
        self.conversationEventDidChanged(event: event, conversationId: conversationId, conversationType: conversationType)
    }
    
    @objc open func conversationEventDidChanged(event: MultiDeviceEvent, conversationId: String, conversationType: ChatConversationType) {
        switch event {
        case .conversationPinned,.conversationUnpinned:
            if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                self.driver?.refreshList(infos: self.mapper(objects: infos))
                self.service?.handleResult(error: nil, type: event == .conversationPinned ? .pin:.unpin)
            }
        case .conversationDelete:
            if let infos = ChatClient.shared().chatManager?.getAllConversations(true) {
                if let info = self.mapper(objects: infos).first(where: { $0.id == conversationId }) {
                    self.driver?.swipeMenuOperation(info: info, type: .delete)
                    self.service?.handleResult(error: nil, type: .delete)
                }
            }
            
        default: break
        }
    }
    
    
    @objc open func mapper(objects: [ChatConversation]) -> [ConversationInfo] {
        objects.map {
            let conversation = ComponentsRegister.shared.Conversation.init()
            conversation.id = $0.conversationId
            var nickname = ""
            var profile: EaseProfileProtocol?
            if $0.type == .chat {
                profile = EaseChatUIKitContext.shared?.userCache?[$0.conversationId]
            } else {
                profile = EaseChatUIKitContext.shared?.groupCache?[$0.conversationId]
                if EaseChatUIKitContext.shared?.groupProfileProvider == nil,EaseChatUIKitContext.shared?.groupProfileProviderOC == nil {
                    profile?.nickname = ChatGroup(id: $0.conversationId).groupName ?? ""
                }
            }
            if nickname.isEmpty {
                nickname = profile?.remark ?? ""
            }
            if nickname.isEmpty {
                nickname = profile?.nickname ?? ""
            }
            if nickname.isEmpty {
                nickname = $0.conversationId
            }
            conversation.unreadCount = UInt($0.unreadMessagesCount)
            conversation.lastMessage = $0.latestMessage
            conversation.type = EaseProfileProviderType(rawValue: UInt($0.type.rawValue)) ?? .chat
            conversation.pinned = $0.isPinned
            conversation.nickname = profile?.nickname ?? ""
            conversation.remark = profile?.remark ?? ""
            conversation.avatarURL = profile?.avatarURL ?? ""
            conversation.doNotDisturb = false
            if let silentMode = self.muteMap[EaseChatUIKitContext.shared?.currentUserId ?? ""]?[$0.conversationId] {
                conversation.doNotDisturb = silentMode != 0
            }
            
            _ = conversation.showContent
            return conversation
        }
    }
}
