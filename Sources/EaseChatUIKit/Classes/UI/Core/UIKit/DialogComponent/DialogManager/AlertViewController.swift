//
//  AlertViewController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/9/22.
//

import UIKit

@objc open class AlertViewController: UIViewController , PresentedViewType {
    
    public var presentedViewComponent: PresentedViewComponent?

    var customView: UIView?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
     Initializes a new `AlertViewController` instance with a custom view and optional constraints size.

     - Parameters:
        - custom: The custom view to be displayed in the dialog container.
     - Returns: A new `AlertViewController` instance.
     */
    @objc public required convenience init(custom: UIView,size: CGSize,customPosition: Bool) {
        self.init()
        if customPosition {
            self.presentedViewComponent = PresentedViewComponent(contentSize: size,destination: .custom(center: CGPoint(x: ScreenWidth/2.0-custom.frame.width/2.0, y: ScreenHeight/2.0-custom.frame.height/2.0)))
        } else {
            self.presentedViewComponent = PresentedViewComponent(contentSize: size,destination: .center)
        }
        self.customView = custom
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        if self.customView != nil {
            self.customView?.cornerRadius(Appearance.alertStyle == .small ? .extraSmall:.medium)
            self.view.addSubview(self.customView!)
        }
    }
}

@objcMembers open class AlertView: UIView {
    private var cancelClosure:(()->())?
    private var sureClosure:((String?)->())?
    private var rightClosure:(()->())?
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 16
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private lazy var titleLabelContainer: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.textColor = UIColor(red: 27/255.0, green: 16/255.0, blue: 103/255.0, alpha: 1.0)
        label.font = UIFont.theme.titleLarge
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.numberOfLines = 0
        label.textColor = Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5
        label.font = UIFont.theme.labelMedium
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()
    public private(set) lazy var textField: UITextField = {
       let textField = UITextField()
        textField.placeholder = "Aa"
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.isHidden = true
        textField.leftView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 10, height: 10)))
        textField.leftViewMode = .always
        return textField
    }()
    private lazy var textFieldLineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 195/255.0, green: 197/255.0, blue: 254/255.0, alpha: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    private lazy var buttonContainerView: UIView = {
        let view = UIView()
        return view
    }()
    private lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.spacing = 7
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    private lazy var leftButton: UIButton = {
        let button = UIButton()
        button.setTitle("barrage_long_press_menu_cancel".chat.localize, for: .normal)
        button.setTitleColor(UIColor(red: 120/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.theme.headlineSmall
        button.layer.cornerRadius = 25
        button.layer.borderColor = UIColor(red: 120/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1.0).cgColor
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(clickCancelButton), for: .touchUpInside)
        return button
    }()
    private lazy var rightButton: UIButton = {
        let button = UIButton()
        button.setTitle("Confirm".chat.localize, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.theme.headlineSmall
        button.layer.cornerRadius = 25
        button.backgroundColor = UIColor(red: 120/255.0, green: 0/255.0, blue: 255/255.0, alpha: 1.0)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.isHidden = true
        button.addTarget(self, action: #selector(clickSureButton), for: .touchUpInside)
        return button
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark")?.withTintColor(.darkGray, renderingMode: .alwaysOriginal),
                        for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(clickCloseButton), for: .touchUpInside)
        button.isHidden = true
        return button
    }()
    
    private var placeHolderColor: UIColor?
    private var placeHolderFont: UIFont?
    
    //MARK: Public
    public func background(color: UIColor?) -> AlertView {
        backgroundColor = color
        return self
    }
    public func isShowCloseButton(isShow: Bool) -> AlertView {
        closeButton.isHidden = !isShow
        return self
    }
    public func title(title: String?) -> AlertView {
        titleLabelContainer.isHidden = title == nil
        titleLabel.text = title
        return self
    }
    public func titleColor(color: UIColor?) -> AlertView {
        titleLabel.textColor = color
        return self
    }
    public func titleFont(font: UIFont?) -> AlertView {
        titleLabel.font = font
        return self
    }
    public func content(content: String?) -> AlertView {
        contentLabel.isHidden = content == nil
        contentLabel.text = content
        return self
    }
    public func contentTextAlignment(textAlignment: NSTextAlignment) -> AlertView {
        contentLabel.textAlignment = textAlignment
        return self
    }
    
    public func contentAttributes(content: NSAttributedString?) -> AlertView {
        contentLabel.isHidden = content == nil
        contentLabel.attributedText = content
        return self
    }
    public func contentColor(color: UIColor?) -> AlertView {
        contentLabel.textColor = color
        return self
    }
    public func contentFont(font: UIFont?) -> AlertView {
        contentLabel.font = font
        return self
    }
    public func textField(text: String?) -> AlertView {
        textField.isHidden = text == nil
        textField.text = text
        return self
    }
    public func textField(color: UIColor?) -> AlertView {
        textField.textColor = color
        return self
    }
    public func textField(font: UIFont?) -> AlertView {
        textField.font = font
        return self
    }
    public func textField(leftView: UIView?) -> AlertView {
        textField.leftView = leftView
        return self
    }
    public func textField(cornerRadius: CGFloat) -> AlertView {
        textField.layer.cornerRadius = cornerRadius
        textField.layer.masksToBounds = true
        return self
    }
    @discardableResult
    public func textFieldRadius(cornerRadius: CornerRadius) -> AlertView {
        textField.cornerRadius(cornerRadius)
        return self
    }
    
    public func textField(showBottomDivider: Bool) -> AlertView {
        textFieldLineView.isHidden = !showBottomDivider
        return self
    }
    public func textField(bottomDividerColor: UIColor?) -> AlertView {
        textFieldLineView.backgroundColor = bottomDividerColor
        return self
    }
    @discardableResult
    public func textFieldBackground(color: UIColor?) -> AlertView {
        textField.backgroundColor = color
        return self
    }
    public func textFieldPlaceholder(placeholder: String?) -> AlertView {
        textField.isHidden = placeholder == nil
        textField.placeholder = placeholder
        return self
    }
    public func textFieldPlaceholder(color: UIColor?) -> AlertView {
        guard let color = color else { return self }
        placeHolderColor = color
        var attribute = NSAttributedString(string: textField.placeholder ?? "",
                                      attributes: [.foregroundColor: color])
        if let font = placeHolderFont {
            attribute = NSAttributedString(string: textField.placeholder ?? "",
                                      attributes: [.foregroundColor: color,
                                                   .font: font])
        }
        textField.attributedPlaceholder = attribute
        return self
    }
    public func textFieldPlaceholder(font: UIFont?) -> AlertView {
        guard let font = font else { return self }
        placeHolderFont = font
        var attribute = NSAttributedString(string: textField.placeholder ?? "",
                                      attributes: [.font: font])
        if let color = placeHolderColor  {
            attribute = NSAttributedString(string: textField.placeholder ?? "",
                                      attributes: [.font: font,
                                                   .foregroundColor: color])
        }
        textField.attributedPlaceholder = attribute
        return self
    }
    @discardableResult
    public func textFieldRightView(rightView: UIView) -> AlertView {
        textField.rightView = rightView
        textField.rightViewMode = .always
        return self
    }
    @discardableResult
    public func textFieldDelegate(delegate: UITextFieldDelegate) -> AlertView {
        textField.delegate = delegate
        return self
    }
    
    @discardableResult
    public func leftButton(title: String?) -> AlertView {
        leftButton.isHidden = title == nil
        leftButton.setTitle(title, for: .normal)
        return self
    }
    @discardableResult
    public func leftButton(color: UIColor?) -> AlertView {
        leftButton.setTitleColor(color, for: .normal)
        return self
    }
    @discardableResult
    public func leftButton(font: UIFont?) -> AlertView {
        leftButton.titleLabel?.font = font
        return self
    }
    @discardableResult
    public func leftButton(cornerRadius: CGFloat) -> AlertView {
        leftButton.layer.cornerRadius = cornerRadius
        leftButton.layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    public func leftButtonRadius(cornerRadius: CornerRadius) -> AlertView {
        leftButton.cornerRadius(cornerRadius == .large ? 25:CGFloat(cornerRadius.rawValue))
        return self
    }
    
    @discardableResult
    public func leftButtonBackground(color: UIColor?) -> AlertView {
        leftButton.backgroundColor = color
        return self
    }
    @discardableResult
    public func leftButtonBorder(color: UIColor?) -> AlertView {
        leftButton.layer.borderColor = color?.cgColor
        return self
    }
    @discardableResult
    public func leftButtonBorder(width: CGFloat) -> AlertView {
        leftButton.layer.borderWidth = width
        return self
    }
    @discardableResult
    public func leftButtonTapClosure(onTap: @escaping () -> Void) -> AlertView {
        cancelClosure = onTap
        return self
    }
    @discardableResult
    public func rightButton(title: String?) -> AlertView {
        rightButton.isHidden = title == nil
        rightButton.setTitle(title, for: .normal)
        return self
    }
    @discardableResult
    public func rightButton(color: UIColor?) -> AlertView {
        rightButton.setTitleColor(color, for: .normal)
        return self
    }
    @discardableResult
    public func rightButton(font: UIFont?) -> AlertView {
        rightButton.titleLabel?.font = font
        return self
    }
    @discardableResult
    public func rightButton(cornerRadius: CGFloat) -> AlertView {
        rightButton.layer.cornerRadius = cornerRadius
        rightButton.layer.masksToBounds = true
        return self
    }
    
    @discardableResult
    public func rightButtonRadius(cornerRadius: CornerRadius) -> AlertView {
        rightButton.cornerRadius(cornerRadius == .large ? 25:CGFloat(cornerRadius.rawValue))
        return self
    }
    
    @discardableResult
    public func rightButtonBackground(color: UIColor?) -> AlertView {
        rightButton.backgroundColor = color
        return self
    }
    @discardableResult
    public func rightButtonBorder(color: UIColor?) -> AlertView {
        rightButton.layer.borderColor = color?.cgColor
        return self
    }
    @discardableResult
    public func rightButtonBorder(width: CGFloat) -> AlertView {
        rightButton.layer.borderWidth = width
        return self
    }
    @discardableResult
    public func rightButtonTapClosure(onTap: @escaping (String?) -> Void) -> AlertView {
        sureClosure = onTap
        return self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(stackView)
        titleLabelContainer.addSubview(titleLabel)
        addSubview(closeButton)
        stackView.addArrangedSubview(titleLabelContainer)
        stackView.addArrangedSubview(contentLabel)
        stackView.addArrangedSubview(textField)
        textField.addSubview(textFieldLineView)
        stackView.addArrangedSubview(buttonContainerView)
        buttonContainerView.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(leftButton)
        buttonStackView.addArrangedSubview(rightButton)
        
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor(red: 0.106, green: 0.063, blue: 0.404, alpha: 0.2).cgColor
        layer.shadowRadius = 40
        layer.shadowOpacity = 1
        layer.shadowOffset = CGSize(width: 0, height: 0)
        translatesAutoresizingMaskIntoConstraints = false
        widthAnchor.constraint(equalToConstant: Appearance.alertContainerConstraintsSize.width).isActive = true
        
        stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: (ScreenWidth-Appearance.alertContainerConstraintsSize.width)/2.0).isActive = true
        stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -(ScreenWidth-Appearance.alertContainerConstraintsSize.width)/2.0).isActive = true
        stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        stackView.topAnchor.constraint(equalTo: topAnchor, constant: (ScreenWidth-Appearance.alertContainerConstraintsSize.width)/2.0).isActive = true
        
        titleLabel.topAnchor.constraint(equalTo: titleLabelContainer.topAnchor).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: titleLabelContainer.centerXAnchor).isActive = true
        titleLabel.bottomAnchor.constraint(equalTo: titleLabelContainer.bottomAnchor, constant: -16).isActive = true
        
        closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 10).isActive = true
        closeButton.widthAnchor.constraint(equalToConstant: 20).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: 20).isActive = true
        
        textField.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        textFieldLineView.leadingAnchor.constraint(equalTo: textField.leadingAnchor).isActive = true
        textFieldLineView.bottomAnchor.constraint(equalTo: textField.bottomAnchor).isActive = true
        textFieldLineView.trailingAnchor.constraint(equalTo: textField.trailingAnchor).isActive = true
        textFieldLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        buttonStackView.topAnchor.constraint(equalTo: buttonContainerView.topAnchor, constant: 16).isActive = true
        buttonStackView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        buttonStackView.leadingAnchor.constraint(equalTo: buttonContainerView.leadingAnchor).isActive = true
        buttonStackView.trailingAnchor.constraint(equalTo: buttonContainerView.trailingAnchor).isActive = true
        buttonStackView.bottomAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -16).isActive = true
    }
    
    @objc
    private func clickCancelButton(){
        let vc = UIViewController.currentController?.presentingViewController
        if vc != nil {
            vc?.dismiss(animated: true)
        } else {
            UIViewController.currentController?.dismiss(animated: true)
        }
        textField.endEditing(true)
        cancelClosure?()
    }
    
    @objc
    private func clickSureButton(){
        let vc = UIViewController.currentController?.presentingViewController
        if vc != nil {
            vc?.dismiss(animated: true)
        } else {
            UIViewController.currentController?.dismiss(animated: true)
        }
        textField.endEditing(true)
        sureClosure == nil ? rightClosure?() : sureClosure?(textField.text)
    }
    @objc
    private func clickCloseButton() {
        let vc = UIViewController.currentController?.presentingViewController
        if vc != nil {
            vc?.dismiss(animated: true)
        } else {
            UIViewController.currentController?.dismiss(animated: true)
        }
        textField.endEditing(true)
    }
}
