//
//  DisplayProviderProtocol.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/8.
//

import Foundation

@objc public enum EaseProfileProviderType: UInt {
    case chat
    case group
    case contact
}

/// Profile of the EaseChatUIKit display needed.
@objc public protocol EaseProfileProtocol: NSObjectProtocol {
    var id: String {set get}
    var remark: String {set get}
    var selected: Bool {set get}
    var nickname: String {set get}
    var avatarURL: String {set get}
    
    func toJsonObject() -> Dictionary<String,Any>?
}

@objcMembers open class EaseProfile:NSObject, EaseProfileProtocol {
    public var remark: String = ""
    
    public func toJsonObject() -> Dictionary<String, Any>? {
        ["ease_chat_uikit_user_info":["nickname":self.nickname,"avatarURL":self.avatarURL,"userId":self.id]]
    }
    
    
    public var id: String = ""
    
    public var avatarURL: String = ""
    
    public var nickname: String = ""
        
    public var selected: Bool = false
    
    public var modifyTime: Int64 = 0
    
    public override func setValue(_ value: Any?, forUndefinedKey key: String) {
        
    }
        
}

/// Profile provider of the EaseChatUIKit.Only available in Swift language.
public protocol EaseProfileProvider {
    
    /// Coroutine obtains user information asynchronously.
    /// - Parameter profileIds: The corresponding conversation id string array.
    /// - Returns: Array of the conform``EaseProfileProtocol`` object.
    func fetchProfiles(profileIds: [String]) async -> [EaseProfileProtocol]
}

/// /// Profile provider of the EaseChatUIKit.Only available in Objective-C language.
@objc public protocol EaseProfileProviderOC: NSObjectProtocol {
    
    /// Need to obtain the list display information on the current screen.
    /// - Parameters:
    ///   - profileIds: The corresponding conversation id string array.
    ///   - completion: Callback,obtain Array of the ``EaseProfileProtocol`` object.
    func fetchProfiles(profileIds: [String],completion: @escaping ([EaseProfileProtocol]) -> Void)
}

public protocol EaseGroupProfileProvider {
    /// Coroutine obtains user information asynchronously.
    /// - Parameter profileIds: The corresponding conversation id string array.
    /// - Returns: Array of the conform``EaseProfileProtocol`` object.
    func fetchGroupProfiles(profileIds: [String]) async -> [EaseProfileProtocol]
    
}



@objc public protocol EaseGroupProfileProviderOC: NSObjectProtocol {
    
    /// Need to obtain the list display information on the current screen.
    /// - Parameters:
    ///   - profileIds: The corresponding conversation id string array.
    ///   - completion: Callback,obtain Array of the ``EaseProfileProtocol`` object.
    func fetchGroupProfiles(profileIds: [String],completion: @escaping ([EaseProfileProtocol]) -> Void)
}


