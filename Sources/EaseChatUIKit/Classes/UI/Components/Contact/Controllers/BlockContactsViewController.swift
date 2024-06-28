//
//  BlockContactsViewController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/4.
//

import UIKit

open class BlockContactsViewController: UIViewController {
    
    @UserDefault("EaseChatUIKit_contact_block_list_exist", defaultValue: Dictionary<String,Bool>()) public private(set) var blockListExist
    
    public private(set) lazy var navigation: EaseChatNavigationBar = {
        self.createNavigation()
    }()
    
    /**
     Creates and returns a navigation bar for the ContactViewController.
     
     - Returns: An instance of EaseChatNavigationBar.
     */
    @objc open func createNavigation() -> EaseChatNavigationBar {
        EaseChatNavigationBar(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: NavigationHeight),textAlignment: .left).backgroundColor(.clear)
    }
    
    public private(set) lazy var search: UIButton = {
        self.createSearch()
    }()
    
    /**
     Creates a search button with a custom frame and appearance.

     - Returns: The created search button.
     */
    @objc open func createSearch() -> UIButton {
        UIButton(type: .custom).frame(CGRect(x: 16, y: self.navigation.frame.maxY + 5, width: self.view.frame.width-32, height: 36)).backgroundColor(UIColor.theme.neutralColor95).textColor(UIColor.theme.neutralColor6, .normal).title("Search".chat.localize, .normal).image(UIImage(named: "search", in: .chatBundle, with: nil), .normal).addTargetFor(self, action: #selector(searchAction), for: .touchUpInside).cornerRadius(Appearance.avatarRadius)
    }
    
    public private(set) lazy var contactList: ContactView = {
        self.createContactList()
    }()
    
    /**
     Creates a contact list view.

     - Returns: A `ContactView` instance.
     */
    @objc open func createContactList() -> ContactView {
        ContactView(frame: CGRect(x: 0, y: self.search.frame.maxY+10, width: self.view.frame.width, height: self.view.frame.height-self.search.frame.maxY-10),headerStyle: .contact).backgroundColor(.clear)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.addSubViews([self.navigation,self.search,self.contactList])
        self.contactList.contactList.tableHeaderView = nil
        self.navigation.title = "block_list".chat.localize
        self.navigation.clickClosure = { [weak self] _,_ in
            self?.pop()
        }
        self.contactList.selectClosure = { [weak self] in
            self?.viewProfile(profile: $0)
        }
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fetchBlockList()
    }
    
    @objc open func pop() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    @objc func searchAction() {
        let vc = SearchBlockContactController { [weak self] in
            self?.viewProfile(profile: $0)
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc func viewProfile(profile: EaseProfileProtocol) {
        let vc = ComponentsRegister.shared.ContactInfoController.init(profile: profile)

        vc.modalPresentationStyle = .fullScreen
        ControllerStack.toDestination(vc: vc)
    }

    /// Fetch block user list.
    @objc open func fetchBlockList() {
        if let exist = self.blockListExist[EaseChatUIKitContext.shared?.currentUserId ?? ""],!exist {
            ChatClient.shared().contactManager?.getBlackListFromServer(completion: { [weak self] users, error in
                if error != nil {
                    consoleLogInfo("fetchBlockList error:\(error?.errorDescription ?? "")", type: .error)
                } else {
                    self?.mirrorIdsToProfiles(users: users)
                }
            })
        } else {
            self.mirrorIdsToProfiles(users: ChatClient.shared().contactManager?.getBlackList())
        }
    }
    
    @objc open func mirrorIdsToProfiles(users: [String]?) {
        var profiles = [EaseProfileProtocol]()
        if let users = users {
            for user in users {
                let profile = EaseProfile()
                profile.id = user
                profile.nickname = EaseChatUIKitContext.shared?.userCache?[user]?.nickname ?? ""
                profile.remark = EaseChatUIKitContext.shared?.userCache?[user]?.remark ?? ""
                profile.avatarURL = EaseChatUIKitContext.shared?.userCache?[user]?.avatarURL ?? ""
                profiles.append(profile)
            }
        }
        self.navigation.title = "block_list".chat.localize+"(\(profiles.count))"
        self.contactList.refreshList(infos: profiles)    }
}

extension BlockContactsViewController: ThemeSwitchProtocol {
    open func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.search.backgroundColor = style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor95
        
    }
    
}
