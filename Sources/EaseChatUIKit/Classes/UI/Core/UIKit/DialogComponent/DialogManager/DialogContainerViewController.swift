//
//  DialogContainerViewController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/9/6.
//

import UIKit
 /**
     A view controller that manages the presentation of a dialog container view and its content.
     - `presentedViewComponent`: An optional `PresentedViewComponent` object that represents the content view to be presented.
     - `customView`: An optional `UIView` object that represents a custom view to be presented.
     */
@objc final public class DialogContainerViewController:  UIViewController, PresentedViewType {
    
   
    public var presentedViewComponent: PresentedViewComponent? = PresentedViewComponent(contentSize: Appearance.pageContainerConstraintsSize,destination: .bottomBaseline,canTapBGDismiss: true)

    var customView: UIView?

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /**
     Initializes a new `DialogContainerViewController` instance with a custom view and optional constraints size.

     - Parameters:
        - custom: The custom view to be displayed in the dialog container.
        - constraintsSize: The size of the constraints to be applied to the dialog container's content view. Defaults to `.zero`.

     - Returns: A new `DialogContainerViewController` instance.
     */
    @objc public init(custom: UIView,constraintsSize:CGSize = .zero,canPanDismiss: Bool = true) {
        if constraintsSize != .zero {
            self.presentedViewComponent?.contentSize = constraintsSize
            self.presentedViewComponent?.canTapBGDismiss = canPanDismiss
        }
        self.customView = custom
        super.init(nibName: nil, bundle: nil)
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        if self.customView != nil {
            self.view.addSubview(self.customView!)
        }
    }
}

extension DialogContainerViewController {
    @objc private func keyboardWillShow(notification: Notification) {
        guard let keyboardFrame = notification.keyboardEndFrame else { return }
        let duration = notification.keyboardAnimationDuration!
        UIView.animate(withDuration: duration) {
            self.customView?.frame = CGRect(x: 0, y: ScreenHeight-keyboardFrame.height - self.customView!.frame.height, width: self.customView!.frame.width, height: self.customView!.frame.height)
        }
    }
}

