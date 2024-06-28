//
//  GroupParticipantsController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/27.
//

import UIKit

/**
 An enumeration representing the possible operations for group participants.
 
 - normal: Represents a normal operation.
 - mention: Represents an operation related to mentioning participants.
 - transferOwner: Represents an operation related to transferring ownership of the group.
 */
@objc public enum GroupParticipantsOperation: UInt {
    case normal
    case mention
    case transferOwner
}

/// A view controller that displays the participants of a group.
@objcMembers open class GroupParticipantsController: UIViewController {
    
    private var pageSize = UInt(200)
    
    private var recursiveCount = 5
    
    private let service: GroupService = GroupServiceImplement()
    
    private var cursor = ""
    
    private var loadFinished = false
    
    /**
     The array of participants in the group.
     */
    public private(set) var participants: [EaseProfileProtocol] = []
    
    public private(set) var chatGroup = ChatGroup()
    
    public var mentionClosure: ((EaseProfileProtocol) -> Void)?
    
    public private(set) var operation = GroupParticipantsOperation.normal
    
    public private(set) lazy var navigation: EaseChatNavigationBar = {
        self.createNavigation()
    }()
    
    /// Creates and returns a navigation bar for the GroupParticipantsController.
    /// - Returns: An instance of EaseChatNavigationBar.
    @objc open func createNavigation() -> EaseChatNavigationBar {
        EaseChatNavigationBar(frame: self.operation == .mention ? CGRect(x: 0, y: 0, width: ScreenWidth, height: 44):CGRect(x: 0, y: 0, width: ScreenWidth, height: NavigationHeight),showLeftItem: true, textAlignment: .left, rightImages:  self.rightImages ,hiddenAvatar: true).backgroundColor(.clear)
    }
    
    private var rightImages: [UIImage] {
        ((self.chatGroup.owner == EaseChatUIKitContext.shared?.currentUserId ?? "" && !self.chatGroup
            .isDisabled)&&self.operation == .normal) ? [UIImage(named: "person_add", in: .chatBundle, with: nil)!,UIImage(named: "members_remove", in: .chatBundle, with: nil)!]:[]
    }
    
    public private(set) lazy var participantsList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: self.navigation.frame.height, width: self.view.frame.width, height: self.view.frame.height-self.navigation.frame.height), style: .plain).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(60).backgroundColor(.clear).separatorStyle(.none)
    }()
    
    /**
     Initializes a `GroupParticipantsController` with the specified group ID and operation.
     
     - Parameters:
        - groupId: The ID of the group.
        - operation: The operation to be performed on the group participants. Default value is `.normal`.
     
     - Returns: An initialized `GroupParticipantsController` instance.
     */
    @objc required public init(groupId: String, operation: GroupParticipantsOperation = .normal) {
        self.chatGroup = ChatGroup(id: groupId)
        self.operation = operation
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    


    open override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.theme.neutralColor98
        self.setupTitle()
        self.view.addSubViews([self.navigation,self.participantsList])
        // Do any additional setup after loading the view.
        //click of the navigation
        self.navigation.clickClosure = { [weak self] in
            self?.navigationClick(type: $0, indexPath: $1)
        }
        self.fetchParticipants()
        
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshList), name: Notification.Name(rawValue: "EaseChatUIKitContextUpdateCache"), object: nil)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.refreshList()
    }
    
    @objc private func refreshList() {
        for participant in participants {
            if let user = EaseChatUIKitContext.shared?.userCache?[participant.id]{
                participant.nickname = user.nickname
                participant.remark = user.remark
                participant.avatarURL = user.avatarURL
            }
        }
        self.participantsList.reloadData()
    }
    
    private func setupTitle() {
        var text = ""
        switch self.operation {
        case .normal:
            text = "group_details_button_members".chat.localize
        case .mention:
            text = "group_mention_title".chat.localize
        case .transferOwner:
            text = "group_details_extend_button_transfer".chat.localize
        }
        if self.participants.count > 0 {
            text += "(\(self.participants.count))"
        }
        self.navigation.title = text
    }
    
    
    /**
     Handles the navigation bar click events.
     
     - Parameters:
        - type: The type of navigation bar click event.
        - indexPath: The index path associated with the event (optional).
     */
    @objc open func navigationClick(type: EaseChatNavigationBarClickEvent, indexPath: IndexPath?) {
        switch type {
        case .back: self.pop()
        case .rightItems: self.rightActions(indexPath: indexPath ?? IndexPath())
        default:
            break
        }
    }
    
    @objc open func pop() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    private func rightActions(indexPath: IndexPath) {
        switch indexPath.row {
        case 0: self.toAdd()
        case 1: self.toRemove()
        default:
            break
        }
    }
    
    @objc open func ignoreContacts() -> [String] {
        let contacts = ChatClient.shared().contactManager?.getContacts() ?? []
        var ignoreIds = [String]()
        for participant in self.participants {
            for id in contacts {
                if id == participant.id {
                    ignoreIds.append(id)
                }
            }
        }
        return ignoreIds
    }
    
    @objc open func toAdd() {
        let vc = ComponentsRegister.shared.ContactsController.init(headerStyle: .addGroupParticipant,ignoreIds: self.ignoreContacts())
        vc.confirmClosure = { [weak self] users in
            guard let `self` = self else { return }
            self.service
                .invite(userIds: users.map({ $0.id }), to: self.chatGroup.groupId, message: "", completion: { [weak self] group, error in
                    if error == nil {
                        self?.participants.append(contentsOf: users)
                        self?.participantsList.reloadData()
                        self?.pop()
                    } else {
                        consoleLogInfo("Add participants  error:\(error?.errorDescription ?? "")", type: .error)
                    }
                })
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc open func toRemove() {
        let vc = ComponentsRegister.shared.RemoveGroupParticipantController.init(group: self.chatGroup, profiles: self.participants.filter({ $0.id != self.chatGroup.owner })) { [weak self] userIds in
            for userId in userIds {
                self?.participants.removeAll(where: { $0.id == userId })
            }
            self?.participantsList.reloadData()
        }
        vc.modalPresentationStyle = .fullScreen
        ControllerStack.toDestination(vc: vc)
    }

    @objc open func fetchParticipants() {
        if self.recursiveCount > 0 {
            self.service.fetchParticipants(groupId: self.chatGroup.groupId, cursor: self.cursor, pageSize: self.pageSize) { [weak self] result, error in
                guard let `self` = self else { return }
                if error == nil {
                    if let list = result?.list {
                        if self.cursor.isEmpty {
                            self.participants.removeAll()
                            self.participants = list.map({
                                let profile = EaseProfile()
                                let id = $0 as String
                                profile.id = id
                                if let user = EaseChatUIKitContext.shared?.userCache?[id] {
                                    profile.nickname = user.nickname
                                    profile.avatarURL = user.avatarURL
                                }
                                if let user = EaseChatUIKitContext.shared?.chatCache?[id] {
                                    profile.nickname = user.nickname
                                    profile.avatarURL = user.avatarURL
                                }
                                
                                return profile
                            })
                            if list.count <= self.pageSize {
                                if self.operation != .transferOwner {
                                    let profile = EaseProfile()
                                    profile.id = self.chatGroup.owner
                                    if let user = EaseChatUIKitContext.shared?.userCache?[self.chatGroup.owner] {
                                        profile.nickname = user.nickname
                                        profile.avatarURL = user.avatarURL
                                    }
                                    if let user = EaseChatUIKitContext.shared?.chatCache?[self.chatGroup.owner] {
                                        profile.nickname = user.nickname
                                        profile.avatarURL = user.avatarURL
                                    }
                                    self.participants.insert(profile, at: 0)
                                }
                            }
                        } else {
                            self.participants.append(contentsOf: list.map({
                                let profile = EaseProfile()
                                profile.id = $0 as String
                                if let user = EaseChatUIKitContext.shared?.userCache?[profile.id] {
                                    profile.nickname = user.nickname
                                    profile.avatarURL = user.avatarURL
                                }
                                if let user = EaseChatUIKitContext.shared?.chatCache?[profile.id] {
                                    profile.nickname = user.nickname
                                    profile.avatarURL = user.avatarURL
                                }
                                return profile
                            }))
                        }
                    }
                    self.cursor = result?.cursor ?? ""
                    self.participantsList.reloadData()
                    self.recursiveCount -= 1
                    if self.participants.count < Appearance.chat.groupParticipantsLimitCount {
                        self.fetchParticipants()
                    }
                } else {
                    consoleLogInfo("GroupParticipantsController fetch error:\(error?.errorDescription ?? "")", type: .error)
                }
                
                self.setupTitle()
            }
        } else {
            if self.operation == .mention {
                let profile = EaseProfile()
                profile.id = "All"
                profile.nickname = "All"
                profile.avatarURL = "all"
                self.participants.insert(profile, at: 0)
            }
            self.participantsList.reloadData()
        }
    }
}


extension GroupParticipantsController: UITableViewDelegate,UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.participants.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        self.cellForRowAt(indexPath: indexPath)
    }
    
    @objc open func cellForRowAt(indexPath: IndexPath) -> UITableViewCell {
        var cell = self.participantsList.dequeueReusableCell(withIdentifier: "GroupParticipantCell") as? GroupParticipantCell
        if cell == nil {
            cell = GroupParticipantCell(displayStyle: .normal, identifier: "GroupParticipantCell")
        }
        if let profile = self.participants[safe: indexPath.row] {
            cell?.refresh(profile: profile, keyword: "")
        }
        cell?.selectionStyle = .none
        return cell ?? GroupParticipantCell()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var unknownInfoIds = [String]()
        if let visiblePaths = self.participantsList.indexPathsForVisibleRows {
            for indexPath in visiblePaths {
                if let nickName = self.participants[safe: indexPath.row]?.nickname,nickName.isEmpty {
                    unknownInfoIds.append(self.participants[safe: indexPath.row]?.id ?? "")
                }
            }
        }
        
    }
    
    private func processCacheInfos(values: [String]) {
        for participant in self.participants {
            for value in values {
                if value == participant.id {
                    participant.nickname = value
                }
            }
        }
        self.participantsList.reloadData()
    }
    
    private func processCacheProfiles(values: [EaseProfileProtocol]) {
        for participant in self.participants {
            for value in values {
                if value.id == participant.id {
                    participant.nickname = value.nickname
                    participant.avatarURL = value.avatarURL
                }
            }
        }
        self.participantsList.reloadData()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let profile = self.participants[safe: indexPath.row] {
            switch self.operation {
            case .normal:
                let vc = ComponentsRegister.shared.ContactInfoController.init(profile: profile)
                vc.modalPresentationStyle = .fullScreen
                ControllerStack.toDestination(vc: vc)
            case .mention,.transferOwner:
                self.mentionClosure?(profile)
                self.pop()
            }
            
        }
    }
}

extension GroupParticipantsController: ThemeSwitchProtocol {
    open func switchTheme(style: ThemeStyle) {
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
    }
}
