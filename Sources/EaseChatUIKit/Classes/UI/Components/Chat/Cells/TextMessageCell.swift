//
//  TextMessageCell.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/12/5.
//

import UIKit

@objc open class TextMessageCell: MessageCell {
    
    public var receiveStateColor: UIColor {
        Theme.style  == .dark ? UIColor.theme.neutralSpecialColor7:UIColor.theme.neutralSpecialColor5
    }
    
    public var sendStateColor: UIColor {
        Theme.style  == .dark ? UIColor.theme.primaryColor3:UIColor.theme.primaryColor9
    }
    
    public private(set) lazy var content: ActiveLabel = {
        self.createContent()
    }()
    
    @objc open func createContent() -> ActiveLabel {
        ActiveLabel(frame: .zero).backgroundColor(.clear).numberOfLines(0)
    }
    
    public private(set) lazy var edit: UIButton = {
        self.createEditSymbol()
    }()
    
    @objc open func createEditSymbol() -> UIButton {
        UIButton(type: .custom).frame(.zero).backgroundColor(.clear).font(UIFont.theme.labelSmall)
    }
    
    public private(set) lazy var separatorLine: UIView = {
        UIView(frame: .zero)
    }()
    
    public private(set) lazy var translationContainer: TranslateTextView = {
        self.createTranslationContainer()
    }()
    
    @objc open func createTranslationContainer() -> TranslateTextView {
        TranslateTextView(frame: .zero).backgroundColor(.clear).isEditable(false)
    }
    
    public private(set) lazy var translation: UILabel = {
        self.createTranslation()
    }()
    
    @objc open func createTranslation() -> UILabel {
        UILabel(frame: .zero).backgroundColor(.clear).numberOfLines(0)
    }
    
    public private(set) lazy var translateSymbol: UIButton = {
        self.createTranslateSymbol()
    }()
    
    @objc open func createTranslateSymbol() -> UIButton {
        UIButton(type: .custom).frame(.zero).backgroundColor(.clear).font(UIFont.theme.labelSmall)
    }
    
    public private(set) lazy var previewContent: URLPreviewResultView = {
        self.createPreviewContent()
    }()
    
    @objc open func createPreviewContent() -> URLPreviewResultView {
        URLPreviewResultView(frame: CGRect(x: 0, y: self.frame.height-38, width: limitBubbleWidth, height: 38))
    }
    
    @objc required public init(towards: BubbleTowards,reuseIdentifier: String) {
        super.init(towards: towards, reuseIdentifier: reuseIdentifier)
        if Appearance.chat.bubbleStyle == .withArrow {
            self.bubbleWithArrow.addSubViews([self.content,self.edit])
            if Appearance.chat.enableTranslation {
                self.bubbleWithArrow.addSubViews([self.separatorLine,self.translationContainer,self.translation,self.translateSymbol])
                if Appearance.chat.enableURLPreview {
                    self.bubbleWithArrow.addSubViews([self.previewContent])
                }
            }
            self.addGestureTo(view: self.bubbleWithArrow, target: self)
        } else {
            self.bubbleMultiCorners.addSubViews([self.content,self.edit])
            if Appearance.chat.enableTranslation {
                self.bubbleMultiCorners.addSubViews([self.separatorLine,self.translationContainer,self.translation,self.translateSymbol])
            }
            if Appearance.chat.enableURLPreview {
                self.bubbleMultiCorners.addSubViews([self.previewContent])
            }
            self.addGestureTo(view: self.bubbleMultiCorners, target: self)
        }
        self.translationContainer.isScrollEnabled = false
        self.translationContainer.showsVerticalScrollIndicator = false
        self.translationContainer.showsHorizontalScrollIndicator = false
        self.translationContainer.isSelectable = true
        self.translationContainer.isUserInteractionEnabled = true
        self.edit.contentHorizontalAlignment = .right
        self.translateSymbol.contentHorizontalAlignment = .right
        self.previewContent.isHidden = true
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func refresh(entity: MessageEntity) {
        super.refresh(entity: entity)
        let textSize = entity.textSize()
        let translationSize = Appearance.chat.enableTranslation ? entity.translationSize():.zero
        self.content.frame = CGRect(x: 12, y: 6.5, width: entity.bubbleSize.width-24, height: textSize.height)
        self.content.customize { [weak self] in
            self?.customizeContent(label: $0,entity: entity,textSize: textSize)
        }
        let stateColor: UIColor = entity.message.direction == .send ? self.sendStateColor:self.receiveStateColor
        self.edit.setTitleColor(stateColor, for: .normal)
        self.translateSymbol.setTitleColor(stateColor, for: .normal)
        if entity.message.direction == .send {
            self.separatorLine.backgroundColor(Theme.style == .dark ? UIColor.theme.primaryColor9:UIColor.theme.primaryColor8)
        } else {
            self.separatorLine.backgroundColor(Theme.style == .dark ? UIColor.theme.neutralSpecialColor7:UIColor.theme.neutralSpecialColor8)
        }

        if entity.message.edited {
            self.edit.isHidden = false
            self.edit.frame = CGRect(x: 12, y: self.content.frame.maxY, width: entity.bubbleSize.width-24, height: 16)
            let image = UIImage(named: "text_message_edited", in: .chatBundle, with: nil)
            self.edit.image(image?.withTintColor(stateColor), .normal)
            self.edit.setTitle("Edited".chat.localize, for: .normal)
        } else {
            self.edit.isHidden = true
            self.edit.frame = .zero
        }
        
        if entity.showTranslation,Appearance.chat.enableTranslation {
            self.translation.attributedText = entity.translation
            self.separatorLine.isHidden = false
            self.translation.isHidden = false
            self.translateSymbol.isHidden = false
            self.separatorLine.frame = CGRect(x: 12, y: (entity.message.edited ? self.edit.frame.maxY+8:self.content.frame.maxY+6), width: entity.bubbleSize.width-24, height: 0.5)
            self.translationContainer.frame = CGRect(x: 12, y: self.separatorLine.frame.maxY+8, width: entity.bubbleSize.width-24, height: translationSize.height)
            self.translation.frame = CGRect(x: 12, y: self.separatorLine.frame.maxY+8, width: entity.bubbleSize.width-24, height: translationSize.height)
            var symbolY = entity.bubbleSize.height - 20
            if Appearance.chat.enableURLPreview {
                symbolY = self.translation.frame.maxY
            }
            self.translateSymbol.frame = CGRect(x: 12, y: symbolY, width: entity.bubbleSize.width-24, height: 16)
            self.translateSymbol.setTitle("Translated".chat.localize, for: .normal)
            let image = UIImage(named: "text_message_translated", in: .chatBundle, with: nil)
            self.translateSymbol.image(image?.withTintColor(stateColor), .normal)
        } else {
            self.separatorLine.isHidden = true
            self.translation.isHidden = true
            self.translateSymbol.isHidden = true
        }
        if Appearance.chat.enableURLPreview {
            self.previewContent.state = entity.previewResult
            let previewHeight = entity.urlPreviewHeight()
            self.previewContent.frame = CGRect(x: 0, y: entity.bubbleSize.height-previewHeight+4, width: entity.bubbleSize.width, height: previewHeight)
            switch entity.previewResult {
            case .success:
                self.previewContent.show(with: entity.urlPreview)
            default: break
            }
            self.previewContent.isHidden = previewHeight <= 0
        }
        
    }
    
    @objc open func customizeContent(label: ActiveLabel, entity: MessageEntity, textSize: CGSize) {
        label.frame = CGRect(x: 12, y: 6.5, width: entity.bubbleSize.width-24, height: textSize.height+2)
        let receiveLinkColor = Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5
        label.font = UIFont.theme.bodyMedium
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.URLColor = (entity.message.direction == .send ? Appearance.chat.sendTextColor:receiveLinkColor)
        label.URLSelectedColor = Theme.style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor9
        label.attributedText = entity.content
        
        label.handleURLTap { url in
            var urlString = url.absoluteString
            if !urlString.hasPrefix("http://"), !urlString.hasPrefix("https://") {
                urlString = "https://" + urlString
            } else {
                if urlString.hasPrefix("http://") {
                    urlString.insert("s", at: 4)
                }
            }
            if let validateURL = URL(string: urlString) {
                UIApplication.shared.open(validateURL)
            }
            
        }
    }
    
    
    
}


@objc open class TranslateTextView: UITextView {
    // 确保 UITextView 可以响应复制操作
    open override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return true
        }
        return super.canPerformAction(action, withSender: sender)
    }
    
    // 处理复制操作
    open override func copy(_ sender: Any?) {
        if let selectedTextRange = self.selectedTextRange {
            let selectedText = self.text(in: selectedTextRange)
            UIPasteboard.general.string = selectedText
        }
    }

}
