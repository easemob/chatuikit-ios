import UIKit
import Combine

/// Tag used for identifying the avatar view in the message cell.
public let avatarTag = 900

/// Tag used for identifying the reply view in the message cell.
public let replyTag = 199

/// Tag used for identifying the bubble view in the message cell.
public let bubbleTag = 200

/// Tag used for identifying the status view in the message cell.
public let statusTag = 168

/// Enum representing the style of a message cell.
@objc public enum MessageCellStyle: UInt {
    case text
    case image
    case video
    case location
    case voice
    case file
    case cmd
    case contact
    case alert
    case combine
}

/// Enum representing the different areas that can be clicked in a message cell.
@objc public enum MessageCellClickArea: UInt {
    case avatar
    case reply
    case bubble
    case status
}

/// The amount of space between the message bubble and the cell.
let message_bubble_space = CGFloat(1)

@objcMembers open class MessageCell: UITableViewCell {
    
    private var longGestureEnabled: Bool = true
    
    public private(set) var entity = ComponentsRegister.shared.MessageRenderEntity.init()
    
    public private(set) var towards = BubbleTowards.left
    
    public var clickAction: ((MessageCellClickArea,MessageEntity) -> Void)?
    
    public var longPressAction: ((MessageCellClickArea,MessageEntity) -> Void)?
    
    public private(set) lazy var avatar: ImageView = {
        self.createAvatar()
    }()
    
    /**
     Creates an avatar image view.
     
     - Returns: An instance of `ImageView` configured with the necessary properties.
     */
    @objc open func createAvatar() -> ImageView {
        ImageView(frame: .zero).contentMode(.scaleAspectFit).backgroundColor(.clear).tag(avatarTag)
    }
    
    public private(set) lazy var nickName: UILabel = {
        self.createNickName()
    }()
    
    @objc open func createNickName() -> UILabel {
        UILabel(frame: .zero).backgroundColor(.clear).font(UIFont.theme.labelSmall)
    }
    
    public private(set) lazy var replyContent: MessageReplyView = {
        self.createReplyContent()
    }()
    
    @objc open func createReplyContent() -> MessageReplyView {
        MessageReplyView(frame: .zero).backgroundColor(.clear).tag(replyTag)
    }
    
    public private(set) lazy var bubbleWithArrow: MessageBubbleWithArrow = {
        self.createBubbleWithArrow()
    }()
    
    @objc open func createBubbleWithArrow() -> MessageBubbleWithArrow {
        MessageBubbleWithArrow(frame: .zero, forward: self.towards).tag(bubbleTag)
    }
    
    public private(set) lazy var bubbleMultiCorners: MessageBubbleMultiCorner = {
        self.createBubbleMultiCorners()
    }()
    
    @objc open func createBubbleMultiCorners() -> MessageBubbleMultiCorner {
        MessageBubbleMultiCorner(frame: .zero, forward: self.towards).tag(bubbleTag)
    }
    
    public private(set) lazy var status: UIImageView = {
        self.statusView()
    }()
    
    @objc open func statusView() -> UIImageView {
        UIImageView(frame: .zero).backgroundColor(.clear).tag(statusTag)
    }
    
    public private(set) lazy var messageDate: UILabel = {
        self.createMessageDate()
    }()
    
    @objc open func createMessageDate() -> UILabel {
        UILabel(frame: .zero).font(UIFont.theme.bodySmall).backgroundColor(.clear)
    }
    
    @objc public enum ContentDisplayStyle: UInt {
        case withReply = 1
        case withAvatar = 2
        case withNickName = 4
        case withDateAndTime = 8
    }
        
    @objc public enum BubbleDisplayStyle: UInt {
        case withArrow
        case withMultiCorner
    }
    
    internal override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    /// ``MessageCell`` required init method.
    /// - Parameters:
    ///   - towards: ``BubbleTowards`` is towards of the bubble.
    ///   - reuseIdentifier: Cell reuse identifier.
    @objc(initWithTowards:reuseIdentifier:)
    required public init(towards: BubbleTowards,reuseIdentifier: String) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        self.towards = towards
        if Appearance.chat.contentStyle.contains(.withNickName) {
            self.contentView.addSubview(self.nickName)
        }
        if Appearance.chat.contentStyle.contains(.withReply) {
            self.contentView.addSubview(self.replyContent)
            self.addGestureTo(view: self.replyContent, target: self)
        }
        if Appearance.chat.contentStyle.contains(.withAvatar) {
            self.contentView.addSubview(self.avatar)
            self.addGestureTo(view: self.avatar, target: self)
            self.longPressGestureTo(view: self.bubbleWithArrow, target: self)
        }
        if Appearance.chat.bubbleStyle == .withArrow {
            self.contentView.addSubview(self.bubbleWithArrow)
            self.longPressGestureTo(view: self.bubbleWithArrow, target: self)
        } else {
            self.contentView.addSubview(self.bubbleMultiCorners)
            self.longPressGestureTo(view: self.bubbleMultiCorners, target: self)
        }
        if Appearance.chat.contentStyle.contains(.withDateAndTime) {
            self.contentView.addSubview(self.messageDate)
        }
        self.contentView.addSubview(self.status)
        self.addGestureTo(view: self.status, target: self)
        Theme.registerSwitchThemeViews(view: self)
        self.replyContent.isHidden = true
        self.switchTheme(style: Theme.style)
    }
    
    @objc public func addGestureTo(view: UIView,target: Any?) {
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(UITapGestureRecognizer(target: target, action: #selector(clickAction(gesture:))))
    }
    
    @objc public func longPressGestureTo(view: UIView,target: Any?) {
        view.isUserInteractionEnabled = true
        let longPress = UILongPressGestureRecognizer(target: target, action: #selector(longPressAction(gesture:)))
        view.addGestureRecognizer(longPress)
    }
    
    @objc open func clickAction(gesture: UITapGestureRecognizer) {
        if let tag = gesture.view?.tag {
            switch tag {
            case statusTag:
                self.clickAction?(.status,self.entity)
            case replyTag:
                self.clickAction?(.reply,self.entity)
            case bubbleTag:
                self.clickAction?(.bubble,self.entity)
            case avatarTag:
                self.clickAction?(.avatar,self.entity)
            default:
                break
            }
        }
    }
    
    @objc open func longPressAction(gesture: UILongPressGestureRecognizer) {
        if let tag = gesture.view?.tag {
            if self.longGestureEnabled {
                self.longGestureEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.longGestureEnabled = true
                }
                switch tag {
                case bubbleTag:
                    self.longPressAction?(.bubble,self.entity)
                case avatarTag:
                    self.longPressAction?(.avatar,self.entity)
                default:
                    break
                }
            }
        }
    }
    
    private func addRotation() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(value: Double.pi * 2)
        rotationAnimation.duration = 1
        rotationAnimation.repeatCount = 999
        rotationAnimation.isRemovedOnCompletion = false
        rotationAnimation.fillMode = CAMediaTimingFillMode.forwards
        
        self.status.layer.add(rotationAnimation, forKey: "rotationAnimation")
    }
        
    /// Refresh cell with ``MessageEntity``
    /// - Parameter entity: ``MessageEntity``
    @objc(refreshWithEntity:)
    open func refresh(entity: MessageEntity) {
        self.towards = entity.message.direction == .send ? .right:.left
        self.entity = entity
        self.updateAxis(entity: entity)
        self.status.image = entity.stateImage
        if entity.state == .sending {
            self.addRotation()
        } else {
            self.status.layer.removeAllAnimations()
        }
        self.avatar.cornerRadius(Appearance.avatarRadius)
        self.avatar.image = Appearance.avatarPlaceHolder
        if let user = entity.message.user {
            if !user.avatarURL.isEmpty {
                self.avatar.image(with: user.avatarURL, placeHolder: Appearance.avatarPlaceHolder)
            } else {
                self.avatar.image = Appearance.avatarPlaceHolder
            }
            let nickName = user.nickname.isEmpty ? user.id:user.nickname
            self.nickName.text = nickName
        }
        self.nickName.text = entity.message.from
        let date = entity.message.showDetailDate
        self.messageDate.text = date
        self.replyContent.isHidden = entity.replyContent == nil
        self.replyContent.isHidden = entity.replySize.height <= 0
        if entity.replySize.height > 0 {
            self.replyContent.refresh(entity: entity)
        }
    }
    
    
    /// Update cell subviews axis with ``MessageEntity``
    /// - Parameter entity: ``MessageEntity``
    @objc(updateAxisWithEntity:)
    open func updateAxis(entity: MessageEntity) {
        if entity.message.direction == .receive {
            self.avatar.frame = CGRect(x: 12, y: entity.height - 8 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - 34, width: 28, height: 28)
            self.nickName.frame = CGRect(x:  Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.maxX+12:12, y: 10, width: limitBubbleWidth, height: 16)
            self.messageDate.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.maxX+12:12, y: entity.height-24, width: 120, height: 16)
            self.messageDate.textAlignment = .left
            self.nickName.textAlignment = .left
            if Appearance.chat.contentStyle.contains(.withReply) {
                self.replyContent.frame = CGRect(x:  Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.maxX+12:12, y: Appearance.chat.contentStyle.contains(where: { $0 == .withNickName }) ? self.nickName.frame.maxY:12, width: entity.replySize.width, height: entity.replySize.height)
            }
            self.bubbleWithArrow.towards = (entity.message.direction == .receive ? .left:.right)
            self.bubbleMultiCorners.towards = (entity.message.direction == .receive ? .left:.right)
            if Appearance.chat.bubbleStyle == .withArrow {
                self.bubbleWithArrow.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.maxX+12:12, y: entity.height - 16 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - entity.bubbleSize.height, width: entity.bubbleSize.width, height: entity.bubbleSize.height+message_bubble_space*2)
                self.bubbleWithArrow.draw(self.bubbleWithArrow.frame)
            } else {
                self.bubbleMultiCorners.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.maxX+12:12, y: entity.height - 16 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - entity.bubbleSize.height, width: entity.bubbleSize.width, height: entity.bubbleSize.height+message_bubble_space*2)
                self.bubbleMultiCorners.draw(self.bubbleMultiCorners.frame)
            }
            self.status.isHidden = true
            self.status.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.maxX+entity.bubbleSize.width+4:12+entity.bubbleSize.width+4, y: entity.height - 8 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - 22, width: 20, height: 20)
        } else {
            self.status.isHidden = false
            self.avatar.frame = CGRect(x: ScreenWidth-40, y: entity.height - 8 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - 34, width: 28, height: 28)
            self.nickName.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.minX-limitBubbleWidth-12:ScreenWidth-limitBubbleWidth-12, y: 10, width: limitBubbleWidth, height: 16)
            self.messageDate.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? (self.avatar.frame.minX-12-120):(ScreenWidth-132), y: entity.height-24, width: 120, height: 16)
            self.messageDate.textAlignment = .right
            self.nickName.textAlignment = .right
            if Appearance.chat.contentStyle.contains(.withReply) {
                self.replyContent.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.minX-entity.replySize.width-12:ScreenWidth-12-entity.replySize.width, y: Appearance.chat.contentStyle.contains(where: { $0 == .withNickName }) ? self.nickName.frame.maxY:12, width: entity.replySize.width, height: entity.replySize.height)
            }
            self.bubbleWithArrow.towards = (entity.message.direction == .receive ? .left:.right)
            self.bubbleMultiCorners.towards = (entity.message.direction == .receive ? .left:.right)
            if Appearance.chat.bubbleStyle == .withArrow {
                self.bubbleWithArrow.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.minX-entity.bubbleSize.width-12:ScreenWidth-entity.bubbleSize.width-12, y: entity.height - 16 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - entity.bubbleSize.height, width: entity.bubbleSize.width, height: entity.bubbleSize.height+message_bubble_space*2)
                self.bubbleWithArrow.draw(self.bubbleWithArrow.frame)
            } else {
                self.bubbleMultiCorners.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.minX-entity.bubbleSize.width-12:ScreenWidth-entity.bubbleSize.width-12, y: entity.height - 16 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - entity.bubbleSize.height, width: entity.bubbleSize.width, height: entity.bubbleSize.height+message_bubble_space*2)
                self.bubbleMultiCorners.draw(self.bubbleMultiCorners.frame)
            }
            self.status.frame = CGRect(x: Appearance.chat.contentStyle.contains(where: { $0 == .withAvatar }) ? self.avatar.frame.minX-entity.bubbleSize.width-12-20-4:ScreenWidth-entity.bubbleSize.width-12-20-4, y: entity.height - 8 - (Appearance.chat.contentStyle.contains(where: { $0 == .withDateAndTime }) ? 16:2) - 22, width: 20, height: 20)
            self.replyContent.cornerRadius(Appearance.chat.imageMessageCorner)
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


/**
 An extension of `MessageCell` that conforms to the `ThemeSwitchProtocol`.
 It provides a method to switch the theme of the cell.
 */
extension MessageCell: ThemeSwitchProtocol {
    /**
     Switches the theme of the cell.
     
     - Parameter style: The style of the theme to switch to.
     */
    open func switchTheme(style: ThemeStyle) {
        self.replyContent.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor95
        self.nickName.textColor = style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5
        self.messageDate.textColor = style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor7
    }
}


