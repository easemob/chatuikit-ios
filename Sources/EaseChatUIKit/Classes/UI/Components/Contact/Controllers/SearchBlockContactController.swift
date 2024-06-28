//
//  SearchBlockContactController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/5.
//

import UIKit

@objcMembers open class SearchBlockContactController: UITableViewController {

    private var searchKeyWord = ""
    
    public var rawDatas = [EaseProfileProtocol]()
    
    private var selectClosure: ((EaseProfileProtocol) -> Void)?
         
    public private(set) var searchResults = [EaseProfileProtocol]()
    
    public private(set) lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.searchBar.showsCancelButton = true
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.automaticallyShowsSearchResultsController = true
        searchController.showsSearchResultsController = true
        searchController.automaticallyShowsScopeBar = false
        searchController.searchBar.backgroundImage = UIImage()
        searchController.searchBar.delegate = self
        return searchController
    }()
        
    public private(set) lazy var empty: EmptyStateView = {
        EmptyStateView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.width, height: self.tableView.frame.height),emptyImage: UIImage(named: "empty",in: .chatBundle, with: nil)) {
            
        }
    }()
    
    /// ``ContactListController`` init method.Only available in Objective-C language.
    /// - Parameters:
    ///   - headerStyle: ``ContactListHeaderStyle``
    ///   - action: Select row callback.
    @objc public required init(action: @escaping (EaseProfileProtocol) -> Void) {
        self.selectClosure = action
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = true
    }
    

    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.tableFooterView(UIView()).rowHeight(Appearance.contact.rowHeight).tableHeaderView(self.searchController.searchBar)
        self.tableView.keyboardDismissMode = .onDrag
        self.loadAllBlockUsers()
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    @objc public func loadAllBlockUsers() {
        if let users = ChatClient.shared().contactManager?.getBlackList() {
            let infos = users.map({
                let profile = EaseProfile()
                profile.id = $0
                profile.nickname = EaseChatUIKitContext.shared?.userCache?[$0]?.nickname ?? ""
                profile.avatarURL = EaseChatUIKitContext.shared?.userCache?[$0]?.avatarURL ?? ""
                profile.remark = EaseChatUIKitContext.shared?.userCache?[$0]?.remark ?? ""
                return profile
            })
            self.rawDatas.removeAll()
            self.searchResults.removeAll()
            self.rawDatas = infos
        }
        self.tableView.reloadData()
    }

    // MARK: - Table view data source

    open override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if self.searchResults.count <= 0 {
            self.tableView.backgroundView = self.empty
        } else {
            self.tableView.backgroundView = nil
        }
        return self.searchResults.count
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(with: ComponentsRegister.shared.ContactsCell.self, reuseIdentifier: "EaseUIKit_Block_Users_Cell_Search")
        if cell == nil {
            cell = ComponentsRegister.shared.ContactsCell.init(displayStyle: .normal,identifier: "EaseUIKit_Block_Users_Cell_Search")
        }
        if let item = self.searchResults[safe: indexPath.row] {
            cell?.refresh(profile: item,keyword: self.searchKeyWord)
        }
        cell?.selectionStyle = .none
        cell?.backgroundColor = .clear
        return cell ?? UITableViewCell()
    }
    
    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let item = self.searchResults[safe: indexPath.row] {
            item.selected = !item.selected
            self.selectClosure?(item)
        }
        self.tableView.reloadData()
    }
}

extension SearchBlockContactController: UISearchResultsUpdating,UISearchControllerDelegate,UISearchBarDelegate {

    public func updateSearchResults(for searchController: UISearchController) {
        searchController.searchResultsController?.view.isHidden = false
        self.searchKeyWord = searchController.searchBar.text?.lowercased() ?? ""
        if let searchText = searchController.searchBar.text?.lowercased() {
            self.searchResults = self.rawDatas.filter({ user in
                var showName = user.nickname.isEmpty ? user.id:user.nickname
                if !user.remark.isEmpty {
                    showName = user.remark
                }
                return (showName.lowercased() as NSString).range(of: searchText).location != NSNotFound && (showName.lowercased() as NSString).range(of: searchText).length >= 0
            })
        }
        self.tableView.reloadData()
    }
    
    public func willPresentSearchController(_ searchController: UISearchController) {
        self.searchController = searchController
    }
    
    public func didPresentSearchController(_ searchController: UISearchController) {
        
    }
    
    public func willDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    public func didDismissSearchController(_ searchController: UISearchController) {
        
    }
    
    public func presentSearchController(_ searchController: UISearchController) {
        
    }
    
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
}

extension SearchBlockContactController: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.searchController.searchBar.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.searchController.searchBar.barStyle = style == .dark ? .black:.default
        self.searchController.searchBar.searchTextField.textColor = style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1
        self.tableView.backgroundColor(style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98)
        self.tableView.reloadData()
    }
    
    
}
