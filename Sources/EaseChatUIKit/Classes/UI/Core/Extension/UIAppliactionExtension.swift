//
//  UIWindow+Key.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/8/30.
//

import UIKit

public extension UIApplication {
    var chat: ChatWrapper<UIApplication> {
        return ChatWrapper.init(self)
    }
}


public extension ChatWrapper where Base == UIApplication {
    
    /// KeyWindow property
    /// How to use?
    /// `UIApplication.shared.chat.keyWindow`
    var keyWindow: UIWindow? {
        (base.connectedScenes
         // Keep only active scenes, onscreen and visible to the user
            .filter { $0.activationState == .foregroundActive }
         // Keep only the first `UIWindowScene`
            .first(where: { $0 is UIWindowScene })
         // Get its associated windows
            .flatMap({ $0 as? UIWindowScene })?.windows
         // Finally, keep only the key window
            .first(where: \.isKeyWindow))
    }
}


