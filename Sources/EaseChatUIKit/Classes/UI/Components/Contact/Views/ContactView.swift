import UIKit


/// The header display style of the ``ContactList``.
@objc public enum ContactListHeaderStyle: UInt {
    case newChat
    case contact
    case newGroup
    case shareContact
    case addGroupParticipant
}

/// ContactList action events delegate.
@objc public protocol ContactListActionEventsDelegate: NSObjectProtocol {
    
    /// When contact list scrolled.
    /// - Parameter indexPath: ``IndexPath``
    func onContactListScroll(indexPath: IndexPath)
    
    /// When fetch conversations list occur error.Empty view retry button on clicked.The method will call.
    func onContactListOccurErrorWhenFetchServer()
    
    /// The method will called on conversation list end scroll,then it will ask you for the session nickname and avatar data and then refresh it.
    /// - Parameter ids: [conversationId]
    func onContactListEndScrollNeededDisplayInfos(ids: [String])
    
    /// The method'll called on contact list cell clicked.
    /// - Parameters:
    ///   - indexPath: ``IndexPath``
    ///   - profile: Conform to ``EaseProfileProtocol`` object.
    func didSelected(indexPath: IndexPath,profile: EaseProfileProtocol)
}


/// A driver protocol of ``ContactList``.
@objc public protocol IContactListDriver: NSObjectProtocol {
    
    /// Add UI actions handler.
    /// - Parameter actionHandler: ``ContactListActionEventsDelegate``
    func addActionHandler(actionHandler: ContactListActionEventsDelegate)
    
    /// Remove UI action handler.
    /// - Parameter actionHandler: ``ContactListActionEventsDelegate``
    func removeActionHandler(actionHandler: ContactListActionEventsDelegate)
    
    /// When fetch list occur error.
    func occurError()
    
    /// This method can be used when you want refresh some  display info  of datas.
    /// - Parameter infos: Array of conform to``EaseProfileProtocol`` object.
    func refreshProfiles(infos: [EaseProfileProtocol])
    
    /// This method can be used when pulling down to refresh.
    /// - Parameter infos: Array of conform to``EaseProfileProtocol`` objects.
    func refreshList(infos: [EaseProfileProtocol])
    
    /// The method can be used when you want to refresh header of the contact list.
    /// - Parameter info: ``ContactListHeaderItemProtocol``
    func refreshHeader(info: ContactListHeaderItemProtocol)
    
    /// The method can be used when you want to remove a contact.
    /// - Parameter info: ``EaseProfileProtocol``
    func remove(info: EaseProfileProtocol)
    
    /// The method can be user when you want to add someone to contact list.
    /// - Parameter info: ``EaseProfileProtocol``
    func appendThenRefresh(info: EaseProfileProtocol)
}

@objc open class ContactView: UIView {
    
    private var eventsDelegates: NSHashTable<ContactListActionEventsDelegate> = NSHashTable<ContactListActionEventsDelegate>.weakObjects()
    
    private var selectIndex = false
    
    public private(set) var rawData = [EaseProfileProtocol]()
    
    public private(set) var headerStyle: ContactListHeaderStyle = .contact
    
    public private(set) var contacts = [[EaseProfileProtocol]]()
    
    public private(set) var sectionTitles = [String]() {
        willSet {
            if newValue.count <= 0 {
                self.contactList.backgroundView = self.empty
            } else {
                self.contactList.backgroundView = nil
            }
        }
    }
    
    public var selectClosure: ((EaseProfileProtocol) -> ())?
    
    public private(set) lazy var header: ContactListHeader = {
        ContactListHeader(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: CGFloat(54*(self.headerStyle == .contact ? Appearance.contact.listHeaderExtensionActions.count:0))), style: .plain).backgroundColor(.clear)
    }()
    
    public private(set) lazy var empty: EmptyStateView = {
        EmptyStateView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height),emptyImage: UIImage(named: "empty",in: .chatBundle, with: nil), onRetry: { [weak self] in
            guard let `self` = self else { return }
            for listener in self.eventsDelegates.allObjects {
                listener.onContactListOccurErrorWhenFetchServer()
            }
        }).backgroundColor(.clear)
    }()
    
    public private(set) lazy var contactList: UITableView = {
        UITableView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height), style: .grouped).delegate(self).dataSource(self).tableFooterView(UIView()).rowHeight(Appearance.contact.rowHeight).separatorStyle(.none).showsVerticalScrollIndicator(false).sectionHeaderHeight(30).sectionFooterHeight(0).tableFooterView(UIView()).backgroundColor(.clear)
    }()
    
    public private(set) lazy var indexIndicator: SectionIndexList = {
        SectionIndexList(frame: CGRect(x: self.frame.width-18, y: self.header.frame.height+20, width: 16, height: CGFloat(Appearance.contact.listHeaderExtensionActions.count)*Appearance.contact.rowHeight+20), style: .plain).backgroundColor(.clear)
    }()

    internal override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    /// ``ContactView`` init method.
    /// - Parameters:
    ///   - frame: ``CGRect``
    ///   - headerStyle: ``ContactListHeaderStyle``
    @objc(initWithFrame:headerStyle:)
    public required init(frame: CGRect,headerStyle: ContactListHeaderStyle) {
        self.headerStyle = headerStyle
        super.init(frame: frame)
        if Appearance.contact.listHeaderExtensionActions.count > 0 {
            self.contactList.tableHeaderView(headerStyle == .contact ? self.header:nil)
        }
        self.contactList.keyboardDismissMode = .onDrag
        self.addSubViews([self.contactList,self.indexIndicator])
        self.indexIndicator.center = CGPoint(x: self.indexIndicator.center.x, y: self.contactList.center.y)
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.indexIndicator.selectClosure = { [weak self] in
            self?.contactList.scrollToRow(at: IndexPath(row: 0, section: $0.row), at: .middle, animated: true)
            self?.selectIndex = true
            DispatchQueue.main.asyncAfter(deadline: .now()+0.25) {
                self?.selectIndex = false
            }
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
//MARK: - UITableViewDelegate&UITableViewDataSource
extension ContactView: UITableViewDelegate,UITableViewDataSource {
    
    public func numberOfSections(in tableView: UITableView) -> Int {
        self.sectionTitles.count
    }
    
    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        UIView {
            UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: 30)).backgroundColor(.clear)
            UILabel(frame: CGRect(x: 16, y: 6, width: self.frame.width-32, height: 18)).text(self.sectionTitles[safe: section] ?? "").font(UIFont.theme.labelMedium).textColor(UIColor.theme.neutralColor5).backgroundColor(.clear)
        }
    }
    
    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView().backgroundColor(.green)
    }
     
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.contacts[safe: section]?.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(with: ComponentsRegister.shared.ContactsCell.self, reuseIdentifier: "EaseUIKit_ContactsCell")
        if cell == nil {
            cell = ComponentsRegister.shared.ContactsCell.init(displayStyle: (self.headerStyle == .newGroup || self.headerStyle == .addGroupParticipant) ? .withCheckBox:.normal,identifier: "EaseUIKit_ContactsCell")
        }
        if let item = self.contacts[safe:indexPath.section]?[safe: indexPath.row] {
            cell?.refresh(profile: item)
        }
        cell?.backgroundColor = .clear
        return cell ?? UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if self.headerStyle == .newGroup || self.headerStyle == .addGroupParticipant {
            if let item = self.contacts[safe:indexPath.section]?[safe: indexPath.row] {
                if let hooker = ComponentViewsActionHooker.shared.contact.groupWithSelected {
                    hooker(indexPath,item)
                } else {
                    item.selected = !item.selected
                    self.contactList.reloadRows(at: [indexPath], with: .automatic)
                    self.rawData.first { $0.id == item.id }?.selected = item.selected
                    for handler in self.eventsDelegates.allObjects {
                        handler.didSelected(indexPath: indexPath, profile: item)
                    }
                }
                self.selectClosure?(item)
            }
        } else {
            if let item = self.contacts[safe:indexPath.section]?[safe: indexPath.row] {
                if let hooker = ComponentViewsActionHooker.shared.contact.didSelectedContact {
                    hooker(indexPath,item)
                } else {
                    for handler in self.eventsDelegates.allObjects {
                        handler.didSelected(indexPath: indexPath, profile: item)
                    }
                }
                self.selectClosure?(item)
            }
        }
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if let indexPath = self.contactList.indexPathForRow(at: scrollView.contentOffset) {
            if !self.selectIndex {
                self.indexIndicator.selectItem(indexPath: indexPath)
            }
            for listener in self.eventsDelegates.allObjects {
                listener.onContactListScroll(indexPath: indexPath)
            }
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        var unknownInfoIds = [String]()
        if let visiblePaths = self.contactList.indexPathsForVisibleRows {
            for indexPath in visiblePaths {
                if let item = self.contacts[safe: indexPath.section]?[safe: indexPath.row] {
                    if item.nickname.isEmpty || item.avatarURL.isEmpty {
                        unknownInfoIds.append(item.id)
                    }
                }
            }
        }
        if !unknownInfoIds.isEmpty {
            for eventHandle in self.eventsDelegates.allObjects {
                eventHandle.onContactListEndScrollNeededDisplayInfos(ids: unknownInfoIds)
            }
        }
    }
    
}
//MARK: - IContactListDriver
extension ContactView: IContactListDriver {
    
    public func occurError() {
        self.contacts.removeAll()
        self.rawData.removeAll()
        self.sectionTitles.removeAll()
        self.empty.state = .error
        self.contactList.reloadData()
    }
    
    
    public func appendThenRefresh(info: EaseProfileProtocol) {
        self.rawData.append(info)
        self.refreshList(infos: self.rawData)
    }
    
    public func remove(info: EaseProfileProtocol) {
        var indexPath: IndexPath?
        for (section,sections) in self.contacts.enumerated() {
            if indexPath != nil {
                break
            }
            for (row,item) in sections.enumerated() {
                if info.id == item.id {
                    self.rawData.removeAll { $0.id == item.id }
                    indexPath = IndexPath(row: row, section: section)
                    break
                }
            }
        }
        if let idx = indexPath {
            self.contacts[idx.section].remove(at: idx.row)
            self.refreshList(infos: self.rawData)
        }
    }
    
    
    public func refreshHeader(info: ContactListHeaderItemProtocol) {
        for item in Appearance.contact.listHeaderExtensionActions {
            if item.featureIdentify == info.featureIdentify {
                item.showBadge = info.showBadge
                item.showNumber = info.showNumber
                item.numberCount = info.numberCount
            }
        }
        self.header.refresh()
    }
    
    public func addActionHandler(actionHandler: ContactListActionEventsDelegate) {
        if !self.eventsDelegates.contains(actionHandler) {
            self.eventsDelegates.add(actionHandler)
        }
    }
    
    public func removeActionHandler(actionHandler: ContactListActionEventsDelegate) {
        if self.eventsDelegates.contains(actionHandler) {
            self.eventsDelegates.remove(actionHandler)
        }
    }
    
    public func refreshProfiles(infos: [EaseProfileProtocol]) {
        for info in infos {
            if let profile = self.rawData.first(where: { $0.id == info.id }) {
                profile.nickname =  info.nickname.isEmpty ? info.id:info.nickname
                profile.avatarURL = info.avatarURL
                profile.selected = info.selected
                profile.remark = info.remark
            }
        }
        self.refreshList(infos: self.rawData)
    }
    
    public func refreshList(infos: [EaseProfileProtocol]) {
        self.empty.state = .empty
        self.contacts.removeAll()
        self.sectionTitles.removeAll()
        self.rawData = infos
        let tuple = ContactSorter.sort(contacts: self.rawData)
        self.contacts.append(contentsOf: tuple.0)
        self.sectionTitles.append(contentsOf: tuple.1)
        self.contactList.reloadData()
        self.indexIndicator.refresh(titles: self.sectionTitles)
    }
    
    
}

extension ContactView: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.header.reloadData()
        self.contactList.reloadData()
    }
}

//MARK: - ContactSorter
struct ContactSorter {
    static func sort(contacts: [EaseProfileProtocol]) -> ([[EaseProfileProtocol]],[String]) {
        var contactMap = [String:EaseProfileProtocol]()
        
        if contacts.count == 0 {
            return ([], [])
        }
        var sectionTitles: [String] = []
        var result: [[EaseProfileProtocol]] = []
        let indexCollation = UILocalizedIndexedCollation.current()
        sectionTitles.append(contentsOf: indexCollation.sectionTitles)
        if !sectionTitles.contains("#") {
            sectionTitles.append("#")
        }
        for _ in sectionTitles {
            result.append([])
        }
        var _: [String] = []
        var userInfos: [EaseProfileProtocol] = []
        for contact in contacts {
            contactMap[contact.id] = contact
            let profile = EaseProfile()
            profile.id = contact.id
            var showName = contact.remark
            if showName.isEmpty {
                showName = contact.nickname
            }
            if showName.isEmpty {
                showName = contact.id
            }
            profile.nickname = showName
            profile.avatarURL = contact.avatarURL
            userInfos.append(profile)
        }
        userInfos.sort {
            $0.nickname.caseInsensitiveCompare($1.nickname) == .orderedAscending
        }
        for user in userInfos {
            if let firstLetter = user.nickname.chat.pinYin.first?.uppercased() {
                if let sectionIndex = sectionTitles.firstIndex(of: firstLetter) {
                    let contact = EaseProfile()
                    contact.id = user.id
                    contact.nickname = contactMap[contact.id]?.nickname ?? ""
                    contact.avatarURL = user.avatarURL
                    contact.remark = contactMap[contact.id]?.remark ?? ""
                    result[sectionIndex].append(contact)
                } else {
                    let contact = EaseProfile()
                    contact.id = user.id
                    contact.nickname = contactMap[contact.id]?.nickname ?? ""
                    contact.avatarURL = user.avatarURL
                    contact.remark = contactMap[contact.id]?.remark ?? ""
                    result[sectionTitles.count-1].append(contact)
                }
            }
        }
        
        for i in (0..<result.count).reversed() {
            if result[i].count == 0 {
                result.remove(at: i)
                sectionTitles.remove(at: i)
            }
        }
        return (result,sectionTitles)
    }
}
