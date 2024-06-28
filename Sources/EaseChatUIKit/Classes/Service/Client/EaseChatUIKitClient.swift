import Foundation

public let EaseChatUIKit_VERSION = "4.7.0"

@objcMembers public class EaseChatUIKitOptions: NSObject {
    
    /// The option of UI components.
    public var option_UI: UIOptions = UIOptions()
    
    /// The option of chat sdk function.
    public var option_chat: ChatOptions = ChatOptions()
    
    
}

@objcMembers final public class ChatOptions: ChatSDKOptions {
}

@objcMembers public class UIOptions: NSObject {
    
    
    /// Whether to store session avatars and nicknames in EaseChatUIKit.
    public var saveConversationInfo = true
    
    /// Whether to play a sound when new messages are received
    public var soundOnReceivedNewMessage = true
    
    /// Whether load messages from local database.
    public var loadLocalHistoryMessages = true
    
    /// Whether using contact list module.
    public var enableContact = true
}

@objcMembers public class EaseChatUIKitClient: NSObject {
        
    public static let shared = EaseChatUIKitClient()
    
    /// User-related protocol implementation class.
    public private(set) lazy var userService: UserServiceProtocol? = nil
    
    /// Options function wrapper.
    public var option: EaseChatUIKitOptions = EaseChatUIKitOptions()
    
    @UserDefault("EaseChatUIKit_contact_new_request", defaultValue: Dictionary<String,Array<Dictionary<String,Any>>>()) private var newFriends
    
    /// Initializes the ease chat UIKit.
    /// - Parameters:
    ///   - option: The unique identifier that Chat assigns to each app.``ChatOptions``
    /// Returns the initialization success or an error that includes the description of the cause of the failure.
    @objc(setupWithAppKey:option:)
    public func setup(appKey: String? = nil,option: ChatOptions? = nil) -> ChatError? {
        if let options = option {
            return ChatClient.shared().initializeSDK(with: options)
        } else {
            if let key = appKey {
                return ChatClient.shared().initializeSDK(with: ChatOptions(appkey: key))
            }
            return ChatError(description: "App key can't nil", code: .invalidAppkey)
        }
    }
    
    /// Login user.
    /// - Parameters:
    ///   - user: An instance that conforms to ``EaseProfileProtocol``.
    ///   - token: The user chat token.
    @objc(loginWithUser:token:completion:)
    public func login(user: EaseProfileProtocol,token: String,completion: @escaping (ChatError?) -> Void) {
        if EaseChatUIKitClient.shared.option.option_UI.enableContact {
            ChatClient.shared().contactManager?.add(self, delegateQueue: nil)
        }
        EaseChatUIKitContext.shared?.currentUser = user
        EaseChatUIKitContext.shared?.chatCache?[user.id] = user
        EaseChatUIKitContext.shared?.userCache?[user.id] = user
        self.userService = UserServiceImplement(userInfo: user, token: token, completion: completion)
    }
    
    /// Logout user
    @objc public func logout(unbindNotificationDeviceToken: Bool = false,completion: @escaping (ChatError?) -> Void) {
        UserDefaults.standard.removeObject(forKey: "EaseChatUIKit_contact_fetch_server_finished"+saveIdentifier)
        
        ChatClient.shared().logout(unbindNotificationDeviceToken) { error in
            completion(error)
        }
    }
    
    /// Register a user to listen for callbacks that monitor user status changes.
    /// - Parameter listener: ``UserStateChangedListener``
    @objc public func registerUserStateListener(_ listener: UserStateChangedListener) {
        if self.userService == nil {
            self.userService = UserServiceImplement()
        }
        self.userService?.bindUserStateChangedListener(listener: listener)
    }
    
    /// Remove monitoring of user status changes.
    /// - Parameter listener: ``UserStateChangedListener``
    @objc public func unregisterUserStateListener(_ listener: UserStateChangedListener) {
        self.userService?.unBindUserStateChangedListener(listener: listener)
    }
    
    /// unregister theme.
    @objc public func unregisterThemes() {
        Theme.unregisterSwitchThemeViews()
    }
    
    /// Updates user information that is used for login with the `login(with user: UserInfoProtocol,token: String,use userProperties: Bool = true,completion: @escaping (ChatError?) -> Void)` method.
    /// - Parameters:
    ///   - info: An instance that conforms to ``EaseProfileProtocol``.
    ///   - completion: Callback.
    @objc(updateWithUserInfo:completion:)
    public func updateUserInfo(info: EaseProfileProtocol,completion: @escaping (ChatError?) -> Void) {
        self.userService?.updateUserInfo(userInfo: info, completion: { success, error in
            completion(error)
        })
    }
    
    ///  Refreshes the user chat token when receiving the ``ChatClientListener.onUserTokenWillExpired`` callback.
    /// - Parameter token: The user chat token.
    @objc(refreshWithToken:)
    public func refreshToken(token: String) {
        ChatClient.shared().renewToken(token)
    }
}

extension EaseChatUIKitClient: ContactEventsListener {
    public func friendRequestDidReceive(fromUser aUsername: String, message aMessage: String?) {
        let requestInfo: [String:Any] = ["userId":aUsername,"timestamp":Date().timeIntervalSince1970*1000,"groupApply":0,"read":0]
        var exist = self.newFriends[saveIdentifier]
        if exist == nil {
            self.newFriends[saveIdentifier] = [requestInfo]
        } else {
            if exist?.first(where: { $0["userId"] as? String == aUsername }) == nil {
                exist?.append(requestInfo)
                self.newFriends[saveIdentifier] = exist
            }
        }
        if let index = Appearance.contact.listHeaderExtensionActions.firstIndex(where: { $0.featureIdentify == "NewFriendRequest" }) {
            let item = Appearance.contact.listHeaderExtensionActions[index]
            item.showBadge = true
            let unreadCount = self.newFriends[saveIdentifier]?.filter({ $0["read"] as? Int == 0 }).count ?? 0
            item.numberCount = UInt(unreadCount)
            Appearance.contact.listHeaderExtensionActions[index].numberCount = UInt(unreadCount)
        }
    }
}
