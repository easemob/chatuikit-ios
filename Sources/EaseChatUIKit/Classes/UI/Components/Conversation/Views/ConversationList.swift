import UIKit

@objc final public class ConversationList: UITableView {
        
    private var eventHandlers: NSHashTable<ConversationListActionEventsDelegate> = NSHashTable<ConversationListActionEventsDelegate>.weakObjects()
    
    /// Add UI actions handler.
    /// - Parameter actionHandler: ``ConversationListActionEventsDelegate``
    public func addActionHandler(actionHandler: ConversationListActionEventsDelegate) {
        if self.eventHandlers.contains(actionHandler) {
            return
        }
        self.eventHandlers.add(actionHandler)
    }
    
    /// Remove UI action handler.
    /// - Parameter actionHandler: ``ConversationListActionEventsDelegate``
    public func removeActionHandler(actionHandler: ConversationListActionEventsDelegate) {
        self.eventHandlers.remove(actionHandler)
    }
    
    public private(set) var datas: [ConversationInfo] = []
    
    private var indexMap: [String:Int] = [:]
        
    private lazy var empty: EmptyStateView = {
        EmptyStateView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height),emptyImage: UIImage(named: "empty",in: .chatBundle, with: nil), onRetry: { [weak self] in
            guard let `self` = self else { return }
            for listener in self.eventHandlers.allObjects {
                listener.onConversationListOccurErrorWhenFetchServer()
            }
        }).backgroundColor(.clear)
    }()
    
    @objc required public override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.delegate(self).dataSource(self).tableFooterView(UIView()).separatorStyle(.none).registerCell(ComponentsRegister.shared.ConversationCell.self , forCellReuseIdentifier: "EaseChatUIKit.ConversationCell").rowHeight(Appearance.conversation.rowHeight).backgroundColor(.clear)
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        
    }
    
    @objc private func refreshData() {
        self.refreshControl?.attributedTitle = NSAttributedString {
            AttributedText("Refreshing...").font(Font.theme.bodyLarge).foregroundColor(Theme.style == .dark ? Color.theme.neutralColor5:Color.theme.neutralColor6)
        }
        self.refreshControl?.tintColor = Theme.style == .dark ? Color.theme.neutralColor4:Color.theme.neutralColor6
        for handler in self.eventHandlers.allObjects {
            handler.onConversationListRefresh()
        }
    }
    
    @objc private func longPressedAction(gesture: UILongPressGestureRecognizer) {
         
        if gesture.state == .began {
            let touchPoint = gesture.location(in: self)
            if let indexPath = self.indexPathForRow(at: touchPoint) {
                for handler in self.eventHandlers.allObjects {
                    if let info = self.datas[safe: indexPath.row] {
                        handler.onConversationLongPressed(indexPath: indexPath, info: info)
                    }
                }
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

//MARK: - UITableViewDelegate&UITableViewDataSource about
extension ConversationList: UITableViewDelegate,UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.datas.count <= 0 {
            self.backgroundView = self.empty
        } else {
            self.backgroundView = nil
        }
        return self.datas.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(with: ComponentsRegister.shared.ConversationCell, reuseIdentifier: "EaseChatUIKit.ConversationCell")
        if cell == nil {
            cell = ComponentsRegister.shared.ConversationCell.init(style: .default, reuseIdentifier: "EaseChatUIKit.ConversationCell")
        }
        if let info = self.datas[safe: indexPath.row] {
            cell?.refresh(info: info)
        }
        return cell ?? UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let info = self.datas[safe: indexPath.row] else { return }
        if let hooker = ComponentViewsActionHooker.shared.conversation.longPressed {
            hooker(indexPath,info)
        } else {
            for listener in self.eventHandlers.allObjects {
                info.unreadCount = 0
                info.mentioned = false
                listener.onConversationDidSelected(indexPath: indexPath, info: info)
            }
            self.refreshData()
        }
    }
    
    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let info = self.datas[safe: indexPath.row] else { return nil }
        if info.doNotDisturb {
            if let index = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .unmute }) {
                Appearance.conversation.swipeLeftActions[index] = .unmute
            }
        } else {
            if let index = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .unmute }) {
                Appearance.conversation.swipeLeftActions[index] = .mute
            }
        }
        return UISwipeActionsConfiguration(actions: self.actions(leading: false,info: info,indexPath: indexPath))
    }

    public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let info = self.datas[safe: indexPath.row] else { return nil }
        return UISwipeActionsConfiguration(actions: self.actions(leading: true,info: info,indexPath: indexPath))
    }
    
    private func actions(leading: Bool,info: ConversationInfo,indexPath: IndexPath) -> [UIContextualActionChatUIKit] {
        var rightActions = [UIContextualActionType]()
        for action in Appearance.conversation.swipeRightActions {
            if action == .read {
                if info.unreadCount > 0 {
                    rightActions.append(action)
                }
            } else {
                rightActions.append(action)
            }
        }
        if info.pinned,let index = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .pin }) {
            Appearance.conversation.swipeLeftActions[index] = .unpin
        }
        if !info.pinned,let index = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .unpin }) {
            Appearance.conversation.swipeLeftActions[index] = .pin
        }
        if info.doNotDisturb,let index = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .mute }) {
            Appearance.conversation.swipeLeftActions[index] = .unmute
        }
        if !info.doNotDisturb,let index = Appearance.conversation.swipeLeftActions.firstIndex(where: { $0 == .unmute }) {
            Appearance.conversation.swipeLeftActions[index] = .mute
        }
        return (leading ? rightActions:Appearance.conversation.swipeLeftActions).map {
            switch $0 {
            case .more:
                return UIContextualActionChatUIKit(title: "conversation_right_slide_menu_more".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    for listener in self.eventHandlers.allObjects {
                        listener.onConversationSwipe(type: .more, info: info)
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.neutralColor6:UIColor.theme.neutralColor5).icon(image: UIImage(named: "more", in: .chatBundle, with: nil))
            case .read:
                return UIContextualActionChatUIKit(title: "conversation_right_slide_menu_read".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    for listener in self.eventHandlers.allObjects {
                        listener.onConversationSwipe(type: .read, info: info)
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5).icon(image: UIImage(named: "read", in: .chatBundle, with: nil))
            case .delete:
                return UIContextualActionChatUIKit(title: "conversation_right_slide_menu_delete".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    for listener in self.eventHandlers.allObjects {
                        listener.onConversationSwipe(type: .delete, info: info)
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.errorColor6:UIColor.theme.errorColor5).icon(image: UIImage(named: "trash", in: .chatBundle, with: nil))
            case .mute:
                return UIContextualActionChatUIKit(title: "conversation_right_slide_menu_mute".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    for listener in self.eventHandlers.allObjects {
                        listener.onConversationSwipe(type: .mute, info: info)
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5).icon(image: UIImage(named: "mute", in: .chatBundle, with: nil))
            case .pin:
                return UIContextualActionChatUIKit(title: "conversation_left_slide_menu_pin".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    for listener in self.eventHandlers.allObjects {
                        listener.onConversationSwipe(type: .pin, info: info)
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).icon(image: UIImage(named: "pin", in: .chatBundle, with: nil))
            case .unpin:
                return UIContextualActionChatUIKit(title: "conversation_left_slide_menu_unpin".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    if let hooker = ComponentViewsActionHooker.shared.conversation.swipeAction {
                        hooker(.unpin, info)
                    } else {
                        for listener in self.eventHandlers.allObjects {
                            listener.onConversationSwipe(type: .unpin, info: info)
                        }
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.primaryColor6:UIColor.theme.primaryColor5).icon(image: UIImage(named: "unpin", in: .chatBundle, with: nil))
            case .unmute:
                return UIContextualActionChatUIKit(title: "conversation_left_slide_menu_unmute".chat.localize, style: .normal, actionType: $0) { (action, view, completion) in
                    for listener in self.eventHandlers.allObjects {
                        listener.onConversationSwipe(type: .unmute, info: info)
                    }
                    completion(true)
                }.backgroundColor(color: Theme.style == .dark ? UIColor.theme.neutralSpecialColor6:UIColor.theme.neutralSpecialColor5).icon(image: UIImage(named: "unmute", in: .chatBundle, with: nil))
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var unknownInfoIds = [String]()
        if let visiblePaths = self.indexPathsForVisibleRows {
            for indexPath in visiblePaths {
                if let nickName = self.datas[safe: indexPath.row]?.nickname,nickName.isEmpty {
                    unknownInfoIds.append(self.datas[safe: indexPath.row]?.id ?? "")
                }
            }
        }
        if !unknownInfoIds.isEmpty {
            for eventHandler in self.eventHandlers.allObjects {
                eventHandler.onConversationListEndScrollNeededDisplayInfos(ids: unknownInfoIds)
            }
        }
    }
        
    
}

//MARK: - IConversationListDriver Implement
extension ConversationList: IConversationListDriver {
    public func occurError() {
        self.empty.state = .error
        self.reloadData()
    }
    
    public func refreshList(infos: [ConversationInfo]) {
//        self.refreshControl?.endRefreshing()
        self.empty.state = .empty
        self.datas.removeAll()
        self.datas.append(contentsOf: infos)
        self.updateIndexMap()
        self.reloadData()
    }
    
    public func refreshProfiles(infos: [EaseProfileProtocol]) {
        
        for info in infos {
            if let index = self.indexMap[info.id], let item = self.datas[safe: index] {
                if !info.nickname.isEmpty {
                    item.nickname = info.nickname
                }
                if !info.remark.isEmpty {
                    item.remark = info.remark
                }
                if !info.avatarURL.isEmpty {
                    item.avatarURL = info.avatarURL
                }
            }
        }
        self.reloadData()
    }
    
    public func swipeMenuOperation(info: ConversationInfo, type: UIContextualActionType) {
        switch type {
        case .read: self.read(info: info)
        case .mute: self.mute(info: info)
        case .unmute: self.unmute(info: info)
        case .delete: self.delete(info: info)
        default: break
        }
    }
    
    
    private func updateIndexMap() {
        for (index,info) in self.datas.enumerated() {
            self.indexMap[info.id] = index
        }
    }
    
    public func appendThenRefresh(infos: [ConversationInfo]) {
        self.datas.append(contentsOf: infos)
        self.updateIndexMap()
        self.reloadDataSafe()
    }
    
    private func read(info: ConversationInfo) {
        if let index = self.datas.firstIndex(where: { $0.id == info.id }) {
            self.datas[safe: index]?.unreadCount = 0
            if self.indexPathsForVisibleRows?.contains(where: { $0.row == index }) ?? false {
                self.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    private func unread(info: ConversationInfo) {
        if let index = self.datas.firstIndex(where: { $0.id == info.id }) {
            self.datas[safe: index]?.unreadCount = 1
            if self.indexPathsForVisibleRows?.contains(where: { $0.row == index }) ?? false {
                self.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    private func mute(info: ConversationInfo) {
        if let index = self.datas.firstIndex(where: { $0.id == info.id }) {
            self.datas[safe: index]?.doNotDisturb = true
            if self.indexPathsForVisibleRows?.contains(where: { $0.row == index }) ?? false {
                self.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    private func unmute(info: ConversationInfo) {
        if let index = self.datas.firstIndex(where: { $0.id == info.id }) {
            self.datas[safe: index]?.doNotDisturb = false
            if self.indexPathsForVisibleRows?.contains(where: { $0.row == index }) ?? false {
                self.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
            }
        }
    }
    
    private func delete(info: ConversationInfo) {
        if let index = self.datas.firstIndex(where: { $0.id == info.id }) {
            self.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.datas.remove(at: index)
            self.updateIndexMap()
        }
    }
    
    public func showNew(info: ConversationInfo) {
        self.datas.insert(info, at: 0)
        self.updateIndexMap()
        self.reloadDataSafe()
        self.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
    
}

extension ConversationList: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.reloadData()
    }
    
}

//MARK: - ConversationListActionEventsDelegate
/// Session list touch event callback proxy
@objc public protocol ConversationListActionEventsDelegate: NSObjectProtocol {
    
    /// When fetch conversations list occur error.Empty view retry button on clicked.The method will call.
    func onConversationListOccurErrorWhenFetchServer()
    
    /// The method will called on conversation list end scroll,then it will ask you for the session nickname and avatar data and then refresh it.
    /// - Parameter ids: [conversationId]
    func onConversationListEndScrollNeededDisplayInfos(ids: [String])
    
    /// Pull down to refresh
    func onConversationListRefresh()
    
    /// Callback on conversation was swiped.
    /// - Parameters:
    ///   - type: ``UIContextualActionType``
    ///   - info: ``ConversationInfo`` object.
    func onConversationSwipe(type: UIContextualActionType, info: ConversationInfo)
    
    /// Callback on conversation was selected.
    /// - Parameters:
    ///   - indexPath: The ``IndexPath`` of selected cell.
    ///   - info: ``ConversationInfo`` object.
    func onConversationDidSelected(indexPath: IndexPath, info: ConversationInfo)
    
    /// Callback on conversation was long pressed.
    /// - Parameters:
    ///   - indexPath: The ``IndexPath`` of long pressed cell.
    ///   - info: ``ConversationInfo`` object.
    func onConversationLongPressed(indexPath: IndexPath, info: ConversationInfo)
}

//MARK: - IConversationListDriver
/// ConversationList view driver.
@objc public protocol IConversationListDriver: NSObjectProtocol {
    
    /// Add UI actions handler.
    /// - Parameter actionHandler: ``ConversationListActionEventsDelegate``
    func addActionHandler(actionHandler: ConversationListActionEventsDelegate)
    
    /// Remove UI action handler.
    /// - Parameter actionHandler: ``ConversationListActionEventsDelegate``
    func removeActionHandler(actionHandler: ConversationListActionEventsDelegate)
    
    /// When fetch list occur error.
    func occurError()
    
    /// Conversation Operation event after clicking the button in the side-sliding menu.
    /// - Parameters:
    ///   - info: ``ConversationInfo`` object.
    ///   - type: ``UIContextualActionType``
    func swipeMenuOperation(info: ConversationInfo, type: UIContextualActionType)
    
    /// When you received a new contact message,you can call the method.
    /// - Parameter info: ``ConversationInfo`` object.
    func showNew(info: ConversationInfo)
    
    /// This method can be used when you want refresh some  display info  of datas.
    /// - Parameter infos: Array of conform ``EaseProfileProtocol`` object.
    func refreshProfiles(infos: [EaseProfileProtocol])
    
    /// This method can be used when pulling down to refresh.
    /// - Parameter infos: Array of ConversationInfo objects.
    func refreshList(infos: [ConversationInfo])
    
    /// When you receive a lot of messages from new contacts, you can call this method for data transfer.
    /// - Parameter infos: ``ConversationInfo`` object.
    func appendThenRefresh(infos: [ConversationInfo])
    
}

