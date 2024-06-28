//
//  PinnedMessageCell.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/12.
//

import UIKit

@objc open class PinnedMessageCell: UITableViewCell {
    
    public var removeActionHandler: ((PinnedMessageEntity)->Void)?
    
    public private(set) var entity: PinnedMessageEntity?
    
    public var removeWidth: CGFloat = 0
    
    public var confirmRemoveWidth: CGFloat = 0
    
    public lazy var container: UIView = {
        UIView(frame: CGRect(x: 12, y: 4, width: self.frame.width-24, height: self.frame.height-8)).cornerRadius(.extraSmall)
    }()
    
    public lazy var pinTitle: UILabel = {
        UILabel(frame: CGRect(x: 8, y: 6, width: self.container.frame.width-16-80, height: 18)).font(UIFont.theme.labelSmall).backgroundColor(.clear)
    }()
    
    public lazy var pinTime: UILabel = {
        UILabel(frame: CGRect(x: self.container.frame.width-78, y: 6, width: 70, height: 16)).font(UIFont.theme.bodySmall).backgroundColor(.clear).textColor(UIColor.theme.neutralColor7).textAlignment(.right)
    }()
    
    public lazy var pinContent: UILabel = {
        UILabel(frame: CGRect(x: 8, y: 6, width: self.container.frame.width-16-80, height: 18)).font(UIFont.theme.bodyMedium).backgroundColor(.clear)
    }()
    
    public lazy var remove: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: self.container.frame.width-self.removeWidth-8-12, y: self.pinTime.frame.maxY+4, width: self.removeWidth+12, height: 18)).font(UIFont.theme.labelMedium).title("Remove".chat.localize, .normal).addTargetFor(self, action: #selector(removeAction), for: .touchUpInside)
    }()

    public lazy var confirmRemove: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: self.container.frame.width-self.confirmRemoveWidth-8-12, y: self.pinTime.frame.maxY+4, width: self.confirmRemoveWidth+12, height: 18)).font(UIFont.theme.labelMedium).cornerRadius(.extraSmall).title("Confirm Remove".chat.localize, .normal).addTargetFor(self, action: #selector(confirmRemoveAction), for: .touchUpInside)
    }()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        
        self.removeWidth = "Remove".chat.localize.chat.sizeWithText(font: UIFont.theme.labelMedium, size: CGSize(width: 70, height: 18)).width
        self.confirmRemoveWidth = "Confirm Remove".chat.localize.chat.sizeWithText(font: UIFont.theme.labelMedium, size: CGSize(width: 70, height: 18)).width
        self.contentView.addSubview(self.container)
        self.container.addSubViews([self.pinTitle,self.pinTime,self.pinContent,self.remove,self.confirmRemove])
        self.remove.contentHorizontalAlignment = .right
        self.remove.setHitTestEdgeInsets(UIEdgeInsets(top: -5, left: -10, bottom: 5, right:10))
        self.confirmRemove.setHitTestEdgeInsets(UIEdgeInsets(top: -5, left: -10, bottom: 5, right:10))
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.container.frame = CGRect(x: 12, y: 4, width: self.frame.width-24, height: self.frame.height-8)
        self.pinTitle.frame = CGRect(x: 8, y: 6, width: self.container.frame.width-16-80, height: 18)
        self.pinTime.frame = CGRect(x: self.container.frame.width-78, y: 6, width: 70, height: 16)
        self.pinContent.frame = CGRect(x: 8, y: self.pinTitle.frame.maxY, width: self.container.frame.width-16-80, height: 18)
        self.remove.frame = CGRect(x: self.container.frame.width-self.removeWidth-8-12, y: self.pinTime.frame.maxY+4, width: self.removeWidth+12, height: 18)
        self.confirmRemove.frame = CGRect(x: self.container.frame.width-self.confirmRemoveWidth-8-12, y: self.pinTime.frame.maxY+4, width: self.confirmRemoveWidth+12, height: 18)
    }
    
    @objc open func refresh(entity: PinnedMessageEntity) {
        self.entity = entity
        self.pinTitle.attributedText = entity.pinInfo
        self.pinContent.text = entity.message.showType
        self.pinTime.text = entity.message.showDate
        self.remove.isHidden = entity.selected
        self.confirmRemove.isHidden = !entity.selected
        self.pinContent.frame = CGRect(x: 8, y: 6, width: self.container.frame.width-16-(entity.selected ? self.confirmRemove.frame.width:self.remove.frame.width), height: 18)

    }
    
    @objc open func removeAction() {
        self.confirmRemove.frame = CGRect(x: self.container.frame.width-8-12, y: self.pinTime.frame.maxY+4, width: 0, height: 18)
        self.confirmRemove.isHidden = false
        UIView.animate(withDuration: 0.382) {
            self.remove.frame = CGRect(x: self.container.frame.width-self.removeWidth-8-12, y: self.pinTime.frame.maxY+4, width: 0, height: 18)
            self.confirmRemove.frame = CGRect(x: self.container.frame.width-self.confirmRemoveWidth-8-12, y: self.pinTime.frame.maxY+4, width: self.confirmRemoveWidth+12, height: 18)
        }
    }
    
    @objc open func confirmRemoveAction() {
        if let removeMessage = self.entity {
            self.removeActionHandler?(removeMessage)
        }
    }
}


extension PinnedMessageCell: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.container.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor95
        self.pinTitle.textColor = style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
        self.pinContent.textColor = style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor4
        self.remove.setTitleColor(style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5, for: .normal)
        self.confirmRemove.setTitleColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1, for: .normal)
        self.confirmRemove.backgroundColor = style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor9
    }
}
