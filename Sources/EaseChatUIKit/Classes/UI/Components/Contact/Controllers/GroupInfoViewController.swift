//
//  GroupInfoViewController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/24.
//

import UIKit

@objc open class GroupInfoViewController: UIViewController {
    
    /**
     A private variable that represents the index path for editing.
     */
    private var editIndex = IndexPath(row: 1, section: 0)
    
    public var chatGroup = ChatGroup()
    
    public private(set) var service: GroupService = GroupServiceImplement()
    
    public private(set) var conversationService = ConversationServiceImplement()
    
    /**
     A private array of `ActionSheetItem` objects representing the owner options in the group info view controller.
     Each `ActionSheetItem` contains a title, type, and tag.

     Example usage:
     ```
     private var ownerOptions = [
         ActionSheetItem(title: "group_details_extend_button_disband".chat.localize, type: .destructive, tag: "disband_group"),
         ActionSheetItem(title: "group_details_extend_button_transfer".chat.localize, type: .destructive, tag: "transfer_owner")
     ]
     ```
     */
    public var ownerOptions = [ActionSheetItem(title: "group_details_extend_button_transfer".chat.localize, type: .destructive, tag: "transfer_owner"),ActionSheetItem(title: "group_details_extend_button_disband".chat.localize, type: .destructive, tag: "disband_group")]
    
    /**
     A private array that stores the member options for the group.

     Each member option is represented by an `ActionSheetItem` object, which contains the title, type, and tag of the option.

     Example usage:
     ```
     private var memberOptions = [ActionSheetItem(title: "group_details_extend_button_leave".chat.localize, type: .destructive, tag: "quit_group")]
     ```
     */
    public var memberOptions = [ActionSheetItem(title: "group_details_extend_button_leave".chat.localize, type: .destructive, tag: "quit_group")]
    
    public private(set) lazy var navigation: EaseChatNavigationBar = {
        self.createNavigation()
    }()
    
    /**
     Creates and returns a navigation bar for the GroupInfoViewController.

     - Returns: An instance of EaseChatNavigationBar.
     */
    @objc open func createNavigation() -> EaseChatNavigationBar {
        EaseChatNavigationBar(showLeftItem: true, textAlignment: .left, rightImages: self.chatGroup.isDisabled ? []:[UIImage(named: "more_detail", in: .chatBundle, with: nil)!] ,hiddenAvatar: true).backgroundColor(.clear)
    }
    
    @UserDefault("EaseChatUIKit_conversation_mute_map", defaultValue: Dictionary<String,Dictionary<String,Int>>()) private var muteMap
    
    private lazy var jsons: [[Dictionary<String,Any>]] = {
        [
            [["title":"group_details_button_members".chat.localize,"detail":"\(self.chatGroup.occupantsCount)","withSwitch": false,"switchValue":false],["title":"contact_details_switch_donotdisturb".chat.localize,"detail":"","withSwitch": true,"switchValue":self.muteMap[EaseChatUIKitContext.shared?.currentUserId ?? ""]?[self.chatGroup.groupId] ?? 0 == 1],
                ["title":"contact_details_button_clearchathistory".chat.localize,"detail":"","withSwitch": false,"switchValue":false]
         ],
         [
          ["title":"group_details_button_name".chat.localize,"detail":"\(String(describing: self.chatGroup.groupName ?? ""))","withSwitch": false,"switchValue":false],
          ["title":"group_details_button_description".chat.localize,"detail":self.chatGroup.description ?? "group_details_button_description".chat.localize,"withSwitch": false,"switchValue":false]
         ]
        ]
    }()
    
    public private(set) lazy var datas: [[DetailInfo]] = {
        self.fillDatas()
    }()
    
    /**
     Fills the data for the GroupInfoViewController.
     
     - Returns: An array of arrays of DetailInfo objects representing the filled data.
     */
    @objc open func fillDatas() -> [[DetailInfo]] {
        self.jsons.map {
            $0.map {
                let info = DetailInfo()
                info.setValuesForKeys($0)
                return info
            }
        }
    }
    
    public private(set) lazy var header: DetailInfoHeader = {
        self.createDetailHeader()
    }()
    
    /// Creates a detail header view for the group info.
    /// - Returns: A `DetailInfoHeader` instance.
    @objc open func createDetailHeader() -> DetailInfoHeader {
        DetailInfoHeader(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 284), showMenu: true, placeHolder: UIImage(named: "group", in: .chatBundle, with: nil)).backgroundColor(.clear)
    }
    
    public private(set) lazy var menuList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: NavigationHeight, width: self.view.frame.width, height: self.view.frame.height), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(54).tableHeaderView(self.header).backgroundColor(.clear)
    }()
    
    /// A closure that is executed when the group name is changed.
    @objc public var nameClosure: ((String,String) -> Void)?
    
    /// Initializes a new GroupInfoViewController with the specified group id.
    @objc required public init(group: String,nameChanged: @escaping (String,String) -> Void) {
        self.nameClosure = nameChanged
        self.chatGroup = ChatGroup(id: group)
        super.init(nibName: nil, bundle: nil)
        self.fetchGroupInfo(groupId: group)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /**
     Fetches the group information for a given group ID.
     
     - Parameters:
        - groupId: The ID of the group to fetch information for.
     */
    @objc open func fetchGroupInfo(groupId: String) {
        // Fetch group information from the service
        self.service.fetchGroupInfo(groupId: groupId) { [weak self] group, error in
            guard let `self` = self else { return }
            if error == nil, let group = group {
                self.chatGroup = group
            } else {
                self.chatGroup = ChatGroup(id: groupId)
            }
            let showName = self.chatGroup.groupName.isEmpty ? groupId:self.chatGroup.groupName
            self.header.nickName.text = showName
            self.header.userState = .offline
            self.header.detailText = groupId
            self.menuList.reloadData()
            let profile = EaseProfile()
            profile.id = self.chatGroup.groupId
            profile.nickname = self.chatGroup.groupName
            if !self.chatGroup.groupName.isEmpty {
                profile.avatarURL = self.chatGroup.settings.ext
            }
            EaseChatUIKitContext.shared?.updateCache(type: .group, profile: profile)
        }
        
        
    }
    
    /**
     Fills the alias (nickname) for the group details button.
     
     - Parameters:
        - nickname: The nickname to be filled as the alias.
     */
    @objc open func fillAlias(nickname: String) {
        for sections in self.datas {
            for row in sections {
                if row.title == "group_details_button_alias".chat.localize {
                    row.detail = nickname
                    self.menuList.reloadData()
                    return
                }
            }
        }
    }
    
    /**
     Updates the user state in the group info view controller.
     
     - Parameters:
        - state: The new user state.
     */
    @MainActor @objc public func updateUserState(state: UserState) {
        self.header.userState = state
    }
    

    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.datas.first?.first?.detail = "\(self.chatGroup.occupantsCount)"
        self.menuList.reloadData()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.theme.neutralColor98
        self.view.addSubViews([self.navigation,self.menuList])
        // Do any additional setup after loading the view.
        //click of the navigation
        if self.chatGroup.owner != EaseChatUIKitContext.shared?.currentUserId ?? "" {
            self.datas = self.datas.dropLast()
        }
        self.navigation.clickClosure = { [weak self] in
            self?.navigationClick(type: $0, indexPath: $1)
        }
        self.headerActions()
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        
    }
    
    /**
     This method is responsible for handling the header actions in the GroupInfoViewController.
     It checks if there is a chat action item available in the contact's detail extension action items.
     If found, it sets the action closure to invoke the `alreadyChat()` method when the action is triggered.

     - Note: The `alreadyChat()` method is called with a weak reference to `self` to avoid potential retain cycles.
     */
    @objc open func headerActions() {
        if let chat = Appearance.contact.detailExtensionActionItems.first(where: { $0.featureIdentify == "Chat" }) {
            chat.actionClosure = { [weak self] in
                self?.processHeaderActionEvents(item: $0)
            }
        }
        if let search = Appearance.contact.detailExtensionActionItems.first(where: { $0.featureIdentify == "SearchMessages" }) {
            search.actionClosure = { [weak self] in
                self?.processHeaderActionEvents(item: $0)
            }
        }
    }
    
    @objc open func processHeaderActionEvents(item: ContactListHeaderItemProtocol) {
        switch item.featureIdentify {
        case "Chat": self.alreadyChat()
//        case "AudioCall":
//        case "VideoCall":
        case "SearchMessages": self.searchHistoryMessages()
        default: break
        }
    }
    
    @objc open func searchHistoryMessages() {
        let vc = SearchHistoryMessagesViewController(conversationId: self.chatGroup.groupId) { message in
            
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    /**
     Handles the navigation click events in the GroupInfoViewController.
     
     - Parameters:
        - type: The type of navigation click event.
        - indexPath: The optional index path associated with the event.
     */
    @objc open func navigationClick(type: EaseChatNavigationBarClickEvent, indexPath: IndexPath?) {
        switch type {
        case .back: self.pop()
        case .rightItems: self.rightActions(indexPath: indexPath ?? IndexPath())
        default:
            break
        }
    }
    
    /**
     Opens the chat conversation for the current group.
     
     This method is called when the user wants to open the chat conversation for the current group. It performs the following steps:
     1. Acknowledges the conversation read by calling `ackConversationRead` method of the shared `ChatClient` instance.
     2. Checks if the previous view controller in the navigation stack is `MessageListController`.
         - If it is, pops to the view controller before that and then pushes a new instance of `ComponentsRegister.shared.MessageViewController` with the conversation ID and chat type set to `.group`.
         - If it is not, directly pushes a new instance of `ComponentsRegister.shared.MessageViewController` with the conversation ID and chat type set to `.group`.
     3. If the navigation stack is empty, checks if the presenting view controller is `MessageListController`.
         - If it is, dismisses the presenting view controller and then presents a new instance of `ComponentsRegister.shared.MessageViewController` with the conversation ID and chat type set to `.group`.
         - If it is not, presents a new instance of `ComponentsRegister.shared.MessageViewController` with the conversation ID and chat type set to `.group` using the full screen modal presentation style.
     4. If there is no presenting view controller, creates a new instance of `ComponentsRegister.shared.MessageViewController` with the conversation ID and chat type set to `.group` and navigates to it using `ControllerStack.toDestination` method.
     */
    @objc open func alreadyChat() {
        ChatClient.shared().chatManager?.ackConversationRead(self.chatGroup.groupId)
        if let count = self.navigationController?.viewControllers.count {
            if self.navigationController?.viewControllers[safe: count - 2] is MessageListController {
                if let root = self.navigationController?.viewControllers[safe: count - 3] {
                    self.navigationController?.popToViewController(root, animated: true)
                    let vc = ComponentsRegister.shared.MessageViewController.init(conversationId: self.chatGroup.groupId,chatType: .group)
                    vc.modalPresentationStyle = .fullScreen
                    ControllerStack.toDestination(vc: vc)
                }
            } else {
                let vc = ComponentsRegister.shared.MessageViewController.init(conversationId: self.chatGroup.groupId,chatType: .group)
                vc.modalPresentationStyle = .fullScreen
                ControllerStack.toDestination(vc: vc)
            }
        } else {
            if let presentingVC = self.presentingViewController {
                if presentingVC is MessageListController {
                    self.dismiss(animated: false) {
                        presentingVC.dismiss(animated: false) {
                            let vc = ComponentsRegister.shared.MessageViewController.init(conversationId: self.chatGroup.groupId,chatType: .group)
                            vc.modalPresentationStyle = .fullScreen
                            UIViewController.currentController?.present(vc, animated: true)
                        }
                    }
                } else {
                    let vc = ComponentsRegister.shared.MessageViewController.init(conversationId: self.chatGroup.groupId,chatType: .group)
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true)
                }
            } else {
                let desiredViewController = ComponentsRegister.shared.MessageViewController.init(conversationId: self.chatGroup.groupId,chatType: .group)
                desiredViewController.modalPresentationStyle = .fullScreen
                ControllerStack.toDestination(vc: desiredViewController)
            }
            
        }
    }
    
    /**
     Pops the current view controller from the navigation stack or dismisses it if there is no navigation controller.

     - Note: If the view controller is embedded in a navigation controller, it will be popped from the navigation stack with animation. If there is no navigation controller, the view controller will be dismissed with animation.
     */
    @objc open func pop() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    /**
     Handles the right actions for a given indexPath in the GroupInfoViewController.
     
     - Parameters:
         - indexPath: The index path of the selected row.
     */
    @objc open func rightActions(indexPath: IndexPath) {
        switch indexPath.row {
        case 0:
            DialogManager.shared.showActions(actions: self.chatGroup.permissionType == .owner ? self.ownerOptions:self.memberOptions) { [weak self] item in
                guard let `self` = self else { return }
                switch item.tag {
                case "disband_group": self.disband()
                case "transfer_owner": self.transfer()
                case "quit_group": self.leave()
                default:
                    break
                }
            }
        default:
            break
        }
    }
    
    /**
     Disbands the group.
     This method shows an alert to confirm the disbanding of the group. If the user confirms, it calls the `disband` method of the `service` object to disband the group. After successful disbanding, it posts a notification with the group ID and pops the current view controller from the navigation stack. If there is an error during the disbanding process, it logs the error message.
     */
    @objc open func disband() {
        DialogManager.shared.showAlert(title: "group_details_extend_button_disband_alert_title".chat.localize, content: "group_details_extend_button_disband_alert_subtitle".chat.localize, showCancel: true, showConfirm: true) { [weak self] _ in
            self?.service.disband(groupId: self?.chatGroup.groupId ?? "") { error in
                if error == nil {
                    NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_leaveGroup"), object: self?.chatGroup.groupId ?? "")
                    self?.pop()
                } else {
                    consoleLogInfo("disband error:\(error?.errorDescription ?? "")", type: .error)
                }
            }
        }
        
    }
    
    /**
     Transfers the ownership of the group to another participant.
     */
    @objc open func transfer() {
        let vc =
        ComponentsRegister.shared.GroupParticipantController.init(groupId: self.chatGroup.groupId, operation: .transferOwner)
        vc.mentionClosure = { [weak self] in
            self?.transferConfirm(profile: $0)
        }
        if vc.presentingViewController != nil {
            vc.modalPresentationStyle = .fullScreen
        }
        ControllerStack.toDestination(vc: vc)
    }
    
    private func transferConfirm(profile: EaseProfileProtocol) {
        DialogManager.shared.showAlert(title: "group_details_extend_button_transfer".chat.localize+"to ".chat.localize+"\(profile.nickname)?", content: "", showCancel: true, showConfirm: true) { [weak self] text in
            guard let `self` = self else { return }
            self.service.transfer(groupId: self.chatGroup.groupId, userId: profile.id, completion: { group, error in
                if error == nil {
                    NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_leaveGroup"), object: profile.id)
                    self.pop()
                } else {
                    consoleLogInfo("transfer owner error:\(error?.errorDescription ?? "")", type: .error)
                }
            })
        }
    }
    
    /**
     Method to leave the group.
     
     This method displays an alert to confirm leaving the group. If the user confirms, it calls the `leave` method of the `service` object to leave the group. If leaving the group is successful, it pops the current view controller. Otherwise, it logs an error message.
     */
    @objc open func leave() {
        DialogManager.shared.showAlert(title: "group_details_extend_button_leave_alert_title".chat.localize, content: "group_details_extend_button_leave_alert_subtilte".chat.localize, showCancel: true, showConfirm: true) { [weak self] _ in
            self?.service.leave(groupId: self?.chatGroup.groupId ?? "") { error in
                if error == nil {
                    NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_leaveGroup"), object: self?.chatGroup.groupId ?? "")
                    self?.pop()
                } else {
                    consoleLogInfo("disband error:\(error?.errorDescription ?? "")", type: .error)
                }
            }
        }
        
    }

}


extension GroupInfoViewController: UITableViewDelegate,UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        self.datas.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.datas[safe: section]?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if self.datas.count > 1 {
            return (section <= 0 ? 30:0)
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if self.datas.count > 1 {
            return section <= 0 ? UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 30)).backgroundColor(Theme.style == .dark ? UIColor.theme.neutralColor2:UIColor.theme.neutralColor95):nil
        } else {
            return nil
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.cellForRowAt(indexPath: indexPath)
    }
    
    /**
     Returns a table view cell for the specified index path.

     - Parameters:
        - indexPath: The index path of the cell.

     - Returns: A table view cell for the specified index path.
     */
    @objc open func cellForRowAt(indexPath: IndexPath) -> UITableViewCell {
        var cell = self.menuList.dequeueReusableCell(withIdentifier: "DetailInfoListCell") as? DetailInfoListCell
        if cell == nil {
            cell = DetailInfoListCell(style: .default, reuseIdentifier: "DetailInfoListCell")
        }
        cell?.indexPath = indexPath
        if let info = self.datas[safe: indexPath.section]?[safe: indexPath.row] {
            if EaseChatUIKitContext.shared?.currentUserId ?? "" == self.chatGroup.owner {
                cell?.accessoryType = info.withSwitch ? .none:.disclosureIndicator
            } else {
                if indexPath.section == 1 {
                    cell?.accessoryType = .none
                } else {
                    cell?.accessoryType = info.withSwitch ? .none:.disclosureIndicator
                }
            }
            cell?.refresh(info: info)
        }
        cell?.switchMenu.isEnabled = !self.chatGroup.isDisabled
        cell?.valueChanged = { [weak self] in
            self?.switchChanged(isOn: $0, indexPath: $1)
        }
        return cell ?? UITableViewCell()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if EaseChatUIKitContext.shared?.currentUserId ?? "" == self.chatGroup.owner {
            self.didSelectRowAt(indexPath: indexPath)
        } else {
            if indexPath.section == 0 {
                self.didSelectRowAt(indexPath: indexPath)
            }
        }
        
    }
    
    /**
     Handles the selection of a table view cell at a specific index path.
     
     - Parameters:
         - indexPath: The index path of the selected cell.
     */
    @objc open func didSelectRowAt(indexPath: IndexPath) {
        if let info = self.datas[safe: indexPath.section]?[safe: indexPath.row] {
            self.editIndex = indexPath
            switch info.title {
            case "group_details_button_name".chat.localize: self.edit(type: .name, detail: info.detail)
            case "group_details_button_alias".chat.localize: self.edit(type: .alias, detail: info.detail)
            case "group_details_button_members".chat.localize: self.viewParticipants()
            case "group_details_button_description".chat.localize: self.edit(type: .description, detail: info.detail)
            case "contact_details_button_clearchathistory".chat.localize: self.cleanHistoryMessages()
            default:
                break
            }
        }
    }
    
    /// Opens the view to display the participants of the chat group.
    @objc open func viewParticipants() {
        let vc = ComponentsRegister.shared.GroupParticipantController.init(groupId: self.chatGroup.groupId)
        vc.modalPresentationStyle = .fullScreen
        ControllerStack.toDestination(vc: vc)
    }
    
    /**
     Cleans the history messages of the group.
     */
    @objc open func cleanHistoryMessages() {
        DialogManager.shared.showAlert(title: "group_details_button_clearchathistory".chat.localize, content: "", showCancel: true, showConfirm: true) { [weak self] _ in
            guard let `self` = self else { return }
            ChatClient.shared().chatManager?.getConversationWithConvId(self.chatGroup.groupId)?.deleteAllMessages(nil)
            NotificationCenter.default.post(name: Notification.Name("EaseChatUIKit_clean_history_messages"), object: self.chatGroup.groupId)
        }
        
    }
    
    /**
     Opens the edit view for the group information.
     
     - Parameters:
        - type: The type of information to edit.
        - detail: The current detail of the information being edited.
     */
    @objc open func edit(type: GroupInfoEditType, detail: String) {
        // Check if the group is disabled
        if self.chatGroup.isDisabled {
            DialogManager.shared.showAlert(title: "Group was disabled".chat.localize, content: "", showCancel: false, showConfirm: true) { _ in
                
            }
            return
        }
        
        // Create an instance of GroupInfoEditViewController
        let vc = GroupInfoEditViewController(groupId: self.chatGroup.groupId, type: type, rawText: detail) { [weak self] result in
            self?.handleEditCallback(text: result, type: type)
        }
        
        // Push the edit view controller to the navigation stack
        vc.modalPresentationStyle = .fullScreen
        ControllerStack.toDestination(vc: vc)
    }
    
    /**
     Handles the callback for editing group information.
     
     - Parameters:
        - text: The edited text.
        - type: The type of information being edited.
     */
    @objc open func handleEditCallback(text: String, type: GroupInfoEditType) {
        if type == .name {
            self.nameClosure?(self.chatGroup.groupId, text)
            if let profile = EaseChatUIKitContext.shared?.groupCache?[self.chatGroup.groupId] {
                profile.nickname = text
                EaseChatUIKitContext.shared?.updateCache(type: .group, profile: profile)
            } else {
                let profile = EaseProfile()
                profile.id = self.chatGroup.groupId
                profile.nickname = text
                profile.avatarURL = self.chatGroup.settings.ext
                EaseChatUIKitContext.shared?.updateCache(type: .group, profile: profile)
            }
            EaseChatUIKitContext.shared?.onGroupNameUpdated?(self.chatGroup.groupId, text)
            self.header.nickName.text = text
        }
        self.datas[safe: self.editIndex.section]?[safe: self.editIndex.row]?.detail = text
        self.menuList.reloadRows(at: [self.editIndex], with: .fade)
    }
    
    /**
        This method is called when the switch is changed in the GroupInfoViewController.
        
        - Parameters:
            - isOn: A boolean value indicating whether the switch is turned on or off.
            - indexPath: The index path of the cell containing the switch.
    */
    @objc open func switchChanged(isOn: Bool, indexPath: IndexPath) {
        if let name = self.datas[safe: indexPath.section]?[safe: indexPath.row]?.title {
            if isOn {
                self.conversationService.setSilentMode(conversationId: self.chatGroup.groupId) { [weak self] result, error in
                    guard let `self` = self else { return }
                    if error == nil {
                        self.processSilentMode(name: name, isOn: isOn)
                    } else {
                        consoleLogInfo("ContactInfoViewController set silent mode error:\(error?.errorDescription ?? "")", type: .error)
                    
                    }
                }
            } else {
                self.conversationService.clearSilentMode(conversationId: self.chatGroup.groupId) { [weak self] result, error in
                    guard let `self` = self else { return }
                    if error == nil {
                        self.processSilentMode(name: name, isOn: isOn)
                    } else {
                        consoleLogInfo("ContactInfoViewController clear silent mode error:\(error?.errorDescription ?? "")", type: .error)
                    }
                }
            }
        }
    }
    
    @objc open func processSilentMode(name: String,isOn: Bool) {
        if var userMap = self.muteMap[EaseChatUIKitContext.shared?.currentUserId ?? ""] {
            userMap[self.chatGroup.groupId] = isOn ? 1:0
            self.muteMap[EaseChatUIKitContext.shared?.currentUserId ?? ""] = userMap
        } else {
            self.muteMap[EaseChatUIKitContext.shared?.currentUserId ?? ""] = [self.chatGroup.groupId:isOn ? 1:0]
        }
        if name == "contact_details_switch_donotdisturb".chat.localize,let groupId = self.chatGroup.groupId {
            NotificationCenter.default.post(name: Notification.Name(rawValue: "EaseUIKit_do_not_disturb_changed"), object: nil,userInfo: ["id":groupId,"value":isOn])
        }
    }
    
    
}

extension GroupInfoViewController: ThemeSwitchProtocol {
    open func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
    }
}
