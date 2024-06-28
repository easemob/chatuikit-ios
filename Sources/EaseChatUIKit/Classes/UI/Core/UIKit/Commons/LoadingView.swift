//
//  LoadingView.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/9/22.
//

import UIKit

@objc public class LoadingView: UIView {
    
    let lightEffect = UIBlurEffect(style: UIBlurEffect.Style.light)
    
    let darkEffect = UIBlurEffect(style: UIBlurEffect.Style.dark)
    
    private lazy var activityIndicatorView: CustomActivityIndicator = {
        let activityIndicatorView = CustomActivityIndicator(frame: .zero)
        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        activityIndicatorView.setImage(UIImage(named: "spinner", in: .chatBundle, with: nil))
        return activityIndicatorView
    }()
    
    lazy var blur: UIVisualEffectView = {
        let blurView = UIVisualEffectView(effect: self.lightEffect).cornerRadius(.medium)
        return blurView
    }()
    
    lazy var indicatorText: UILabel = {
        UILabel().font(UIFont.theme.labelMedium).textColor(UIColor.theme.neutralColor98).text("Loading...".chat.localize).textAlignment(.center)
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupViews()
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        self.isHidden = true
        self.activityIndicatorView.stopAnimating()
    }
    
    private func setupViews() {
        self.isHidden = true
        self.addSubViews([self.blur,self.activityIndicatorView,self.indicatorText])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.blur.translatesAutoresizingMaskIntoConstraints = false
        self.indicatorText.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.blur.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.blur.centerYAnchor.constraint(equalTo: centerYAnchor),
            self.blur.widthAnchor.constraint(equalToConstant: 94),
            self.blur.heightAnchor.constraint(equalToConstant: 78)
        ])
        NSLayoutConstraint.activate([
            self.activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.activityIndicatorView.centerYAnchor.constraint(equalTo: centerYAnchor,constant: -12),
            self.activityIndicatorView.widthAnchor.constraint(equalToConstant: 36),
            self.activityIndicatorView.heightAnchor.constraint(equalToConstant: 36)
        ])
        NSLayoutConstraint.activate([
            self.indicatorText.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.indicatorText.bottomAnchor.constraint(equalTo: self.blur.bottomAnchor,constant: -12),
            self.indicatorText.widthAnchor.constraint(equalToConstant: 94),
            self.indicatorText.heightAnchor.constraint(equalToConstant: 18)
        ])
    }
    
    /// Start loading animation
    @MainActor public func startAnimating() {
        self.isHidden = false
        self.alpha = 1
        self.activityIndicatorView.startAnimating()
    }
    
    /// Stop loading animation
    @MainActor public func stopAnimating() {
        self.activityIndicatorView.stopAnimating()
        self.isHidden = true
        UIView.animate(withDuration: 0.2) {
            self.alpha = 0
        } completion: { _ in
        }
    }
    
}


extension LoadingView: ThemeSwitchProtocol {
    
    public func switchTheme(style: ThemeStyle) {
        self.blur.effect = style == .dark ? self.darkEffect:self.lightEffect
        self.backgroundColor = .clear
    }
}


@objc open class CustomActivityIndicator: UIView {
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            imageView.widthAnchor.constraint(equalTo: self.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }
    
    func setImage(_ image: UIImage?) {
        imageView.image = image
    }
    
    func startAnimating() {
        let rotation = CABasicAnimation(keyPath: "transform.rotation")
        rotation.fromValue = 0
        rotation.toValue = Double.pi * 2
        rotation.duration = 1
        rotation.repeatCount = Float.infinity
        imageView.layer.add(rotation, forKey: "rotationAnimation")
    }
    
    func stopAnimating() {
        imageView.layer.removeAnimation(forKey: "rotationAnimation")
    }
}
