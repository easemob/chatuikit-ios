//
//  PinnedMessagesContainer.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/6/18.
//

import UIKit

let limitContainerHeight = ScreenHeight*(590/844.0)


@objc public protocol IPinnedMessagesContainerDriver: NSObjectProtocol {
    
    /// Add action events listener of ``PinnedMessagesContainer``.
    /// - Parameter actionHandler: The object of conform ``PinnedMessagesContainerDelegate``.
    func addActionHandler(actionHandler: PinnedMessagesContainerDelegate)
    
    /// Remove action events listener of ``PinnedMessagesContainer``.
    /// - Parameter actionHandler: The object of conform ``PinnedMessagesContainerDelegate``.
    func removeEventHandler(actionHandler: PinnedMessagesContainerDelegate)
    
    func refresh(entities: [PinnedMessageEntity])
    
    func remove(messageId: String)
}

@objc public protocol PinnedMessagesContainerDelegate: NSObjectProtocol {
    
    func didSelect(entity: PinnedMessageEntity)
    
    func remove(entity: PinnedMessageEntity)
}

@objc open class PinnedMessagesContainer: UIView {
    
    private var eventHandlers: NSHashTable<PinnedMessagesContainerDelegate> = NSHashTable<PinnedMessagesContainerDelegate>.weakObjects()
    
    public var entities: [PinnedMessageEntity] = []
    
    public private(set) lazy var pinCount: PinnedIndicatorView = {
        PinnedIndicatorView(frame: CGRect(x: 12, y: 10, width: self.frame.width-24, height: 34))
    }()
    
    public private(set) lazy var cover: UIView = {
        UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)).backgroundColor(.clear)
    }()
    
    public private(set) lazy var container: UIView = {
        let realHeight = CGFloat(self.entities.count*60)+34+16+8
        return UIView(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: realHeight < limitContainerHeight ? realHeight:limitContainerHeight))
    }()
    
    public private(set) lazy var messageList: UITableView = {
        var realHeight = limitContainerHeight-34-16-8
        if realHeight > CGFloat(self.entities.count*60) {
            realHeight = CGFloat(self.entities.count*60)
        }
        return UITableView(frame: CGRect(x: 0, y: self.pinCount.frame.maxY+8, width: self.frame.width, height: realHeight)).separatorStyle(.none).backgroundColor(.clear).registerCell(PinnedMessageCell.self, forCellReuseIdentifier: "PinnedMessageCell").separatorStyle(.none).rowHeight(60).backgroundColor(.clear).delegate(self).dataSource(self)
    }()
    
    public private(set) lazy var indicator: UIView = {
        UIView(frame: CGRect(x: self.frame.width/2.0-18, y: self.container.frame.height-10, width: 36, height: 5)).cornerRadius(2.5).backgroundColor(UIColor.theme.neutralColor8)
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubViews([self.cover,self.container,self.pinCount,self.messageList,self.indicator])
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc open func dismiss() {
        UIView.animate(withDuration: 0.382) {
            self.messageList.frame = CGRect(x: 0, y: self.pinCount.frame.maxY+8, width: self.frame.width, height: 0)
            self.container.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 56)
            self.indicator.isHidden = true
            self.cover.alpha = 0
            
        } completion: { finished in
            if finished {
                self.removeFromSuperview()
            }
        }
    }
    
    @objc open func show(datas: [PinnedMessageEntity]) {
        self.pinCount.content.text = "\(datas.count)"+"Pin Messages".chat.localize
        self.isHidden = false
        self.cover.alpha = 1
        self.container.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: 56)
        self.refresh(entities: datas)
    }
        
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.pinCount.content.text = "Sticky Message".chat.localize
        self.dismiss()
    }
}

extension PinnedMessagesContainer: UITableViewDelegate,UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.entities.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PinnedMessageCell", for: indexPath) as? PinnedMessageCell
        if let entity = self.entities[safe: indexPath.row] {
            cell?.refresh(entity: entity)
        }
        cell?.removeActionHandler = { [weak self] in
            self?.processRemoveAction(entity: $0)
        }
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        for handler in self.eventHandlers.allObjects {
            if let entity = self.entities[safe: indexPath.row] {
                handler.didSelect(entity: entity)
            }
        }
        self.dismiss()
    }
    
    @objc open func processRemoveAction(entity: PinnedMessageEntity) {
        for handler in self.eventHandlers.allObjects {
            handler.remove(entity: entity)
        }
    }
}

extension PinnedMessagesContainer: IPinnedMessagesContainerDriver {
    public func addActionHandler(actionHandler: any PinnedMessagesContainerDelegate) {
        if self.eventHandlers.contains(actionHandler) {
            return
        }
        self.eventHandlers.add(actionHandler)
    }
    
    public func removeEventHandler(actionHandler: any PinnedMessagesContainerDelegate) {
        self.eventHandlers.remove(actionHandler)
    }
    
    
    public func refresh(entities: [PinnedMessageEntity]) {
        self.entities = entities
        var containerHeight = CGFloat(self.entities.count*60)+34+16+8
        if containerHeight > limitContainerHeight {
            containerHeight = limitContainerHeight
        }
        self.indicator.isHidden = false
        UIView.animate(withDuration: 0.382) {
            self.container.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: containerHeight+5)
            self.messageList.frame =  CGRect(x: 0, y: self.pinCount.frame.maxY+8, width: self.frame.width, height: containerHeight-34-16-8)
            self.messageList.reloadData()
            self.indicator.frame = CGRect(x: self.frame.width/2.0-18, y: self.container.frame.height-10, width: 36, height: 5)
        }
    }
    
    public func remove(messageId: String) {
        if let index = self.entities.firstIndex(where: { $0.message.messageId == messageId }) {
            self.entities.remove(at: index)
            self.messageList.beginUpdates()
            self.messageList.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            self.messageList.endUpdates()
        }
        UIView.animate(withDuration: 0.382) {
            var containerHeight = CGFloat(self.entities.count*60)+34+16+8
            if containerHeight > limitContainerHeight {
                containerHeight = limitContainerHeight
            }

            self.container.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: containerHeight+5)
            self.messageList.frame =  CGRect(x: 0, y: self.pinCount.frame.maxY+8, width: self.frame.width, height: self.container.frame.height-34-16-8)
            self.indicator.frame = CGRect(x: self.frame.width/2.0-18, y: self.container.frame.height-10, width: 36, height: 5)
        }
    }
}

extension PinnedMessagesContainer: ThemeSwitchProtocol {
    public func switchTheme(style: ThemeStyle) {
        self.backgroundColor = .clear
        self.pinCount.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.cover.backgroundColor = style == .dark ? UIColor.theme.barrageDarkColor2:UIColor.theme.barrageLightColor2
        self.container.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.indicator.backgroundColor(style == .dark ? UIColor.theme.neutralColor3:UIColor.theme.neutralColor8)
    }
}
