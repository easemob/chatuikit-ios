//
//  URLPreviewResultView.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/19.
//

import UIKit

@objc public enum URLPreviewResult: UInt8 {
    case parsing
    case success
    case failure
}

@objc open class URLPreviewResultView: UIView {
    
    @MainActor @objc public var state: URLPreviewResult = .parsing {
        didSet {
            switch state {
            case .parsing:
                showLoadingState()
            case .failure:
                showErrorState()
            default: break
            }
        }
    }

    public private(set) var imageView: ImageView = {
        let imageView = ImageView(frame: .zero).contentMode(.scaleAspectFill)
        imageView.clipsToBounds = true
        return imageView
    }()
    
    public private(set) var titleLabel: UILabel = {
        UILabel(frame: .zero).font(UIFont.theme.headlineSmall).numberOfLines(2).backgroundColor(.clear).lineBreakMode(.byTruncatingTail)
    }()
    
    public private(set) var descriptionLabel: UILabel = {
        UILabel(frame: .zero).font(UIFont.theme.bodyMedium).numberOfLines(3).backgroundColor(.clear).lineBreakMode(.byTruncatingTail)
    }()
    
    public private(set) var loadingLabel: UILabel = {
        UILabel(frame: .zero).text("Parsing...".chat.localize).font(UIFont.theme.bodyExtraSmall).backgroundColor(.clear)
    }()
    
    public private(set) var imageHeightConstraint: NSLayoutConstraint!
    public private(set) var titleTopConstraint: NSLayoutConstraint!
    public private(set) var descriptionTopConstraint: NSLayoutConstraint!
    public private(set) var contentHeightConstraint: NSLayoutConstraint!
    
    private var shapeLayer = CAShapeLayer()

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupViews()
    }
    
    @objc public func setupViews() {
        self.backgroundColor = .clear
        self.addSubview(self.imageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.descriptionLabel)
        self.addSubview(self.loadingLabel)
        
        self.imageView.translatesAutoresizingMaskIntoConstraints = false
        self.titleLabel.translatesAutoresizingMaskIntoConstraints = false
        self.descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        self.loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.imageHeightConstraint = self.imageView.heightAnchor.constraint(equalToConstant: urlPreviewImageHeight)
        self.titleTopConstraint = self.titleLabel.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 8)
        self.descriptionTopConstraint = self.descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4)
        self.contentHeightConstraint = self.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)

        
        NSLayoutConstraint.activate([
            self.loadingLabel.leadingAnchor.constraint(equalTo: leadingAnchor,constant: 12),
            self.loadingLabel.trailingAnchor.constraint(equalTo: trailingAnchor,constant: 12),
            self.loadingLabel.topAnchor.constraint(equalTo: topAnchor,constant: 11),
            self.loadingLabel.heightAnchor.constraint(equalToConstant: 16),
            
            self.imageView.topAnchor.constraint(equalTo: topAnchor),
            self.imageView.leadingAnchor.constraint(equalTo: leadingAnchor,constant: -0.5),
            self.imageView.trailingAnchor.constraint(equalTo: trailingAnchor,constant: 0.5),
            self.imageHeightConstraint,
            
            self.titleTopConstraint,
            self.titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            self.titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            self.titleLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 22),
            
            self.descriptionTopConstraint,
            self.descriptionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            self.descriptionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            self.descriptionLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            self.contentHeightConstraint
        ])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    
    @objc open func show(with content: URLPreviewManager.HTMLContent?) {
        self.titleLabel.isHidden = false
        self.loadingLabel.isHidden = true
        self.titleLabel.attributedText = content?.titleAttribute
        self.descriptionLabel.text = content?.descriptionHTML
        self.contentHeightConstraint = self.heightAnchor.constraint(greaterThanOrEqualToConstant: self.frame.height)
        if let url = content?.imageURL,!url.isEmpty {
            self.imageView.isHidden = false
            self.imageHeightConstraint.constant = urlPreviewImageHeight
            self.imageView.image(with: url, placeHolder: nil)
            self.titleTopConstraint = self.titleLabel.topAnchor.constraint(equalTo: self.imageView.bottomAnchor, constant: 8)
        } else {
            self.imageView.isHidden = true
            self.imageHeightConstraint.constant = 0
            self.titleTopConstraint.constant = 8
        }
        
        
        if let description = content?.descriptionHTML, !description.isEmpty {
            self.descriptionLabel.isHidden = false
            self.descriptionTopConstraint.constant = 4
        } else {
            self.descriptionLabel.isHidden = true
            self.descriptionTopConstraint.constant = 0
        }
        self.layoutIfNeeded()
    }
    
    @objc open func showLoadingState() {
        self.imageView.isHidden = true
        self.titleLabel.isHidden = true
        self.descriptionLabel.isHidden = true
        self.loadingLabel.isHidden = false
    }
    
    @objc open func showErrorState() {
        self.imageView.isHidden = true
        self.titleLabel.isHidden = true
        self.descriptionLabel.isHidden = true
        self.loadingLabel.isHidden = true
        self.contentHeightConstraint.constant = 0
        self.layoutIfNeeded()
    }

}

extension URLPreviewResultView: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.loadingLabel.textColor = style == .dark ? UIColor.theme.neutralColor7:UIColor.theme.neutralColor6
        self.descriptionLabel.textColor = style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
        self.imageView.backgroundColor = style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor9
    }
}
