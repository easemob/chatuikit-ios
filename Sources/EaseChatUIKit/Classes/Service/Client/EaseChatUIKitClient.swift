import Foundation

@objcMembers public class EaseChatUIKitOptions: NSObject {
    
    /// The option of UI components.
    public var option_UI: UIOptions = UIOptions()
    
    /// The option of chat sdk function.
    public var option_chat: ChatOptions = ChatOptions()
    
    
}

@objcMembers public class ChatOptions: ChatSDKOptions {
    
    /// Whether to store session avatars and nicknames in EaseChatUIKit.
    var saveConversationInfo = true
    
    /// Whether to play a sound when new messages are received
    var soundOnReceivedNewMessage = true
    
    /// Whether load messages from local database.
    var loadLocalHistoryMessages = true
}

@objcMembers public class UIOptions: NSObject {
    
}

@objcMembers public class EaseChatUIKitClient: NSObject {
        
    public static let shared = EaseChatUIKitClient()
    
    /// User-related protocol implementation class.
    public private(set) lazy var userService: UserServiceProtocol? = nil
    
    /// Options function wrapper.
    public private(set) lazy var option: EaseChatUIKitOptions = EaseChatUIKitOptions()
    
    /// Initializes the chat room UIKit.
    /// - Parameters:
    ///   - appKey: The unique identifier that Chat assigns to each app.
    /// Returns the initialization success or an error that includes the description of the cause of the failure.
    @objc(setupWithAppkey:option:)
    public func setup(appKey: String,option: ChatOptions = ChatOptions()) -> ChatError? {
        let option = ChatOptions(appkey: appKey)
        option.enableConsoleLog = true
        option.isAutoLogin = false
        option.deleteMessagesOnLeaveGroup = false
        return ChatClient.shared().initializeSDK(with: option)
    }
    
    /// Login user.
    /// - Parameters:
    ///   - user: An instance that conforms to ``EaseProfileProtocol``.
    ///   - token: The user chat token.
    @objc(loginWithUser:token:completion:)
    public func login(user: EaseProfileProtocol,token: String,completion: @escaping (ChatError?) -> Void) {
        EaseChatUIKitContext.shared?.currentUser = user
        EaseChatUIKitContext.shared?.chatCache?[user.id] = user
        self.userService = UserServiceImplement(userInfo: user, token: token, completion: completion)
    }
    
    /// Logout user
    @objc public func logout() {
        self.userService?.logout(completion: { _, _ in })
    }
    
    /// Register a user to listen for callbacks that monitor user status changes.
    /// - Parameter listener: ``UserStateChangedListener``
    @objc public func registerUserStateListener(_ listener: UserStateChangedListener) {
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
    
    /// Registers a chat room event listener.
    /// - Parameter listener: ``UserStateChangedListener``
    @objc(registerWithUserEventsListener:)
    public func registerUserEventsListener(_ listener: UserStateChangedListener) {
        self.userService?.unBindUserStateChangedListener(listener: listener)
        self.userService?.bindUserStateChangedListener(listener: listener)
    }
    
    /// Unregisters a chat room event listener.
    /// - Parameter listener: ``UserStateChangedListener``
    @objc(unregisterWithUserEventsListener:)
    public func unregisterUserEventsListener(_ listener: UserStateChangedListener) {
        self.userService?.unBindUserStateChangedListener(listener: listener)
    }
    
    ///  Refreshes the user chat token when receiving the ``ChatClientListener.onUserTokenWillExpired`` callback.
    /// - Parameter token: The user chat token.
    @objc(refreshWithToken:)
    public func refreshToken(token: String) {
        ChatClient.shared().renewToken(token)
    }
}

