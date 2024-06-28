//
//  ChatThreadViewController.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2024/1/24.
//

import UIKit
import MobileCoreServices
import QuickLook
import AVFoundation

@objcMembers open class ChatThreadViewController: UIViewController {
    
    public private(set) var filePath = ""
            
    public private(set) var profile: GroupChatThread = GroupChatThread()
    
    public private(set) lazy var navigation: EaseChatNavigationBar = {
        self.createNavigation()
    }()
    
    /// Creates a navigation bar for the MessageListController.
    /// - Returns: An instance of EaseChatNavigationBar.
    @objc open func createNavigation() -> EaseChatNavigationBar {
        EaseChatNavigationBar(showLeftItem: true,textAlignment: .left,rightImages: [UIImage(named: "more_detail", in: .chatBundle, with: nil)!],hiddenAvatar: true).backgroundColor(.clear)
    }
        
    public private(set) lazy var entity: MessageEntity = {
        self.createEntity()
    }()
    
    open func createEntity() -> MessageEntity {
        let entity = ComponentsRegister.shared.MessageRenderEntity.init()
        entity.state = .succeed
        entity.historyMessage = true
        if let message = self.parentMessage {
            entity.message = message
        }
        _ = entity.content
        _ = entity.bubbleSize
        _ = entity.height
        return entity
    }
    
    public private(set) lazy var messageHeader: UITableView = {
        UITableView(frame: CGRect(x: 0, y: self.navigation.frame.maxY, width: self.view.frame.width, height: self.messageHeight()+20), style: .plain).dataSource(self).dataSource(self).separatorStyle(.none).backgroundColor(.clear).tableFooterView(UIView()).rowHeight(self.messageHeight())
    }()
    
    public private(set) lazy var messageContainer: MessageListView = {
        MessageListView(frame: CGRect(x: 0, y: self.navigation.frame.maxY, width: self.view.frame.width, height: self.view.frame.height-NavigationHeight), mention: false,showType: .thread)
    }()
    
    public private(set) lazy var loadingView: LoadingView = {
        self.createLoading()
    }()
    
    /**
     Creates a loading view.
     
     - Returns: A `LoadingView` instance.
     */
    @objc open func createLoading() -> LoadingView {
        LoadingView(frame: self.view.bounds)
    }
    
    public private(set) lazy var viewModel: ChatThreadViewModel = {
        ChatThreadViewModel(chatThread: self.profile)
    }()
    
    public private(set) var firstMessage: ChatMessage?
    
    public private(set) var parentMessage: ChatMessage?
    
    @objc(initWithChatThread:firstMessage:parentMessageId:)
    public required init(chatThread: GroupChatThread,firstMessage: ChatMessage? = nil,parentMessageId: String = "") {
        self.firstMessage = firstMessage
        self.profile = chatThread
        self.parentMessage = ChatClient.shared().chatManager?.getMessageWithMessageId(parentMessageId)
        super.init(nibName: nil, bundle: nil)
        self.requestChatThreadDetail()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        AudioTools.shared.stopPlaying()
        self.messageContainer.messages.forEach { $0.playing = false }
        self.messageContainer.messageList.reloadData()
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.theme.neutralColor98
        self.view.addSubViews([self.messageContainer,self.navigation])
        self.setupTitle()
//        if self.parentMessage != nil {
//            self.messageContainer.messageList.tableHeaderView = self.messageHeader
//        }
        self.navigation.clickClosure = { [weak self] in
            self?.navigationClick(type: $0, indexPath: $1)
        }
        EaseChatUIKitContext.shared?.onGroupNameUpdated = { [weak self] _,_ in
            self?.setupTitle()
        }
        Theme.registerSwitchThemeViews(view: self)
        self.switchTheme(style: Theme.style)
        self.view.addSubview(self.loadingView)
    }
    
    open func setupTitle() {
        if let group = ChatGroup(id: self.profile.parentId) {
            self.navigation.subtitle = "#"+(group.groupName.isEmpty ? self.profile.parentId:group.groupName)
        }
        self.navigation.title = self.profile.threadName.isEmpty ? self.profile.threadId:self.profile.threadName
    }
    
    open func requestChatThreadDetail() {
        ChatClient.shared().threadManager?.getChatThread(fromSever: self.profile.threadId, completion: { [weak self] thread, error in
            guard let `self` = self else { return }
            if error == nil,let chatThread = thread {
                self.profile = chatThread
                self.parentMessage = ChatClient.shared().chatManager?.getMessageWithMessageId(chatThread.messageId)
                self.entity = self.createEntity()
                if self.parentMessage != nil {
                    self.messageContainer.messageList.tableHeaderView = self.messageHeader
                }
                self.viewModel.bindDriver(driver: self.messageContainer, create: self.firstMessage != nil)
                self.viewModel.addEventsListener(self)
                if let firstMessage = self.firstMessage {
                    self.viewModel.sendFirstMessage(message: firstMessage)
                }
                self.messageHeader.reloadData()
                if let group = ChatGroup(id: chatThread.parentId) {
                    self.navigation.subtitle = "#"+(group.groupName.isEmpty ? group.groupId:group.groupName)
                    self.navigation.title = chatThread.threadName
                }
            } else {
                consoleLogInfo("requestChatThreadDetail error:\(error?.errorDescription ?? "")", type: .error)
            }
        })
    }
    
    
    
    deinit {
        EaseChatUIKitContext.shared?.cleanCache(type: .chat)
    }
}


extension ChatThreadViewController {
    
    open func messageHeight() -> CGFloat {
        var height = CGFloat(0)
        if self.parentMessage?.body.type == .text || self.parentMessage?.body.type == .image || self.parentMessage?.body.type == .video {
            height = self.entity.bubbleSize.height+(self.parentMessage?.body.type != .text ? 40:35)
        } else {
            height = 62
        }
        return height
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
        case .rightItems: self.rightItemsAction(indexPath: indexPath)
        case .cancel:
            self.navigation.editMode = false
            self.messageContainer.editMode = false
        default:
            break
        }
    }
    
    @objc open func rightItemsAction(indexPath: IndexPath?) {
       
        switch indexPath?.row {
        case 0: self.showMoreActions()
        default: break
        }
    }
    
    open func filterActions() -> [ActionSheetItemProtocol] {
        var items = [
            ActionSheetItem(title: "Topic Members", type: .normal, tag: "TopicMembers", image: UIImage(named: "create_group", in: .chatBundle, with: nil)),
            ActionSheetItem(title: "Leave Topic", type: .destructive, tag: "LeaveTopic", image: UIImage(named: "quit", in: .chatBundle, with: nil))
        ]
        let group = ChatGroup(id: self.profile.parentId)
        if group?.owner == EaseChatUIKitContext.shared?.currentUserId ?? "" {
            items.removeLast()
            items.append(ActionSheetItem(title: "Disband Topic", type: .destructive, tag: "DisbandTopic", image: UIImage(named: "quit", in: .chatBundle, with: nil)))

        }
        if group?.owner == EaseChatUIKitContext.shared?.currentUserId ?? "" || self.profile.owner == EaseChatUIKitContext.shared?.currentUserId ?? ""{
            items.insert(ActionSheetItem(title: "Edit Topic", type: .normal, tag: "EditTopic", image: UIImage(named: "message_action_edit", in: .chatBundle, with: nil)), at: 0)
        }
        return items
    }
    
    open func showMoreActions() {
        DialogManager.shared.showActions(actions: self.filterActions()) { [weak self] item in
            self?.processAction(item: item)
        }
    }
    
    open func processAction(item: ActionSheetItemProtocol) {
        switch item.tag {
        case "EditTopic": self.editTopicName()
        case "LeaveTopic": self.leaveTopic()
        case "TopicMembers": self.topicMembers()
        case "DisbandTopic": self.disbandTopic()
        default:
            break
        }
    }
    
    open func editTopicName() {
        let vc = GroupInfoEditViewController(groupId: self.profile.threadId, type: .threadName, rawText: self.profile.threadName) { [weak self] text in
            self?.navigation.title = text
        }
        ControllerStack.toDestination(vc: vc)
    }
    
    open func leaveTopic() {
        self.viewModel.operationTopic(option: .leave) {  [weak self] success in
            if success {
                self?.pop()
            } else {
                consoleLogInfo("leaveTopic error", type: .error)
            }
        }
    }
    
    open func disbandTopic() {
        self.viewModel.operationTopic(option: .destroy) {  [weak self] success in
            if success {
                self?.pop()
            } else {
                consoleLogInfo("disbandTopic error", type: .error)
            }
        }
    }
    
    open func topicMembers() {
        let vc = ChatThreadParticipantsController(chatThread: self.profile)
        ControllerStack.toDestination(vc: vc)
    }
    
    @objc open func pop() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
    
    
    
}

//MARK: - MessageListDriverEventsListener
extension ChatThreadViewController: MessageListDriverEventsListener {
    
    public func onChatThreadUpdated(chatThread: GroupChatThread) {
        self.profile = chatThread
        self.navigation.title = chatThread.threadName
    }
    
    public func onMessageMultiSelectBarClicked(operation: MessageMultiSelectedBottomBarOperation) {
        self.messageContainer.editMode = false
        self.navigation.editMode = false
        let messages = self.filterSelectedMessages()
        switch operation {
        case .delete:
            DialogManager.shared.showAlert(title: "barrage_long_press_menu_delete".chat.localize+" \(messages.count)"+" messages".chat.localize, content: "", showCancel: true, showConfirm: true) { [weak self] _ in
                self?.deleteMessages(messages: messages)
            }
        case .forward: self.forwardMessages(messages: messages)
        }
    }
    
    @objc open func forwardMessage(message: ChatMessage) {
        let vc = ForwardTargetViewController(messages: [message], combine: false)
        self.present(vc, animated: true)
    }
    
    @objc open func forwardMessages(messages: [ChatMessage]) {
        if messages.isEmpty {
            self.showToast(toast: "Please select a message to forward.")
            return
        }
        let vc = ForwardTargetViewController(messages: messages, combine: true)
        self.present(vc, animated: true)
    }
    
    @objc open func deleteMessages(messages: [ChatMessage]) {
        if messages.isEmpty {
            self.showToast(toast: "Please select a message to delete.")
            return
        }
        self.viewModel.deleteMessages(messages: messages)
    }
    
    open func filterSelectedMessages() -> [ChatMessage] {
        var messages = [ChatMessage]()
        for message in self.messageContainer.messages {
            if message.selected {
                messages.append(message.message)
            }
        }
        return messages
    }
    
    
    
    public func onUserQuitTopic() {
        self.pop()
    }
    
    public func onMessageTopicAreaClicked(entity: MessageEntity) { }
    
    
    public func onMessageMoreReactionAreaClicked(entity: MessageEntity) {
        self.showReactionDetailsController(message: entity)
    }
    
    
    public func onMessageWillSendFillExtensionInfo() -> Dictionary<String, Any> {
        //Insert extension info before sending message.
        self.messageWillSendFillExtensionInfo()
    }
    
    @objc open func messageWillSendFillExtensionInfo() -> Dictionary<String, Any> {
        [:]
    }
    /**
     Filters the available message actions based on the provided `MessageEntity`.
     
     - Parameters:
     - message: The `MessageEntity` object to filter the actions for.
     
     - Returns: An array of `ActionSheetItemProtocol` representing the filtered message actions.
     */
    @objc open func filterMessageActions(message: MessageEntity) -> [ActionSheetItemProtocol] {
        var messageActions = Appearance.chat.messageLongPressedActions
        if message.message.body.type != .text {
            messageActions.removeAll { $0.tag == "Copy" }
            messageActions.removeAll { $0.tag == "Edit" }
            messageActions.removeAll { $0.tag == "Translate" }
            messageActions.removeAll { $0.tag == "OriginalText" }
        } else {
            if message.message.direction != .send {
                messageActions.removeAll { $0.tag == "Edit" }
            } else {
                if message.message.status != .succeed {
                    messageActions.removeAll { $0.tag == "Edit" }
                }
            }
            if Appearance.chat.enableTranslation {
                if message.showTranslation {
                    messageActions.removeAll { $0.tag == "Translate" }
                } else {
                    messageActions.removeAll { $0.tag == "OriginalText" }
                }
            } else {
                messageActions.removeAll { $0.tag == "Translate" }
                messageActions.removeAll { $0.tag == "OriginalText" }
            }
        }
        if !Appearance.chat.contentStyle.contains(.withReply) {
            messageActions.removeAll { $0.tag == "Reply" }
        }
        messageActions.removeAll { $0.tag == "Pin" }
        messageActions.removeAll { $0.tag == "Topic" }
        if message.message.direction != .send {
            messageActions.removeAll { $0.tag == "Recall" }
        } else {
            let duration = UInt(abs(Double(Date().timeIntervalSince1970) - Double(message.message.timestamp/1000)))
            if duration > Appearance.chat.recallExpiredTime {
                messageActions.removeAll { $0.tag == "Recall" }
            }
        }
        messageActions.removeAll { $0.tag == "Recall" }
        messageActions.removeAll { $0.tag == "Delete" }
        return messageActions
    }
    
    public func onMessageBubbleLongPressed(message: MessageEntity) {
        self.showMessageLongPressedDialog(message: message)
    }
    
    /**
     Shows a long-pressed dialog for a given chat message.
     
     - Parameters:
     - message: The chat message for which the dialog is shown.
     */
    @objc open func showMessageLongPressedDialog(message: MessageEntity) {
        let header =  CommonReactionView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 44), message: message.message).backgroundColor(.clear)
        header.reactionClosure = { [weak self] emoji,rawMessage in
            UIViewController.currentController?.dismiss(animated: true) {
                if emoji.isEmpty {
                    //more reaction
                    self?.showAllReactionsController(message: message)
                } else {
                    self?.viewModel.operationReaction(emoji: emoji, message: rawMessage)
                }
            }
        }
        DialogManager.shared.showMessageActions(actions: self.filterMessageActions(message: message),withHeader: Appearance.chat.contentStyle.contains(.withMessageReaction) ? header:nil) { [weak self] item in
            self?.processMessage(item: item, message: message.message)
        }
    }
    
    @objc open func showAllReactionsController(message: MessageEntity) {
        let vc = MessageReactionsController(message: message.message) { [weak self] in
            self?.viewModel.driver?.reloadReaction(message: message.message)
        }
        self.presentViewController(vc)
    }
    
    @objc open func showReactionDetailsController(message: MessageEntity) {
        if let reactionMessage = ChatClient.shared().chatManager?.getMessageWithMessageId(message.message.messageId) {
            let vc = MessageReactionsDetailController(message: reactionMessage) { [weak self] in
                self?.viewModel.driver?.reloadReaction(message: reactionMessage)
                UIViewController.currentController?.dismiss(animated: true)
            }
            self.presentViewController(vc)
        }
        
    }
    
    /**
     Processes a chat message based on the selected action sheet item.
     
     - Parameters:
     - item: The selected action sheet item.
     - message: The chat message to be processed.
     */
    @objc open func processMessage(item: ActionSheetItemProtocol,message: ChatMessage) {
        switch item.tag {
        case "Copy":
            self.viewModel.processMessage(operation: .copy, message: message, edit: "")
        case "Edit":
            self.editAction(message: message)
        case "Reply":
            self.viewModel.processMessage(operation: .reply, message: message)
        case "Recall":
            self.viewModel.processMessage(operation: .recall, message: message)
        case "Translate":
            self.viewModel.processMessage(operation: .translate, message: message)
        case "OriginalText":
            self.viewModel.processMessage(operation: .originalText, message: message)
        case "Delete":
            self.viewModel.processMessage(operation: .delete, message: message)
        case "Report":
            self.reportAction(message: message)
        case "MultiSelect":
            self.multiSelect(message: message)
        case "Forward":
            self.forwardMessage(message: message)
        default:
            item.action?(item,message)
            break
        }
    }
    
    @objc open func multiSelect(message: ChatMessage) {
        self.messageContainer.messages.first { $0.message.messageId == message.messageId }?.selected = true
        self.messageContainer.editMode = true
        self.navigation.editMode = true
        self.messageContainer.messageList.reloadData()
    }
    /**
     Opens the message editor for editing a chat message.
     
     - Parameters:
     - message: The chat message to be edited.
     */
    @objc open func editAction(message: ChatMessage) {
        if let body = message.body as? ChatTextMessageBody {
            let editor = MessageEditor(content: body.text) { text in
                self.viewModel.processMessage(operation: .edit, message: message, edit: text)
                UIViewController.currentController?.dismiss(animated: true)
            }
            DialogManager.shared.showCustomDialog(customView: editor)
        }
    }
    
    @objc open func reportAction(message: ChatMessage) {
        DialogManager.shared.showReportDialog(message: message) { error in
            
        }
    }
    
    public func onMessageAttachmentLoading(loading: Bool) {
        self.messageAttachmentLoading(loading: loading)
    }
    
    @objc open func messageAttachmentLoading(loading: Bool) {
        if loading {
            self.loadingView.startAnimating()
        } else {
            self.loadingView.stopAnimating()
        }
    }
    
    public func onMessageBubbleClicked(message: MessageEntity) {
        self.messageBubbleClicked(message: message)
    }
    
    /**
     Handles the click event on a message bubble.
     
     - Parameters:
     - message: The ChatMessage object representing the clicked message.
     */
    @objc open func messageBubbleClicked(message: MessageEntity) {
        switch message.message.body.type {
        case .file,.video,.image:
            if let body = message.message.body as? ChatFileMessageBody {
                self.filePath = body.localPath ?? ""
            }
            self.openFile()
        case .custom:
            if let body = message.message.body as? ChatCustomMessageBody,body.event == EaseChatUIKit_user_card_message {
                self.viewContact(body: body)
            }
        case .combine:
            self.viewHistoryMessages(entity: message)
        default:
            break
        }
    }
    
    @objc open func viewHistoryMessages(entity: MessageEntity) {
        let vc = ChatHistoryViewController(message: entity.message)
        ControllerStack.toDestination(vc: vc)
    }
    
    /**
     Opens the contact view for the given custom message body.
     
     - Parameters:
     - body: The custom message body containing contact information.
     */
    @objc open func viewContact(body: ChatCustomMessageBody) {
        var userId = body.customExt?["userId"] as? String
        if userId == nil {
            userId = body.customExt?["uid"] as? String
        }
        let avatarURL = body.customExt?["avatar"] as? String
        let nickname = body.customExt?["nickname"] as? String
        if body.event == EaseChatUIKit_user_card_message {
            let profile = EaseProfile()
            profile.id = userId ?? ""
            profile.nickname = nickname ?? ""
            profile.avatarURL = avatarURL ?? ""
            let vc = ComponentsRegister.shared.ContactInfoController.init(profile: profile)
            vc.modalPresentationStyle = .fullScreen
            ControllerStack.toDestination(vc: vc)
        }
    }
    
    public func onMessageAvatarClicked(user: EaseProfileProtocol) {
        self.messageAvatarClick(user: user)
    }
    
    /**
     Handles the click event on the message avatar.
     
     - Parameters:
     - user: The user profile associated with the clicked avatar.
     */
    @objc open func messageAvatarClick(user: EaseProfileProtocol) {
        if user.id == EaseChatUIKitContext.shared?.currentUserId ?? "" {
            return
        }
        let vc = ComponentsRegister.shared.ContactInfoController.init(profile: user)
        vc.modalPresentationStyle = .fullScreen
        ControllerStack.toDestination(vc: vc)
    }
    
    public func onInputBoxEventsOccur(action type: MessageInputBarActionType, attributeText: NSAttributedString?) {
        switch type {
        case .audio: self.audioDialog()
        case .attachment: self.attachmentDialog()
        default:
            break
        }
    }
    
    /**
     Opens the audio dialog for recording and sending voice messages.
     
     This method stops any currently playing audio, presents a custom audio recording view, and sends the recorded audio message using the view model's `sendMessage` method.
     
     - Note: The audio recording view is an instance of `MessageAudioRecordView` and is presented as a custom dialog using `DialogManager.shared.showCustomDialog`.
     - Note: The recorded audio message is sent as a text message with the file path of the recorded audio and the duration of the recording as extension information.
     */
    @objc open func audioDialog() {
        AudioTools.shared.stopPlaying()
        let audioView = MessageAudioRecordView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 200+BottomBarHeight)) { [weak self] url, duration in
            UIViewController.currentController?.dismiss(animated: true)
            self?.viewModel.sendMessage(text: url.path, type: .voice, extensionInfo: ["duration":duration])
        } trashClosure: {
            
        }
        
        DialogManager.shared.showCustomDialog(customView: audioView,dismiss: false)
    }
    
    /**
     Opens an attachment dialog to allow the user to select an action.
     */
    @objc open func attachmentDialog() {
        DialogManager.shared.showActions(actions: Appearance.chat.inputExtendActions) { [weak self] item in
            self?.handleAttachmentAction(item: item)
        }
    }
    
    @objc open func handleAttachmentAction(item: ActionSheetItemProtocol) {
        switch item.tag {
        case "File": self.selectFile()
        case "Photo": self.selectPhoto()
        case "Camera": self.openCamera()
        case "Contact": self.selectContact()
        default:
            break
        }
    }
    
    /**
     Opens the photo library and allows the user to select a photo.
     
     - Note: This method checks if the photo library is available on the device. If it is not available, an alert is displayed to the user.
     */
    @objc open func selectPhoto() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            DialogManager.shared.showAlert(title: "permissions disable".chat.localize, content: "photo_disable".chat.localize, showCancel: false, showConfirm: true) { _ in
                
            }
            return
        }
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        self.present(imagePickerController, animated: true, completion: nil)
    }
    
    @objc open func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            DialogManager.shared.showAlert(title: "permissions disable".chat.localize, content: "camera_disable".chat.localize, showCancel: false, showConfirm: true) { _ in
                
            }
            return
        }
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        imagePicker.videoMaximumDuration = 20
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    /**
     Opens a document picker to allow the user to select a file.
     
     The document picker supports various file types including content, text, source code, images, PDFs, Keynote files, Word documents, Excel spreadsheets, PowerPoint presentations, and generic data files.
     
     - Note: The selected file will be handled by the `UIDocumentPickerDelegate` methods implemented in the `MessageListController`.
     */
    @objc open func selectFile() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.content", "public.text", "public.source-code", "public.image", "public.jpeg", "public.png", "com.adobe.pdf", "com.apple.keynote.key", "com.microsoft.word.doc", "com.microsoft.excel.xls", "com.microsoft.powerpoint.ppt","public.data"], in: .open)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .fullScreen
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    /**
     Selects a contact and shares their information.
     */
    @objc open func selectContact() {
        let vc = ComponentsRegister.shared.ContactsController.init(headerStyle: .shareContact)
        vc.confirmClosure = { profiles in
            vc.dismiss(animated: true) {
                if let user = profiles.first {
                    DialogManager.shared.showAlert(title: "Share Contact".chat.localize, content: "Share Contact".chat.localize+"`\(user.nickname.isEmpty ? user.id:user.nickname)`?", showCancel: true, showConfirm: true) { [weak self] _ in
                        self?.viewModel.sendMessage(text: EaseChatUIKit_user_card_message, type: .contact,extensionInfo: ["uid":user.id,"avatar":user.avatarURL,"nickname":user.nickname])
                    }
                    
                }
            }
        }
        self.present(vc, animated: true)
    }
    
    @objc open func openFile() {
        let previewController = QLPreviewController()
        previewController.dataSource = self
        self.navigationController?.pushViewController(previewController, animated: true)
    }
}

extension ChatThreadViewController: UITableViewDataSource, UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.parentMessage == nil ? 0:1
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "ChatThreadCreateHeaderCell") as? ChatHistoryCell
        if cell == nil,let message = self.parentMessage {
            cell = ChatHistoryCell(reuseIdentifier: "ChatThreadCreateHeaderCell", message: message)
        }
        cell?.selectionStyle = .none
        cell?.refresh(entity: self.entity)
        return cell ?? UITableViewCell()
    }
    
}

//MARK: - UIImagePickerControllerDelegate&UINavigationControllerDelegate
extension ChatThreadViewController:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        self.processImagePickerData(info: info)
        picker.dismiss(animated: true, completion: nil)
    }
    
    /**
     Processes the data received from the image picker.
     
     - Parameters:
     - info: A dictionary containing the information about the selected media.
     */
    @objc open func processImagePickerData(info: [UIImagePickerController.InfoKey : Any]) {
        let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String
        if mediaType == kUTTypeMovie as String {
            guard let videoURL = info[.mediaURL] as? URL else { return }
            guard let url = MediaConvertor.videoConvertor(videoURL: videoURL) else { return }
            let fileName = url.lastPathComponent
            let fileURL = URL(fileURLWithPath: MediaConvertor.filePath()+"/\(fileName)")
            if FileManager.default.fileExists(atPath: url.path) {
                do {
                    try Data(contentsOf: url).write(to: fileURL)
                } catch {
                    consoleLogInfo("write video error:\(error.localizedDescription)", type: .error)
                }
            }
            let duration = AVURLAsset(url: fileURL).duration.value
            self.viewModel.sendMessage(text: fileURL.path, type: .video,extensionInfo: ["duration":duration])
        } else {
            if let imageURL = info[.imageURL] as? URL {
                let fileName = imageURL.lastPathComponent
                let fileURL = URL(fileURLWithPath: MediaConvertor.filePath()+"/\(fileName)")
                do {
                    let image = UIImage(contentsOfFile: imageURL.path)
                    try image?.jpegData(compressionQuality: 1)?.write(to: fileURL)
                } catch {
                    consoleLogInfo("write image error:\(error.localizedDescription)", type: .error)
                }
                self.viewModel.sendMessage(text: fileURL.path, type: .image)
            } else {
                guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
                let correctImage = image.fixOrientation()
                let fileName = "\(Int(Date().timeIntervalSince1970)).jpeg"
                let fileURL = URL(fileURLWithPath: MediaConvertor.filePath()+"/\(fileName)")
                do {
                    try correctImage.jpegData(compressionQuality: 1)?.write(to: fileURL)
                } catch {
                    consoleLogInfo("write camera fixOrientation image error:\(error.localizedDescription)", type: .error)
                }
                self.viewModel.sendMessage(text: fileURL.path, type: .image)
            }
        }
    }
    
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
//MARK: - UIDocumentPickerDelegate
extension ChatThreadViewController: UIDocumentPickerDelegate {
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.documentPickerOpenFile(controller: controller,urls: urls)
        
    }
    
    @objc open func documentPickerOpenFile(controller: UIDocumentPickerViewController,urls: [URL]) {
        if controller.documentPickerMode == UIDocumentPickerMode.open {
            guard let selectedFileURL = urls.first else {
                return
            }
            if selectedFileURL.startAccessingSecurityScopedResource() {
                let fileURL = URL(fileURLWithPath: MediaConvertor.filePath()+"/\(selectedFileURL.lastPathComponent)")
                do {
                    try Data(contentsOf: selectedFileURL).write(to: fileURL)
                } catch {
                    consoleLogInfo("write file error:\(error.localizedDescription)", type: .error)
                }
                self.viewModel.sendMessage(text: fileURL.path, type: .file)
                selectedFileURL.stopAccessingSecurityScopedResource()
            } else {
                DialogManager.shared.showAlert(title: "permissions disable".chat.localize, content: "file_disable".chat.localize, showCancel: false, showConfirm: true) { _ in
                    
                }
            }
        }
    }
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
    
}

extension ChatThreadViewController: QLPreviewControllerDataSource {
    public func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    public func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        let fileURL = URL(fileURLWithPath: self.filePath)
        return fileURL as QLPreviewItem
    }
    
    
}
//MARK: - ThemeSwitchProtocol
extension ChatThreadViewController: ThemeSwitchProtocol {
    
    public func switchTheme(style: ThemeStyle) {
        self.navigation.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        self.view.backgroundColor = style == .dark ? UIColor.theme.neutralColor1:UIColor.theme.neutralColor98
        var images = [UIImage(named: "more_detail", in: .chatBundle, with: nil)!]
        if style == .light {
            images = images.map({ $0.withTintColor(UIColor.theme.neutralColor3) })
        }
        self.navigation.updateRightItems(images: images)
    }
    
}
