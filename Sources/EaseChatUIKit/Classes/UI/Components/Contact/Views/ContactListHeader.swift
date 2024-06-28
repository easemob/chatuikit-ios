//
//  ContactListHeader.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/20.
//

import UIKit

@objc open class ContactListHeader: UITableView {
        
    @UserDefault("EaseChatUIKit_contact_new_request", defaultValue: Dictionary<String,Array<Dictionary<String,Any>>>()) private var newFriends
    
    override init(frame: CGRect, style: UITableView.Style) {
        super.init(frame: frame, style: style)
        self.isScrollEnabled = false
        self.tableFooterView(UIView()).dataSource(self).delegate(self).separatorStyle(.none).rowHeight(Appearance.contact.headerRowHeight).registerCell(ContactListHeaderCell.self, forCellReuseIdentifier: "ContactListHeaderCell").showsVerticalScrollIndicator(false)
        self.refresh()
    }

    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func refresh() {
        let unreadCount = self.newFriends[saveIdentifier]?.filter { $0["read"] as? Int == 0 }.count ?? 0
        let newRequest = Appearance.contact.listHeaderExtensionActions.first { $0.featureIdentify == "NewFriendRequest" }
        newRequest?.numberCount = UInt(unreadCount)
        newRequest?.showBadge = true
        newRequest?.showNumber = true
        self.reloadData()
    }
}

extension ContactListHeader: UITableViewDelegate,UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Appearance.contact.listHeaderExtensionActions.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ContactListHeaderCell") as? ContactListHeaderCell else { return ContactListHeaderCell(style: .default, reuseIdentifier: "ContactListHeaderCell") }
        cell.accessoryType = .disclosureIndicator
        if let item = Appearance.contact.listHeaderExtensionActions[safe: indexPath.row] {
            cell.refresh(item: item)
        }
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = Appearance.contact.listHeaderExtensionActions[safe: indexPath.row] {
            Appearance.contact.listHeaderExtensionActions[safe: indexPath.row]?.actionClosure?(item)
        }
    }
}
