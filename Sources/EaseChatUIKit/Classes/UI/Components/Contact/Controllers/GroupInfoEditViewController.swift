//
//  GroupInfoEditViewController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/27.
//

import UIKit

@objc open class GroupInfoEditViewController: UIViewController {
    
    private let service: GroupService = GroupServiceImplement()
    
    public private(set) var groupId: String = ""
    
    public private(set) var raw: String = ""
    
    private var modifySuccess: ((String) -> ())?
    
    public private(set) var editType = GroupInfoEditType.name
    
    public private(set) lazy var navigation: EaseChatNavigationBar = {
        EaseChatNavigationBar(textAlignment: .left,rightTitle: "Save".chat.localize)
    }()
    
    public private(set) lazy var container: UIView = {
        UIView(frame: CGRect(x: 16, y: self.navigation.frame.maxY+16, width: self.view.frame.width-32, height: 114)).backgroundColor(Theme.style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor95).cornerRadius(.extraSmall)
    }()
    
    public private(set) lazy var contentEditor: UITextView = {
        UITextView(frame: CGRect(x: 16, y: self.container.frame.minY+13, width: self.view.frame.width-32, height: 114-38)).delegate(self).font(UIFont.theme.bodyLarge).backgroundColor(.clear)
    }()
    
    public private(set) lazy var limitCount: UILabel = {
        UILabel(frame: CGRect(x: self.container.frame.maxX-70, y: self.container.frame.maxY-35, width: 54, height: 22)).font(UIFont.theme.bodyLarge).textColor(Theme.style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor7).textAlignment(.right)
    }()
    
    @objc public required convenience init(groupId: String,type: GroupInfoEditType,rawText: String,modifyClosure: @escaping (String) -> Void) {
        self.init()
        self.groupId = groupId
        self.editType = type
        self.raw = rawText
        self.modifySuccess = modifyClosure
    }


    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.contentEditor.bounces = false
        self.contentEditor.showsVerticalScrollIndicator = false
        self.contentEditor.showsHorizontalScrollIndicator = false
        
        self.contentEditor.contentInset = UIEdgeInsets(top: -8, left: 10, bottom: 0, right: 10)
//        self.contentEditor.placeHolderColor = Theme.style == .dark ? UIColor.theme.neutralColor5:UIColor.theme.neutralColor6
        let content = self.titleForHeader()
//        self.contentEditor.placeHolder = "Please input".chat.localize
        self.navigation.title = content
        self.contentEditor.text = self.raw
        self.navigation.clickClosure = { [weak self] in
            self?.navigationClick(type: $0, indexPath: $1)
        }
        self.view.addSubViews([self.navigation,self.container,self.contentEditor,self.limitCount])
        self.contentEditor.text = self.raw
        self.limitCount.text = "\(self.raw.count)/\(self.textLimit())"
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.contentEditor.becomeFirstResponder()
    }
    
    private func titleForHeader() -> String {
        var text = ""
        switch self.editType {
        case .name: text = "group_details_button_name".chat.localize
        case .alias: text = "group_details_button_alias".chat.localize
        case .description: text = "group_details_button_description".chat.localize
        case .announcement: text = "group_details_button_announcement".chat.localize
        case .threadName: text = "thread_name".chat.localize
        }
        return text
    }
    
    private func navigationClick(type: EaseChatNavigationBarClickEvent,indexPath: IndexPath?) {
        switch type {
        case .back: self.pop()
        case .rightTitle: self.save()
        default:
            break
        }
    }
    
    private func textLimit() -> Int {
        var limitCount = 64
        switch self.editType {
        case .name,.threadName:
            limitCount = 32
        case .description,.announcement:
            limitCount = 256
        default:
            break
        }
        return limitCount
    }
    
    private func save() {
        self.view.endEditing(true)
        guard let text = self.contentEditor.text  else { return }
        if text.count > self.textLimit() {
            self.showToast(toast: "Reach content character limit.".chat.localize)
        } else {
            self.service.update(type: self.editType, content: text, groupId: self.groupId) { [weak self] group, error in
                if error == nil {
                    self?.modifySuccess?(text)
                    self?.pop()
                } else {
                    consoleLogInfo("GroupInfoEditViewController error:\(error?.errorDescription ?? "")", type: .error)
                }
            }
        }
        
    }
    
    private func pop() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

}

extension GroupInfoEditViewController: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        self.navigation.rightItem.isEnabled = (!(textView.text ?? "").isEmpty || !text.isEmpty)
        if (textView.text ?? "").count > self.textLimit(),!text.isEmpty {
            self.showToast(toast: "Reach content character limit.".chat.localize)
            return false
        } else {
            return true
        }
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        let limitCount = self.textLimit()
        let count = (textView.text ?? "").count
        if count > limitCount {
            self.showToast(toast: "Reach content character limit.".chat.localize)
            textView.text = textView.text.chat.subStringTo(limitCount)
        }
        self.limitCount.text = "\(count)/\(limitCount)"
    }
}

extension GroupInfoEditViewController: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.contentEditor.textColor(style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1)
    }
    
    
}
