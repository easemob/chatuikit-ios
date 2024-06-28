//
//  PinnedMessageContainer.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/13.
//

import UIKit

@objc open class PinnedIndicatorView: UIView {

    public lazy var icon: UIImageView = {
        UIImageView(frame: CGRect(x: 8, y: (self.frame.height-18)/2.0, width: 18, height: 18)).contentMode(.scaleAspectFill).image(UIImage(named: "pinned_messages", in: .chatBundle, with: nil)).backgroundColor(.clear)
    }()
    
    public lazy var content: UILabel = {
        UILabel(frame: CGRect(x: self.icon.frame.maxX+8, y: 8, width: self.frame.width-46*2, height: self.frame.height-16)).lineBreakMode(.byTruncatingTail).backgroundColor(.clear).text("Sticky Message".chat.localize).font(UIFont.theme.labelMedium)
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews([self.icon,self.content])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc open func refresh(entity: MessageEntity) {
        self.content.attributedText = entity.content
    }
}

extension PinnedIndicatorView: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.content.textColor = style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
        if style == .dark {
            self.icon.image = UIImage(named: "pinned_messages", in: .chatBundle, with: nil)
        } else {
            self.icon.image = UIImage(named: "pinned_messages", in: .chatBundle, with: nil)?.withTintColor(UIColor.theme.neutralColor3)
        }
        
    }
}
