import UIKit

/// Audio message `default` height.
public var audioHeight = CGFloat(36)

/// File message `default` height.
public var fileHeight = CGFloat(60)

/// Combine message `default` height.
public var combineHeight = CGFloat(98)

/// Location message `default` height.
public var locationHeight = CGFloat(70)

/// Custom contact card message `default` height.
public var contactCardHeight = CGFloat(90)

/// Alert message `default` height.
public var alertHeight = CGFloat(30)

/// Limit width of the message bubble.
public var limitBubbleWidth = CGFloat(ScreenWidth*(3/5.0))

/// Custom message `default` size exclude Alert&Contact.
public var extraCustomSize = CGSize(width: limitBubbleWidth, height: 36)

public let limitImageHeight = CGFloat((300/844)*ScreenHeight)

public let limitImageWidth = CGFloat((225/390)*ScreenWidth)

public let translationKey = "EaseChatUIKit_force_show_translation"

public let topicHeight = CGFloat(58)

public let reactionHeight = CGFloat(30)

public let reactionMaxWidth = Appearance.chat.contentStyle.contains(.withAvatar) ? ScreenWidth-48*2:40

public let callMessage = "rtcCallWithAgora"

public let urlPreviewImageHeight = CGFloat(137)

@objcMembers open class MessageEntity: NSObject {
    
    required public override init() {
        super.init()
    }
    
    public var message: ChatMessage = ChatMessage()
    
    public var urlPreview: URLPreviewManager.HTMLContent?
    
    public var showUserName: String {
        if let remark = self.message.user?.remark,!remark.isEmpty {
            return remark
        }
        if let nickname = self.message.user?.nickname,!nickname.isEmpty {
            return nickname
        }
        return self.message.from
    }
    
    public var visibleReactionToIndex = 0
    
    /// Whether combine history message or not.
    public var historyMessage: Bool = false
    
    /// Whether text message contain URL or not.
    public var containURL = false
    
    /// What if text message contain url array first
    public var previewURL = ""
    
    /// URL preview result state.
    public var previewResult = URLPreviewResult.parsing 
    
    public var previewFinished: ((MessageEntity) -> Void)?
    
    /// Whether message show translations or not.
    public var showTranslation: Bool {
        set {
            if !newValue {
                if self.message.ext != nil {
                    self.message.ext?.removeValue(forKey: translationKey)
                }
            } else {
                if self.message.ext == nil {
                    self.message.ext = [translationKey:newValue]
                } else {
                    self.message.ext?[translationKey] = newValue
                }
                ChatClient.shared().chatManager?.update(self.message)
            }
        }
        get {
            if self.historyMessage == false {
                return (self.message.ext?[translationKey] as? Bool) ?? false
            }
            return false
        }
    }
        
    /// /// Message state.
    public var state: ChatMessageStatus = .sending
    
    /// Whether audio message playing or not.
    public var playing = false
    
    public var selected = false
    
    /// Message status image.
    public var stateImage: UIImage? {
        self.getStateImage()
    }
    
    open func getStateImage() -> UIImage? {
        switch self.state {
        case .sending:
            return UIImage(named: "message_status_spinner", in: .chatBundle, with: nil)
        case .succeed:
            return UIImage(named: "message_status_succeed", in: .chatBundle, with: nil)
        case .failure:
            return UIImage(named: "message_status_failure", in: .chatBundle, with: nil)
        case .delivered:
            return UIImage(named: "message_status_delivery", in: .chatBundle, with: nil)
        case .read:
            return UIImage(named: "message_status_read", in: .chatBundle, with: nil)
        }
    }
    
    /// Reply bubble size in the message.
    public lazy var replySize: CGSize = {
        self.updateReplySize()
    }()
    
    /// Bubble size of the message.
    public lazy var bubbleSize: CGSize = {
        self.updateBubbleSize()
    }()
    
    /// Height for row.
    public lazy var height: CGFloat = {
        self.cellHeight()
    }()
    
    open func cellHeight() -> CGFloat {
        if let body = self.message.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_alert_message {
            return self.bubbleSize.height
        } else {
            return 8+(Appearance.chat.contentStyle.contains(.withNickName) ? 28:2)+(Appearance.chat.contentStyle.contains(.withReply) ? self.replySize.height:2)+self.bubbleSize.height+(Appearance.chat.contentStyle.contains(.withDateAndTime) ? 24:8)+self.topicContentHeight()+self.reactionContentHeight()
        }
    }
    
    open func reactionMenuWidth() -> CGFloat {
        if self.message.messageId.isEmpty {
            return 0
        }
        if !Appearance.chat.contentStyle.contains(.withMessageReaction) {
            return 0
        }
        if let reactions = self.message.reactionList {
            if reactions.count > 0 {
                var width = CGFloat(0)
                for (index,reaction) in reactions.enumerated() {
                    let newWidth = width + CGFloat(reaction.reactionWidth+(index > 0 ? 4:0))
                    if newWidth < reactionMaxWidth - 30 {
                        width = newWidth
                        self.visibleReactionToIndex = index
                    } else {
                        self.visibleReactionToIndex = index
                        return width
                    }
                }
                return width
            }
            return 0
        }
        return 0
    }
    
    open func topicContentHeight() -> CGFloat {
        if self.message.messageId.isEmpty {
            return 0
        }
        let realHeight = self.message.chatThread != nil ? topicHeight:CGFloat(0)
        let topic_height = Appearance.chat.contentStyle.contains(.withMessageThread) ? realHeight:0
        return topic_height
    }
    
    open func reactionContentHeight() -> CGFloat {
        if self.message.messageId.isEmpty {
            return 0
        }
        let realHeight = (self.message.reactionList?.count ?? 0) > 0 ? reactionHeight:CGFloat(0)
        let reaction_height = (Appearance.chat.contentStyle.contains(.withMessageReaction) ? realHeight:CGFloat(0))
        return reaction_height
    }
    
    /// Text message show content.
    public private(set) lazy var content: NSAttributedString? = {
        self.convertTextAttribute()
    }()
    
    public lazy var topicContent: NSAttributedString? = {
        self.convertTopicContent()
    }()
    
    /// Text message show translation
    public private(set) lazy var translation: NSAttributedString? = {
        if Appearance.chat.enableTranslation {
            return self.convertTextTranslationAttribute()
        } else {
            return nil
        }
    }()
    
    /// Reply title in bubble on current message.
    public private(set) lazy var replyTitle: NSAttributedString? = {
        self.convertReplyTitle()
    }()
    
    
    
    open func convertReplyTitle() -> NSAttributedString? {
        if let quoteMessage = self.message.quoteMessage {
            var showUserName = ""
            if showUserName.isEmpty {
                showUserName = quoteMessage.user?.remark ?? ""
            }
            if showUserName.isEmpty {
                showUserName = quoteMessage.user?.nickname ?? ""
            }
            if showUserName.isEmpty {
                showUserName = quoteMessage.from
            }
            return NSAttributedString {
                AttributedText(showUserName).font(Font.theme.labelSmall).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5)
            }
        } else {
            if self.message.quoteMessageId.isEmpty {
                return nil
            } else {
                return NSAttributedString {
                    AttributedText("message doesn't exist".chat.localize).font(Font.theme.labelSmall).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5)
                }
            }
        }
    }
    
    public private(set) lazy var replyContent: NSAttributedString? = {
        self.convertToReply()
    }()
            
    /// Calculate bubble size.
    /// - Returns: ``CGSize`` of bubble.
    open func updateBubbleSize() -> CGSize {
        switch self.message.body.type {
        case .text: return self.textBubbleSize()
        case .image: return self.thumbnailSize(video: false)
        case .voice: return self.audioSize()
        case .video: return self.thumbnailSize(video: true)
        case .file:  return CGSize(width: limitBubbleWidth, height: fileHeight)
        case .location: return self.message.contentSize
        case .combine:
            if let body = self.message.body as? ChatCombineMessageBody {
                if self.historyMessage {
                    return CGSize(width: ScreenWidth-68, height: 20)
                } else {
                    var summaryHeight = body.summary?.chat.sizeWithText(font: UIFont.theme.bodySmall, size: CGSize(width: limitBubbleWidth-24, height: combineHeight-14)).height ?? 0
                    if summaryHeight < 16 {
                        summaryHeight = 16
                    }
                    return CGSize(width: limitBubbleWidth, height: summaryHeight+(self.message.direction == .receive ? 30:20))
                }
            }
            return .zero
        case .custom: return self.customSize()
        default:
            return CGSize(width: limitBubbleWidth, height: 30)
        }
    }
    
    open func textSize() -> CGSize {
        let label = UILabel().numberOfLines(0).lineBreakMode(.byWordWrapping)
        let textAttribute = self.convertTextAttribute()
        label.attributedText = textAttribute
        var width = label.sizeThatFits(CGSize(width: self.historyMessage ? ScreenWidth-68:limitBubbleWidth-24, height: 9999)).width+(self.historyMessage ? 68:24)
        let textHeight = label.sizeThatFits(CGSize(width: limitBubbleWidth-24, height: 9999)).height
        if textAttribute?.string.count ?? 0 <= 1,self.message.body.type == .text {
            width += 8
        }
        return CGSize(width: width, height: textHeight)
    }
    
    open func textBubbleSize() -> CGSize {
        let textSize = self.textSize()
        var width = textSize.width
        let textHeight = textSize.height

        let translateSize = Appearance.chat.enableTranslation ? self.translationSize():.zero
        if width < translateSize.width {
            width = translateSize.width+16
        }
        var height = 6.5+textHeight+(self.message.edited ? 20:6)+(self.showTranslation ? translateSize.height+28:0)
        if self.message.edited {
            width += 44
        }
        if Appearance.chat.enableURLPreview {
            let increase = self.urlPreviewHeight()
            height += increase
            if increase >= 38 {
                width = limitBubbleWidth
            }
        }
        return CGSize(width: width, height: height)
    }
    
    @objc open func urlPreviewHeight() -> CGFloat {
        var increase:CGFloat = 0
        if self.containURL,!self.historyMessage,self.previewResult != .failure,!self.previewURL.isEmpty {
            if self.urlPreview != nil {
                increase += 4
                if let url = self.urlPreview?.imageURL,!url.isEmpty {
                    increase += urlPreviewImageHeight
                }
                if let title = self.urlPreview?.title ,!title.isEmpty {
                    if let title = self.urlPreview?.titleAttribute  {
                        let titleHeight = UILabel().numberOfLines(2).font(UIFont.theme.headlineSmall).attributedText(title).sizeThatFits(CGSize(width: limitBubbleWidth-24, height: 50)).height
                        increase += (titleHeight+16)
                    }
                }
                if let description = self.urlPreview?.descriptionHTML, !description.isEmpty {
                    if let description = self.urlPreview?.descriptionHTML {
                        let descriptionHeight = UILabel().numberOfLines(3).font(UIFont.theme.bodySmall).text(description).sizeThatFits(CGSize(width: limitBubbleWidth-24, height: 9999)).height
                        increase += (descriptionHeight+8)
                    }
                }
            } else {
                increase = 38
            }
        }
        return increase
    }
    
    open func previewStart() {
        if self.previewURL.isEmpty,self.previewResult == .parsing,self.urlPreview != nil {
            return
        }
        URLPreviewManager.preview(from: self.previewURL) { [weak self] (error, content) in
            guard let `self` = self else { return }
            if error == nil {
                if let content = content {
                    self.urlPreview = content
                    self.previewResult = .success
                    var storage = content.toDictionary()
                    storage["url"] = self.previewURL
                    storage["status"] = "1"
                    self.message.ext?["ease_chat_uikit_text_url_preview"] = storage
                    URLPreviewManager.caches[self.previewURL] = content
                }
            } else {
                self.previewResult = .failure
                self.message.ext?["ease_chat_uikit_text_url_preview"] = ["status":"0","url":self.previewURL]
                if let error = error as? NSError {
                    consoleLogInfo("URLPreviewManager preview \(self.previewURL) error:\(error.localizedDescription)", type: .error)
                }
            }
            
            ChatClient.shared().chatManager?.update(self.message)
            
            DispatchQueue.main.async {
                self.bubbleSize = self.updateBubbleSize()
                self.height = self.cellHeight()
                self.previewFinished?(self)
            }

        }
    }
    
    open func translationSize() -> CGSize {
        if self.showTranslation {
            let label = UILabel().numberOfLines(0)
            label.attributedText = self.convertTextTranslationAttribute()
            let size = label.sizeThatFits(CGSize(width: limitBubbleWidth-24, height: 9999))
            let width = size.width+24
            return CGSize(width: width < 86 ? 86:width, height: size.height+10)
        } else {
            return .zero
        }
    }
    
    open func thumbnailSize(video: Bool) -> CGSize {
        let defaultSize = CGSize(width: 135, height: 135)
        var size = CGSize.zero
        if let body = self.message.body as? ChatImageMessageBody {
            size = body.size
        }
        if let body = self.message.body as? ChatVideoMessageBody {
            size = body.thumbnailSize
        }
        if size == .zero {
            if let body = self.message.body as? ChatImageMessageBody {
                if size == .zero {
                    if let path = body.thumbnailLocalPath,FileManager.default.fileExists(atPath: path) {
                        size = UIImage(contentsOfFile: path)?.size ?? .zero
                    } else {
                        if let localPath = body.localPath,FileManager.default.fileExists(atPath: localPath) {
                            size = UIImage(contentsOfFile: localPath)?.size ?? .zero
                        }
                    }
                }
            }
            if let body = self.message.body as? ChatVideoMessageBody {
                size = body.thumbnailSize
            }
            
            
            if size == .zero {
                size = defaultSize
            }
        }
        let scale = size.width/size.height
        switch scale {
        case 0...0.1:
            return CGSize(width: limitImageHeight/10.0, height: limitImageHeight)
        case 0.1...0.75:
            return CGSize(width: limitImageHeight*(size.width/size.height), height: limitImageHeight)
        case 0.7501...10:
            return CGSize(width: limitImageWidth, height: limitImageWidth*(size.height/size.width))
        case 10...:
            return CGSize(width: limitImageWidth, height: limitImageWidth/10.0)
        default:
            return .zero
        }
    }
    
    open func audioSize() -> CGSize {
        switch Int((self.message.body as? ChatAudioMessageBody)?.duration ?? 1) {
        case 0...9:
            return CGSize(width: 75, height: audioHeight)
        case 10...19:
            return CGSize(width: 100, height: audioHeight)
        case 20...29:
            return CGSize(width: 125, height: audioHeight)
        case 30...39:
            return CGSize(width: 150, height: audioHeight)
        case 40...49:
            return CGSize(width: 175, height: audioHeight)
        case 50...Appearance.chat.audioDuration:
            return CGSize(width: limitBubbleWidth, height: audioHeight)
        default:
            return .zero
        }
    }
    
    open func customSize() -> CGSize {
        if let body = self.message.body as? ChatCustomMessageBody {
            if body.event == EaseChatUIKit_user_card_message {
                return CGSize(width: self.historyMessage ? ScreenWidth-32:limitBubbleWidth, height: contactCardHeight)
            } else {
                if body.event == EaseChatUIKit_alert_message {
                    let label = UILabel().numberOfLines(0).lineBreakMode(.byWordWrapping)
                    label.attributedText = self.convertTextAttribute()
                    let size = label.sizeThatFits(CGSize(width: ScreenWidth-32, height: 9999))
                    return CGSize(width: ScreenWidth-32, height: size.height+50)
                } else {
                    return self.message.contentSize
                }
            }
        } else {
            return .zero
        }
    }
    
    /// Converts the message text into an attributed string, including the user's nickname, message text, and emojis.
    open func convertTextAttribute() -> NSAttributedString? {
        if self.message.messageId.isEmpty {
            return nil
        }
        var text = NSMutableAttributedString()
        if self.message.messageId.isEmpty {
            return NSMutableAttributedString {
                AttributedText("No Messages".chat.localize).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor7).font(UIFont.theme.labelSmall).lineHeight(multiple: 0.98, minimum: 18)
            }
        }
        var textColor = self.message.direction == .send ? Appearance.chat.sendTextColor:Appearance.chat.receiveTextColor
        if self.historyMessage {
            textColor = Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
        }
        if self.message.body.type != .text, self.message.body.type != .custom {
            text.append(NSAttributedString {
                AttributedText(self.message.showType+self.message.showContent).foregroundColor(textColor).font(self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge).lineHeight(multiple: 0.98, minimum: 18).lineBreakMode(.byWordWrapping)
            })
            return text
        }
        if self.historyMessage,self.message.body.type == .custom {
            text.append(NSAttributedString {
                AttributedText(self.message.showType+self.message.showContent).foregroundColor(textColor).font(self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge).lineBreakMode(.byWordWrapping).lineHeight(multiple: 0.98, minimum: 18)
            })
            return text
        }
        if self.message.body.type == .custom,let body = self.message.body as? ChatCustomMessageBody {
            switch body.event {
            case EaseChatUIKit_alert_message:
                if let something = self.message.ext?["something"] as? String {
                    if let threadName = self.message.ext?["threadName"] as? String {
                        let range = something.chat.rangeOfString(threadName)
                        text.append(NSAttributedString {
                            AttributedText(something).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor7).font(UIFont.theme.bodySmall).lineHeight(multiple: 0.98, minimum: 14).alignment(.center)
                        })
                        text.addAttribute(NSAttributedString.Key.foregroundColor, value: Theme.style == .dark ? Color.theme.primaryColor6:Color.theme.primaryColor5, range: range)
                    } else {
                        text.append(NSMutableAttributedString {
                            AttributedText(self.message.user?.nickname ?? self.message.from).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor7).font(UIFont.theme.labelSmall).lineHeight(multiple: 0.98, minimum: 14).alignment(.center)
                        })
                        text.append(NSAttributedString {
                            AttributedText(" "+something).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor7).font(UIFont.theme.bodySmall).lineHeight(multiple: 0.98, minimum: 14).alignment(.center)
                        })
                    }
                    
                }
                
            default:
                text.append(NSAttributedString {
                    AttributedText(self.message.showType+self.message.showContent).foregroundColor(textColor).font(self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge).lineHeight(multiple: 0.98, minimum: self.historyMessage ? 16:18).lineBreakMode(.byWordWrapping)
                })
                break
            }
            
        } else {
            var result = self.message.showType
            
            for (key,value) in ChatEmojiConvertor.shared.oldEmojis {
                result = result.replacingOccurrences(of: key, with: value)
            }
            if self.message.mention.isEmpty {
                text.append(NSAttributedString {
                    AttributedText(result).foregroundColor(textColor).font(self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge).lineHeight(multiple: 0.98, minimum: self.historyMessage ? 16:18).lineBreakMode(.byWordWrapping)
                })
            } else {
                if self.message.mention == EaseChatUIKitContext.shared?.currentUserId ?? "" {
                    let mentionUser = EaseChatUIKitContext.shared?.chatCache?[self.message.mention]
                    var nickname = mentionUser?.remark
                    if nickname?.isEmpty ?? true {
                        nickname = mentionUser?.nickname
                        if nickname?.isEmpty ?? true {
                            nickname = EaseChatUIKitContext.shared?.currentUserId ?? ""
                        }
                    }
                    let content = result
                    
                    let mentionRange = content.lowercased().chat.rangeOfString(nickname ?? "")
                    let range = NSMakeRange(mentionRange.location-1, mentionRange.length+1)
                    let mentionAttribute = NSMutableAttributedString {
                        AttributedText(content).foregroundColor(textColor).font(self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge).lineHeight(multiple: 0.98, minimum: self.historyMessage ? 16:18).lineBreakMode(Appearance.chat.targetLanguage == .Chinese ? .byCharWrapping:.byWordWrapping)
                    }
                    if mentionRange.location != NSNotFound,mentionRange.length != NSNotFound {
                        mentionAttribute.addAttribute(.foregroundColor, value: (Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5), range: range)
                    }
                    text.append(mentionAttribute)
                } else {
                    let content = result
                    
                    let mentionRange = content.lowercased().chat.rangeOfString(self.message.mention.lowercased())
                    let range = NSMakeRange(mentionRange.location-1, mentionRange.length+1)
                    let mentionAttribute = NSMutableAttributedString {
                        AttributedText(content).foregroundColor(textColor).font(self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge).lineHeight(multiple: 0.98, minimum: self.historyMessage ? 16:18).lineBreakMode(.byWordWrapping)
                    }
                    if mentionRange.location != NSNotFound,mentionRange.length != NSNotFound {
                        mentionAttribute.addAttribute(.foregroundColor, value: (Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5), range: range)
                    }
                    text.append(mentionAttribute)
                }
                
            }
            let string = text.string as NSString
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol,imageBounds: CGRect(x: 0, y: -4, width: 18, height: 18))
                    text.addAttribute(.font, value: self.historyMessage ? UIFont.theme.bodyMedium:UIFont.theme.bodyLarge, range: NSMakeRange(0, text.length))
                    text.addAttribute(.foregroundColor, value: textColor, range: NSMakeRange(0, text.length))
                }
            }
            if !Appearance.chat.enableURLPreview {
                return text
            }
            // 创建 NSDataDetector 实例以检测文本中的链接
            guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
                return text
            }


            // 检测文本中的链接
            let matches = detector.matches(in: text.string, options: [], range: NSRange(location: 0, length: text.string.count))
            if matches.count == 1 {
                self.containURL = true
            } else {
                self.containURL = false
                self.previewURL = ""
                self.urlPreview = nil
                self.previewResult = .failure
                return text
            }
            self.previewURL = matches.first?.url?.absoluteString ?? ""
//            for result in matches {
//                if let url = result.url {
//                    let urlString = url.absoluteString
//                    let nsText = text.string as NSString
//                    let range = nsText.range(of: urlString, options: .caseInsensitive)
//                    
//                    if range.length > 0 {
//                        let receiveLinkColor = Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5
//                        text.addAttributes([.link:url,.underlineStyle:NSUnderlineStyle.single,.underlineColor:receiveLinkColor], range: range)
//                    }
//                    break
//                }
//            }
        }

        return text
    }
    
    open func convertTopicContent() -> NSAttributedString? {
        if self.message.messageId.isEmpty {
            return nil
        }
        var text = NSMutableAttributedString()
        guard let topicMessage = self.message.chatThread?.lastMessage else {
            text.append(NSAttributedString {
                AttributedText("No Messages".chat.localize).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).font(UIFont.theme.labelSmall)
            })
            return text
        }
        var nickname = topicMessage.user?.remark ?? ""
        if nickname.isEmpty {
            nickname = topicMessage.user?.nickname ?? ""
        }
        if nickname.isEmpty {
            nickname = topicMessage.from
        }
        if topicMessage.body.type != .text {
            text.append(NSAttributedString {
                AttributedText(nickname+":"+topicMessage.showType).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).font(UIFont.theme.labelSmall)
            })
            return text
        } else {
            var result = nickname+":"+topicMessage.showType
            for (key,value) in ChatEmojiConvertor.shared.oldEmojis {
                result = result.replacingOccurrences(of: key, with: value)
            }
            text.append(NSAttributedString {
                AttributedText(result).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).font(UIFont.theme.labelSmall)
            })
            let string = text.string as NSString
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol,imageBounds: CGRect(x: 0, y: -2, width: 14, height: 14))
                    text.addAttribute(.font, value: UIFont.theme.labelSmall, range: NSMakeRange(0, text.length))
                    text.addAttribute(.foregroundColor, value: Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5, range: NSMakeRange(0, text.length))
                }
            }
        }
        return text
    
    }
    
    open func convertTextTranslationAttribute() -> NSAttributedString? {
        if self.message.messageId.isEmpty {
            return nil
        }
        var text = NSMutableAttributedString()
        if self.message.body.type != .text {
            text.append(NSAttributedString {
                AttributedText(self.message.showType).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTranslationColor:Appearance.chat.receiveTranslationColor).font(UIFont.theme.bodyLarge).lineBreakMode(.byWordWrapping)
            })
            return text
        } else {
            var result = self.message.translation ?? self.message.showType
            for (key,value) in ChatEmojiConvertor.shared.oldEmojis {
                result = result.replacingOccurrences(of: key, with: value)
            }
            text.append(NSAttributedString {
                AttributedText(result).foregroundColor(self.message.direction == .send ? Appearance.chat.sendTranslationColor:Appearance.chat.receiveTranslationColor).font(UIFont.theme.bodyLarge).lineBreakMode(.byWordWrapping)
            })
            let string = text.string as NSString
            for symbol in ChatEmojiConvertor.shared.emojis {
                if string.range(of: symbol).location != NSNotFound {
                    let ranges = text.string.chat.rangesOfString(symbol)
                    text = ChatEmojiConvertor.shared.convertEmoji(input: text, ranges: ranges, symbol: symbol, imageBounds: CGRect(x: 0, y: -4, width: 18, height: 18))
                    let range = NSMakeRange(0, text.length)
                    text.addAttribute(.font, value: UIFont.theme.bodyLarge, range: range)
                    text.addAttribute(.foregroundColor, value: self.message.direction == .send ? Appearance.chat.sendTranslationColor:Appearance.chat.receiveTranslationColor, range: range)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakMode = .byWordWrapping
//                    paragraphStyle.lineHeightMultiple = 0.98
                    text.addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
                }
            }
            return text
        }
    }
    
    open func updateReplySize() -> CGSize {
        if let attributeContent = self.convertToReply() {
            if let attributeTitle = self.replyTitle,attributeContent.length > 0,attributeContent.string != "message doesn't exist".chat.localize {
                let labelTitle = UILabel().numberOfLines(1).lineBreakMode(.byWordWrapping)
                let labelContent = UILabel().numberOfLines(2).lineBreakMode(.byWordWrapping)
                labelTitle.attributedText = attributeTitle
                labelContent.attributedText = attributeContent
                let titleSize = labelTitle.sizeThatFits(CGSize(width: limitBubbleWidth, height: 16))
                let contentSize = labelContent.sizeThatFits(CGSize(width: limitBubbleWidth, height: 36))
                if self.message.quoteMessage!.body.type == .image || self.message.quoteMessage!.body.type == .video {
                    return CGSize(width: (titleSize.width > contentSize.width ? titleSize.width:contentSize.width)+78, height: 36+16)
                } else {
                    return CGSize(width: (titleSize.width > contentSize.width ? titleSize.width:contentSize.width)+24, height: contentSize.height+34)
                }
            } else {
                let labelContent = UILabel().numberOfLines(2).lineBreakMode(.byWordWrapping)
                labelContent.attributedText = attributeContent
                let contentSize = labelContent.sizeThatFits(CGSize(width: limitBubbleWidth, height: 36))
                return CGSize(width: contentSize.width+10, height: contentSize.height+10)
            }
        }
        return .zero
    }
        
    open func convertToReply() -> NSAttributedString? {
        if self.message.quoteMessageId.isEmpty {
            return nil
        }
        if let quoteMessage = self.message.quoteMessage {
            if let msgSender = self.message.quoteMessage?.from,!msgSender.isEmpty  {
//                let showName = quoteMessage.user?.nickName ?? msgSender
                let reply = NSMutableAttributedString()
                if let icon = quoteMessage.replyIcon?.withTintColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5) {
                    reply.append(NSAttributedString {
                        ImageAttachment(icon, bounds: CGRect(x: 0, y: -4, width: 18, height: 18))
                    })
                }
                switch quoteMessage.body.type {
                case .text:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                    })
                case .image,.video,.combine,.location:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                    })
                case .file,.voice:
                    reply.append(NSAttributedString {
                        AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                        AttributedText(quoteMessage.showContent).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                    })
                case .custom:
                    if let body = quoteMessage.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_user_card_message {
                        reply.append(NSAttributedString {
                            AttributedText(quoteMessage.showType).font(Font.theme.labelMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                            AttributedText(quoteMessage.showContent).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                        })
                    } else {
                        reply.append(NSAttributedString {
                            AttributedText("message doesn't exist".chat.localize).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                        })
                    }
                default:
                    reply.append(NSAttributedString {
                        AttributedText("message doesn't exist".chat.localize).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                    })
                }
                return reply
            } else {
                return NSAttributedString {
                    AttributedText("message doesn't exist".chat.localize).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5).lineBreakMode(.byWordWrapping)
                }
            }
        } else {
            if self.message.hasQuote {
                return NSAttributedString {
                    AttributedText("message doesn't exist".chat.localize).font(Font.theme.bodyMedium).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor6:Color.theme.neutralColor5)
                }
            } else {
                return nil
            }
        }
    }
}

@objcMembers open class PinnedMessageEntity: NSObject {
    
    required public override init() {
        super.init()
    }
    
    public var message: ChatMessage = ChatMessage()
    
    public var showUserName: String {
        if let remark = self.message.user?.remark,!remark.isEmpty {
            return remark
        }
        if let nickname = self.message.user?.nickname,!nickname.isEmpty {
            return nickname
        }
        return self.message.from
    }
    
    public var selected = false
    
    public lazy var pinInfo: NSAttributedString? = {
        if let pinInfo = self.message.pinnedInfo {
            var showName = EaseChatUIKitContext.shared?.chatCache?[pinInfo.operatorId]?.nickname ?? ""
            if showName.isEmpty {
                showName = EaseChatUIKitContext.shared?.userCache?[pinInfo.operatorId]?.remark ?? ""
            }
            if showName.isEmpty {
                showName = EaseChatUIKitContext.shared?.userCache?[pinInfo.operatorId]?.nickname ?? ""
            }
            if showName.isEmpty {
                showName = pinInfo.operatorId
            }
            return NSAttributedString {
                AttributedText(showName).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1).font(Font.theme.labelSmall)
                AttributedText(" "+"pinned"+" ").foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1).font(Font.theme.bodySmall)
                AttributedText(self.showUserName).foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1).font(Font.theme.labelSmall)
                AttributedText(" "+"message").foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1).font(Font.theme.bodySmall)
            }
        } else {
            return nil
        }
    }()
}


extension ChatMessage {
    
    /// ``EaseProfileProtocol``
    @objc public var user: EaseProfileProtocol? {
        let cacheUser = EaseChatUIKitContext.shared?.userCache?[self.from]
        if cacheUser != nil,let remark = cacheUser?.remark,!remark.isEmpty {
            EaseChatUIKitContext.shared?.chatCache?[self.from]?.remark = remark
        }
        let chatUser = EaseChatUIKitContext.shared?.chatCache?[self.from]
        if chatUser == nil,cacheUser != nil {
            return cacheUser
        }
        return chatUser
    }
    
    /// Whether message edited or not.
    @objc public var edited: Bool {
        if self.body.type != .text {
            return false
        } else {
            if let body = self.body as? ChatTextMessageBody {
                if body.operatorCount > 0,body.operationTime > 0 {
                    return true
                } else {
                    return false
                }
            }
            return false
        }
    }
    
    /// Message display date on conversation list cell.
    @objc open var showDate: String {
        let messageDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp/1000))
        if messageDate.chat.compareDays() < 0 {
            return messageDate.chat.dateString(Appearance.conversation.dateFormatOtherDay)
        } else {
            return messageDate.chat.dateString(Appearance.conversation.dateFormatToday)
        }
    }
    
    /// Message display date on chat cell.
    @objc open var showDetailDate: String {
        let messageDate = Date(timeIntervalSince1970: TimeInterval(self.timestamp/1000))
        if messageDate.chat.compareDays() < 0 {
            return messageDate.chat.dateString(Appearance.chat.dateFormatOtherDay)
        } else {
            return messageDate.chat.dateString(Appearance.chat.dateFormatToday)
        }
    }
    
    /// Message show type on the conversation list.
    @objc open var showType: String {
        var text = "[unknown]".chat.localize
        switch self.body.type {
        case .text: text = (self.body as? ChatTextMessageBody)?.text ?? ""
        case .image: text = "[Image]".chat.localize
        case .voice: text = "[Audio]".chat.localize
        case .video: text = "[Video]".chat.localize
        case .file: text = "[File]".chat.localize
        case .location: text = "[Location]".chat.localize
        case .combine: text = "[\("Chat History".chat.localize)]"
        case .cmd: text = "[Transparent]".chat.localize
        case .custom:
            if let body = self.body as? ChatCustomMessageBody {
                if body.event == EaseChatUIKit_user_card_message {
                    text = "[Contact]".chat.localize
                }
                if body.event == EaseChatUIKit_alert_message {
                    text = self.from+":"+((self.ext?["something"] as? String) ?? "")
                }
            }
        default: break
        }
        return text.chat.localize
    }
    
    @objc open var replyIcon: UIImage? {
        switch self.body.type {
        case .image:
            return UIImage(named: "reply_image", in: .chatBundle, with: nil)
        case .voice:
            return UIImage(named: "reply_audio", in: .chatBundle, with: nil)
        case .video:
            return UIImage(named: "reply_video", in: .chatBundle, with: nil)
        case .file:
            return UIImage(named: "reply_file", in: .chatBundle, with: nil)
        case .combine:
            return UIImage(named: "reply_history", in: .chatBundle, with: nil)
        case .location:
            return UIImage(named: "reply_location", in: .chatBundle, with: nil)
        case .custom:
            if let body = self.body as? ChatCustomMessageBody {
                if body.event == EaseChatUIKit_user_card_message {
                    return UIImage(named: "reply_contact", in: .chatBundle, with: nil)
                }
            }
            return nil
        default:
            return nil
        }
    }
    
    /// Message show content.
    @objc open var showContent: String {
        var text = ""
        switch self.body.type {
        case .text: text = (self.body as? ChatTextMessageBody)?.text ?? ""
        case .voice: text = "\((self.body as? ChatAudioMessageBody)?.duration ?? 0)″"
        case .file: text = "\((self.body as? ChatFileMessageBody)?.displayName ?? "")"
        case .location: text = self.showType
        case .custom:
            if let body = self.body as? ChatCustomMessageBody {
                if body.event == EaseChatUIKit_user_card_message {
                    let userId = body.customExt["uid"] ?? ""
                    text = body.customExt["nickname"] ?? userId
                }
                if body.event == EaseChatUIKit_alert_message {
                    text = (self.ext?["something"] as? String) ?? ""
                }
            }
        default: break
        }
        return text
    }
    
    /// Text message if you were mentioned,the property isn't empty.
    @objc public var mention: String {
        if self.body.type == .text && self.direction == .receive,let conversation = ChatClient.shared().chatManager?.getConversation(self.conversationId, type: .groupChat, createIfNotExist: false) {
            if conversation.type == .groupChat {
                if let ext = self.ext, let atList = ext["em_at_list"] {
                    if let atListString = atList as? String {
                        if atListString.lowercased() == "All".lowercased() {
                            return "All"
                        }
                    } else if let atListArray = atList as? [String] {
                        if ChatClient.shared().currentUsername?.count ?? 0 > 0 && atListArray.contains((ChatClient.shared().currentUsername ?? "").lowercased()) {
                            return (EaseChatUIKitContext.shared?.currentUser?.id ?? self.from).lowercased()
                        }
                    }
                }
            }
        }
        return ""
    }
    
    /// When you send a text message. Quote the message.
    @objc public var quoteMessage: ChatMessage? {
        guard let quoteInfo = self.ext?["msgQuote"] as? Dictionary<String,Any> else { return nil }
        guard let quoteMessageId = quoteInfo["msgID"] as? String else {
            return ChatMessage()
        }
        return ChatClient.shared().chatManager?.getMessageWithMessageId(quoteMessageId)
    }
    
    /// When you send a text message. Quote the message.
    @objc public var hasQuote: Bool {
        return !self.quoteMessageId.isEmpty
    }
    
    /// When you send a text message. Quote the message.
    @objc public var quoteMessageId: String {
        guard let quoteInfo = self.ext?["msgQuote"] as? Dictionary<String,Any>,let messageId = quoteInfo["msgID"] as? String else { return "" }
        return messageId
    }
    
    @objc open var contentSize: CGSize {
        switch self.body.type {
        case .custom:
            return extraCustomSize
        case .location:
            return CGSize(width: limitBubbleWidth, height: locationHeight)
        default:
            return CGSize(width: limitBubbleWidth, height: 30)
        }
    }
    
    /// Translation of the text message.
    @objc public var translation: String? {
        (self.body as? ChatTextMessageBody)?.translations?.first?.value
    }
    
}


