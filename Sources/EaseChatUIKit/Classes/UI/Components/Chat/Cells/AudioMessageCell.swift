//
//  AudioMessageCell.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/12/5.
//

import UIKit

@objc open class AudioMessageCell: MessageCell {
    
    public private(set) lazy var content: AudioMessageView = {
        AudioMessageView(frame: .zero, towards: self.towards).backgroundColor(.clear).tag(bubbleTag)
    }()
    
    lazy var redDot: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 8)).cornerRadius(4)
    }()
    
    @objc required public init(towards: BubbleTowards,reuseIdentifier: String) {
        super.init(towards: towards, reuseIdentifier: reuseIdentifier)
        if Appearance.chat.bubbleStyle == .withArrow {
            self.bubbleWithArrow.addSubview(self.content)
        } else {
            self.bubbleMultiCorners.addSubview(self.content)
        }
        self.addGestureTo(view: self.content, target: self)
        self.contentView.addSubview(self.redDot)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func refresh(entity: MessageEntity) {
        super.refresh(entity: entity)
        let frame = Appearance.chat.bubbleStyle == .withArrow ? self.bubbleWithArrow.frame:self.bubbleMultiCorners.frame
        let size = frame.size
        self.content.frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        if entity.message.direction == .receive {
            self.redDot.frame = CGRect(x: frame.maxX+8, y: frame.maxY - (frame.height/2.0) - 4, width: 8, height: 8)
            self.redDot.isHidden = entity.message.isListened
        } else {
            self.redDot.isHidden = true
        }
        self.content.refresh(entity: entity)
    }
    
    public override func switchTheme(style: ThemeStyle) {
        super.switchTheme(style: style)
        self.redDot.backgroundColor = style == .dark ? UIColor.theme.errorColor6:UIColor.theme.errorColor5
    }
}

