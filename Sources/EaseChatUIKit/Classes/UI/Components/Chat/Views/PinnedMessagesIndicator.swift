//
//  PinnedMessagesIndicator.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/12.
//

import UIKit

@objc open class PinnedMessagesIndicator: UIView {

    public lazy var first: PinnedIndicatorView = {
        PinnedIndicatorView(frame: CGRect(x: 12, y: 8, width: self.frame.width-24, height: 34)).cornerRadius(.extraSmall)
    }()
    
    public lazy var second: UIView = {
        UIView(frame: CGRect(x: 20, y: 8, width: self.frame.width-40, height: 40)).cornerRadius(.small)
    }()

    public lazy var separateLine: UIView = {
        UIView(frame: CGRect(x: 0, y: self.frame.height-0.5, width: self.frame.width, height: 0.5))
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews([self.second,self.first,self.separateLine])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }

    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension PinnedMessagesIndicator: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.first.backgroundColor =  style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor95
        self.second.backgroundColor = style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor9
        self.separateLine.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor9
    }
}
