//
//  UserServiceImplement.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/8/30.
//

import UIKit

public var saveIdentifier: String {
    ChatClient.shared().options.appkey+(EaseChatUIKitContext.shared?.currentUserId ?? "")
}

@objc public final class UserServiceImplement: NSObject {
        
    private var responseDelegates: NSHashTable<UserStateChangedListener> = NSHashTable<UserStateChangedListener>.weakObjects()
    
    /// Init method
    /// - Parameters:
    ///   - userInfo: ``EaseProfileProtocol``
    ///   - token: Chat token
    ///   - completion: Callback,login successful or failure.
    @objc public init(userInfo: EaseProfileProtocol,token: String,completion: @escaping (ChatError?) -> Void) {
        super.init()
        self.registerEventListener()
        self.login(userId: userInfo.id.lowercased(), token: token) { success, error in
            if !success {
                let errorInfo = error?.errorDescription ?? ""
                consoleLogInfo(errorInfo, type: .error)
            }
            completion(error)
        }
    }
    
    @objc public override init() {
        super.init()
        self.registerEventListener()
    }
    
    @objc public func registerEventListener() {
        ChatClient.shared().add(self, delegateQueue: nil)
    }
    
    @objc public func removeEventListener() {
        ChatClient.shared().removeDelegate(self)
    }
    
    deinit {
        removeEventListener()
        consoleLogInfo("\(self.swiftClassName ?? "") deinit", type: .debug)
    }

}

extension UserServiceImplement:UserServiceProtocol {
    
    public func bindUserStateChangedListener(listener: UserStateChangedListener) {
        if self.responseDelegates.contains(listener) {
            return
        }
        self.responseDelegates.add(listener)
    }
    
    public func unBindUserStateChangedListener(listener: UserStateChangedListener) {
        if self.responseDelegates.contains(listener) {
            self.responseDelegates.remove(listener)
        }
    }
    
    public func userInfo(userId: String, completion: @escaping (EaseProfileProtocol?,ChatError?) -> Void) {
//        self.userInfos(userIds: [userId]) { infos,error in
//            completion(infos.first,error)
//        }
    }
    
    public func userInfos(userIds: [String], completion: @escaping ([EaseProfileProtocol],ChatError?) -> Void) {
//        ChatClient.shared().userInfoManager?.fetchUserInfo(byId: userIds,completion: { [weak self] infoMap, error in
//            guard let dic = infoMap as? Dictionary<String,UserInfo> else { return }
//            var users = [EaseProfile]()
//            for userId in userIds {
//                if let info = dic[userId] {
//                    if let user = self?.convertToUser(info: info) {
//                        users.append(user)
//                    }
//                }
//            }
//            completion(users,error)
//        })
    }
    
    public func updateUserInfo(userInfo: EaseProfileProtocol, completion: @escaping (Bool, ChatError?) -> Void) {
        if userInfo.id == EaseChatUIKitContext.shared?.currentUserId ?? "" {
            EaseChatUIKitContext.shared?.currentUser = userInfo
            EaseChatUIKitContext.shared?.userCache?[userInfo.id] = userInfo
        } else {
            EaseChatUIKitContext.shared?.updateCache(type: .chat, profile: userInfo)
            EaseChatUIKitContext.shared?.updateCache(type: .user, profile: userInfo)
            EaseChatUIKitContext.shared?.updateCache(type: .group, profile: userInfo)
        }
    }
    
    public func login(userId: String, token: String, completion: @escaping (Bool, ChatError?) -> Void) {
        ChatClient.shared().login(withUsername: userId, token: token) { user_id, error in
            completion(error == nil,error)
        }
    }
    
    public func logout(unbindNotificationDeviceToken: Bool = false, completion: @escaping (Bool, ChatError?) -> Void) {
        ChatClient.shared().logout(unbindNotificationDeviceToken) { error in
            completion(error == nil,error)
        }
    }
    
    private func convertToUser(info: UserInfo) -> EaseProfile {
        let user = EaseProfile()
        user.id = info.userId ?? ""
        user.nickname = info.nickname ?? ""
        user.avatarURL = info.avatarUrl ?? ""
        return user
    }
    
    private func convertToUserInfo(user: EaseProfileProtocol) -> UserInfo {
        let info = UserInfo()
        info.userId = user.id
        info.nickname = user.nickname
        info.avatarUrl = user.avatarURL
        return info
    }
    
}

//MARK: - ChatClientDelegate
//MARK: - ChatClientDelegate
extension UserServiceImplement: ChatClientListener {
    public func tokenDidExpire(_ aErrorCode: ChatErrorCode) {
        for response in self.responseDelegates.allObjects {
            response.onUserTokenDidExpired()
        }
    }
    
    public func tokenWillExpire(_ aErrorCode: ChatErrorCode) {
        for response in self.responseDelegates.allObjects {
            response.onUserTokenWillExpired()
        }
    }
    
    public func userAccountDidLogin(fromOtherDevice aDeviceName: String?) {
        for response in self.responseDelegates.allObjects {
            if let device = aDeviceName {
                response.onUserLoginOtherDevice(device: device)
            }
        }
    }
    
    public func connectionStateDidChange(_ aConnectionState: ConnectionState) {
        for response in self.responseDelegates.allObjects {
            response.onSocketConnectionStateChanged(state: aConnectionState)
        }
    }
    
    public func userDidForbidByServer() {
        for response in self.responseDelegates.allObjects {
            response.userDidForbidden()
        }
    }
    
    public func userAccountDidRemoveFromServer() {
        for response in self.responseDelegates.allObjects {
            response.userAccountDidRemoved()
        }
    }
    
    public func userAccountDidForced(toLogout aError: ChatError?) {
        for response in self.responseDelegates.allObjects {
            response.userAccountDidForcedToLogout(error: aError)
        }
    }
    
    public func autoLoginDidCompleteWithError(_ aError: ChatError?) {
        for response in self.responseDelegates.allObjects {
            response.onUserAutoLoginCompletion(error: aError)
        }
    }
}


