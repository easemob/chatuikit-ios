//
//  CustomTextView.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/28.
//

import UIKit

@objcMembers open class CustomTextView: UITextView {
    
    private var placeholderLabel: UILabel
    
    open var placeholder: String? {
        didSet {
            placeholderLabel.text = placeholder
        }
    }
    
    open override var text: String! {
        didSet {
            textDidChange()
        }
    }
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        placeholderLabel = UILabel()
        super.init(frame: frame, textContainer: textContainer)
        commonInit()
    }
    
    required public init?(coder: NSCoder) {
        placeholderLabel = UILabel()
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        placeholderLabel.textColor = Theme.style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor6
        placeholderLabel.numberOfLines = 0
        placeholderLabel.font = self.font
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)
        
        // 设置 textContainerInset 和 lineFragmentPadding
        self.textContainerInset = UIEdgeInsets(top: 8, left: 7, bottom: 7, right: 8)
        self.textContainer.lineFragmentPadding = 0
        
        // 设置占位符标签的约束
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: textContainerInset.top),
            placeholderLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: textContainerInset.left),
            placeholderLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -textContainerInset.right)
        ])
        
        NotificationCenter.default.addObserver(self, selector: #selector(textDidChange), name: UITextView.textDidChangeNotification, object: nil)
        
        textDidChange()
    }
    
    @objc private func textDidChange() {
        placeholderLabel.isHidden = !text.isEmpty
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 更新 placeholderLabel 的 frame
        let padding = textContainer.lineFragmentPadding
        let insets = textContainerInset
        placeholderLabel.frame = CGRect(
            x: padding + insets.left,
            y: insets.top,
            width: frame.width - padding * 2 - insets.left - insets.right,
            height: placeholderLabel.sizeThatFits(CGSize(width: frame.width - padding * 2 - insets.left - insets.right, height: CGFloat.greatestFiniteMagnitude)).height
        )
        
        // 在高度变化后强制更新光标位置
        DispatchQueue.main.async {
            self.scrollRangeToVisible(self.selectedRange)
        }
    }
}

