//
//  DetailInfoHeader.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/22.
//

import UIKit


@objc open class DetailInfoHeader: UIView {
    
    /**
     A property representing the state of the user.

     The default value is `.online`. When the value of `userState` is set, the `willSet` block is executed on the main queue, updating the background color of the `status` view based on the new value.

     - Note: The `status` view is expected to be a subview of the `DetailInfoHeader` view.
     */
    @objc public var userState: UserState = .online {
        willSet {
            DispatchQueue.main.async {
                self.status.image = nil
                self.status.backgroundColor = newValue == .online ? (Theme.style == .dark ? UIColor.theme.secondaryColor6:UIColor.theme.secondaryColor5):(Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5)
            }
        }
    }
    
    /// Avatar url
    @objc public var avatarURL: String? {
        didSet {
            if let url = self.avatarURL {
                self.avatar.image(with: url, placeHolder: Appearance.avatarPlaceHolder)
            }
        }
    }
    
    /**
     A property representing the detail text of the header view.
     
     When the `detailText` property is set, it updates the `detail` button's attributed title with the provided text and an image attachment. The image attachment is created using the "copy" image from the "chatBundle" resource bundle. The appearance of the text and image is determined by the current theme style.
     */
    @objc public var detailText: String? {
        didSet {
            if let string = self.detailText {
                let text = NSMutableAttributedString(string: ("UserId".chat.localize+" "+string),attributes: [.font:UIFont.theme.bodySmall,.foregroundColor:(Theme.style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor6)])
                let imageAttachment = NSTextAttachment()
                imageAttachment.image = UIImage(named: "copy", in: .chatBundle, with: nil)?.withTintColor(Theme.style == .dark ? UIColor.theme.neutralColor4:UIColor.theme.neutralColor6)
                imageAttachment.bounds = CGRect(x: 0, y: -3, width: imageAttachment.image?.size.width ?? 0, height: imageAttachment.image?.size.height ?? 0)
                let imageAttribute = NSAttributedString(attachment: imageAttachment)
                text.append(imageAttribute)
                self.detail.setAttributedTitle(text, for: .normal)
            }
        }
    }
    
    private let itemWidth = Appearance.contact.detailExtensionActionItems.count > 3 ? ((ScreenWidth-8*CGFloat(Appearance.contact.detailExtensionActionItems.count-1)-40)/CGFloat(Appearance.contact.detailExtensionActionItems.count)):(114*ScreenWidth/390.0)
    
    public private(set) lazy var avatar: ImageView = {
        ImageView(frame: CGRect(x: self.frame.width/2.0-50, y: 20, width: 100, height: 100)).cornerRadius(Appearance.avatarRadius).backgroundColor(.clear)
    }()
    
    public private(set) lazy var status: UIImageView = {
        let r = self.avatar.frame.width / 2.0
        let length = CGFloat(sqrtf(Float(r)))
        let x = (Appearance.avatarRadius == .large ? (r + length + self.avatar.frame.width/4.0-3):(self.avatar.frame.width-16))
        let y = (Appearance.avatarRadius == .large ? (r + length + +self.avatar.frame.width/4.0-3):(self.avatar.frame.height-16))
        return UIImageView(frame: CGRect(x: self.avatar.frame.minX+x, y: self.avatar.frame.minY+y, width: 18, height: 18)).backgroundColor(UIColor.theme.secondaryColor5).cornerRadius(.large).layerProperties(UIColor.theme.neutralColor98, 2)
    }()
    
    public private(set) lazy var nickName: UILabel = {
        UILabel(frame: CGRect(x: 50, y: self.avatar.frame.maxY+12, width: self.frame.width-100, height: 28)).textAlignment(.center).font(UIFont.theme.headlineLarge)
    }()
    
    public private(set) lazy var detail: UIButton = {
        UIButton(type: .custom).frame(CGRect(x: 50, y: self.nickName.frame.maxY, width: self.frame.width-100, height: 32)).backgroundColor(.clear).addTargetFor(self, action: #selector(copyAction), for: .touchUpInside)
    }()
    
    public private(set) lazy var layout: UICollectionViewFlowLayout = {
        var flow = UICollectionViewFlowLayout()
        if Appearance.contact.detailExtensionActionItems.count <= 1 {
            flow = ChoiceItemLayout()
        }
        flow.itemSize = CGSize(width: self.itemWidth, height: 62)
        flow.minimumInteritemSpacing = 8
        flow.minimumInteritemSpacing = 0
        flow.scrollDirection = .horizontal
        return flow
    }()
    
    public private(set) lazy var itemList: UICollectionView = {
        let width = CGFloat((Int(self.itemWidth)*Appearance.contact.detailExtensionActionItems.count)+(Appearance.contact.detailExtensionActionItems.count-1)*8)
        return UICollectionView(frame: CGRect(x: 15, y: self.detail.frame.maxY+20, width: width+10, height: 62), collectionViewLayout: self.layout).delegate(self).dataSource(self).registerCell(DetailInfoHeaderExtensionCell.self, forCellReuseIdentifier: "DetailInfoHeaderExtensionCell").backgroundColor(.clear).showsHorizontalScrollIndicator(false)
    }()

    internal override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// ``DetailInfoHeader`` init method.
    /// - Parameters:
    ///   - frame: ``CGRect``
    ///   - showMenu: Whether show extension menu or not.
    ///   - placeHolder: Avatar place holder.
    @objc public required init(frame: CGRect,showMenu: Bool ,placeHolder: UIImage?) {
        super.init(frame: frame)
        if showMenu {
            self.addSubViews([self.avatar,self.status,self.nickName,self.detail,self.itemList])
            self.itemList.isScrollEnabled = false
            self.itemList.center = CGPoint(x: self.center.x, y: self.itemList.center.y)
        } else {
            self.addSubViews([self.avatar,self.status,self.nickName,self.detail])
        }
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.avatar.image = placeHolder
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func copyAction() {
        UIPasteboard.general.string = self.detail.titleLabel?.text?.components(separatedBy: ":").last
        UIViewController.currentController?.showToast(toast: "Copied".chat.localize)
    }
    
    @objc open func refreshHeader(showMenu: Bool) {
        if showMenu {
            let width = CGFloat((Int(self.itemWidth)*Appearance.contact.detailExtensionActionItems.count)+(Appearance.contact.detailExtensionActionItems.count-1)*8)
            self.itemList.frame = CGRect(x: 15, y: self.detail.frame.maxY+20, width: width+10, height: 62)
            self.itemList.center = CGPoint(x: self.center.x, y: self.itemList.center.y)
            if self.itemList.isHidden {
                self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.width, height: self.frame.height+82)
            }
            self.itemList.isHidden = false
        } else {
            self.itemList.isHidden = true
            self.itemList.frame = .zero
            self.frame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: self.frame.width, height: self.frame.height-82)
        }
        self.itemList.isHidden = !showMenu
    }
}

extension DetailInfoHeader: UICollectionViewDelegate,UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        Appearance.contact.detailExtensionActionItems.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(with: DetailInfoHeaderExtensionCell.self, reuseIdentifier: "DetailInfoHeaderExtensionCell", indexPath: indexPath) else { return DetailInfoHeaderExtensionCell() }
        if let item = Appearance.contact.detailExtensionActionItems[safe: indexPath.row] {
            cell.icon.image = item.featureIcon?.withTintColor(Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5)
            cell.title.text = item.featureName
        }
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        if let item = Appearance.contact.detailExtensionActionItems[safe: indexPath.row] {
            item.actionClosure?(item)
        }
    }
}

extension DetailInfoHeader: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.status.layerProperties(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98, 2)
        switch self.userState {
        case .online:
            self.status.backgroundColor = style == .dark ? UIColor.theme.secondaryColor6:UIColor.theme.secondaryColor5
        case .offline:
            self.status.backgroundColor = style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5
        }
        self.nickName.textColor = style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
    }
}
