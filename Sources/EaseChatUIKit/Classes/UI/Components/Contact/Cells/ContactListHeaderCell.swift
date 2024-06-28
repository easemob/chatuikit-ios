//
//  ContactListHeaderCell.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/20.
//

import UIKit


/// A protocol of the contact list item.
@objc public protocol ContactListHeaderItemProtocol: NSObjectProtocol {
    
    /// Identify of the feature
    var featureIdentify: String {set get}
    
    /// Name of the feature
    var featureName: String {set get}
    
    /// Icon of the feature
    var featureIcon: UIImage? {set get}
    
    /// Whether show badge on cell.
    var showBadge: Bool {set get}
    
    /// Whether show number on cell.
    var showNumber: Bool {set get}
    
    /// Display number.
    var numberCount: UInt {set get}
    
    /// When the cell clicked,callback.
    var actionClosure: ContactListItemActionClosure? {set get}
}


/// The header list cell of the contact list.
@objc open class ContactListHeaderCell: UITableViewCell {
    
    public private(set) lazy var badge: UILabel = {
        UILabel(frame: CGRect(x: self.frame.width-70, y: self.contentView.frame.height/2.0-9, width: 32, height: 18)).cornerRadius(.large).font(UIFont.theme.bodySmall)
    }()
    
    public private(set) lazy var separatorLine: UIView = {
        self.createSeparatorLine()
    }()
    
    @objc open func createSeparatorLine() -> UIView {
        UIView(frame: CGRect(x: 16, y: self.contentView.frame.height-0.5, width: self.contentView.frame.width-16, height: 0.5))
    }
        
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        self.imageView?.contentMode = .scaleAspectFit
        self.textLabel?.font = UIFont.theme.titleMedium
        self.textLabel?.textColor = UIColor.theme.neutralColor1
        self.contentView.addSubview(self.badge)
        self.contentView.addSubview(self.separatorLine)
//        self.accessoryView = self.badge
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.separatorLine.frame = CGRect(x: 16, y: self.contentView.frame.height-0.5, width: self.frame.width, height: 0.5)
    }
    
    /// Refresh cell on needed.
    /// - Parameter item: The object of conform ``ContactListItemProtocol``.
    @objc public func refresh(item: ContactListHeaderItemProtocol) {
        self.imageView?.image = item.featureIcon
        self.textLabel?.text = item.featureName
        if item.showBadge {
            self.badge.backgroundColor(Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).textColor(UIColor.theme.neutralColor98).textAlignment(.center)
        } else {
            self.badge.textAlignment(.right).textColor(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).backgroundColor(.clear)
        }
        if item.numberCount > 0 {
            self.badge.text = "\(item.numberCount)"
        } else {
            self.badge.text = nil
        }
        let badgeWidth = item.numberCount > 9 ? 32:18
        self.badge.frame = CGRect(x: Int(self.frame.width)-38-badgeWidth, y: Int(Appearance.contact.headerRowHeight/2.0)-9, width: badgeWidth, height: 18)
        if item.showNumber {
            self.badge.isHidden = item.numberCount <= 0
        } else {
            self.badge.isHidden = false
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension ContactListHeaderCell: ThemeSwitchProtocol {

    @objc open func switchTheme(style: ThemeStyle) {
        self.badge.backgroundColor(style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).textColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
        self.textLabel?.textColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
        self.accessoryView?.tintColor = style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor3
        self.accessoryView?.subviews.first?.tintColor = style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor3
        
        self.separatorLine.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor9
    }
}


public typealias ContactListItemActionClosure = ((ContactListHeaderItemProtocol) -> Void)

@objc final public class ContactListHeaderItem: NSObject,ContactListHeaderItemProtocol {
    
    public var numberCount: UInt = 0
    
    public var featureIdentify: String = ""
    
    public var featureName: String = ""
    
    public var featureIcon: UIImage?
    
    public var showBadge: Bool = false
    
    public var showNumber: Bool = false
    
    public var actionClosure: ContactListItemActionClosure?
    
    /// A convenience initializer for creating an ``ContactListItem`` object .
    /// - Parameters:
    ///   - featureName: The feature name of the contact header item
    ///   - featureIcon: The icon of the contact header item
    ///   - action: The callback on item clicked.
    @objc public init(featureIdentify: String ,featureName: String, featureIcon: UIImage?,action: @escaping ContactListItemActionClosure) {
        self.actionClosure = action
        self.featureIdentify = featureIdentify
        self.featureName = featureName
        self.featureIcon = featureIcon
        super.init()
    }

    
    /// A convenience initializer for creating an ``ContactListItem`` object .
    /// - Parameters:
    ///   - featureName: The feature name of the contact header item
    ///   - featureIcon: The icon of the contact header item
    @objc public init(featureIdentify: String ,featureName: String, featureIcon: UIImage?) {
        self.featureIcon = featureIcon
        self.featureName = featureName
        self.featureIdentify = featureIdentify
        super.init()
    }
    
    public override init() {
        super.init()
    }
}
