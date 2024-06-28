//
//  TypealiasWrapper.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/8/31.
//

import Foundation
/**
 This code defines typealiases for chat client, delegates, errors, messages, message bodies, chatrooms, user info, connection state, options, recall info, and cursor result for two different chat SDKs: HyphenateChat and AgoraChat.
 
 If HyphenateChat is imported, the typealiases are defined for HyphenateChat classes. If AgoraChat is imported, the typealiases are defined for AgoraChat classes.
 
 */

#if canImport(HyphenateChat)
import HyphenateChat
public typealias ChatClient = EMClient
public typealias ChatClientListener = EMClientDelegate
public typealias ChatEventsListener = EMChatManagerDelegate
public typealias ChatError = EMError
public typealias ChatErrorCode = EMErrorCode
public typealias ChatMessage = EMChatMessage
public typealias ChatMessageBody = EMMessageBody
public typealias ChatTextMessageBody = EMTextMessageBody
public typealias ChatImageMessageBody = EMImageMessageBody
public typealias ChatVideoMessageBody = EMVideoMessageBody
public typealias ChatAudioMessageBody = EMVoiceMessageBody
public typealias ChatFileMessageBody = EMFileMessageBody
public typealias ChatCombineMessageBody = EMCombineMessageBody
public typealias ChatMessageAttachmentStatus = EMDownloadStatus
public typealias ChatLocationMessageBody = EMLocationMessageBody
public typealias ChatCustomMessageBody = EMCustomMessageBody
public typealias ChatCMDMessageBody = EMCmdMessageBody
public typealias ChatMessageBodyType = EMMessageBodyType
public typealias ChatroomEventsListener = EMChatroomManagerDelegate
public typealias ChatRoom = EMChatroom
public typealias UserInfo = EMUserInfo
public typealias ChatroomBeKickedReason = EMChatroomBeKickedReason
public typealias ConnectionState = EMConnectionState
public typealias ChatSDKOptions = EMOptions
public typealias RecallInfo = EMRecallMessageInfo
public typealias CursorResult = EMCursorResult
public typealias GroupEventsListener = EMGroupManagerDelegate
public typealias MultiDeviceEventsListener = EMMultiDevicesDelegate
public typealias MultiDeviceEvent = EMMultiDevicesEvent
public typealias ContactEventsListener = EMContactManagerDelegate
public typealias ContactRequestInterface = IEMContactManager
public typealias MessageReactionChange = EMMessageReactionChange
public typealias MessageReaction = EMMessageReaction
public typealias MessageReactionOperation = EMMessageReactionOperation
public typealias ChatConversation = EMConversation
public typealias ChatConversationType = EMConversationType
public typealias GroupLeaveReason = EMGroupLeaveReason
public typealias ChatGroup = EMGroup
public typealias ChatGroupOption = EMGroupOptions
public typealias SilentModeResult = EMSilentModeResult
public typealias SilentModeParam = EMSilentModeParam
public typealias Contact = EMContact
public typealias UserInfoType = EMUserInfoType
public typealias GroupChatThreadListener = EMThreadManagerDelegate
public typealias GroupChatThreadEvent = EMChatThreadEvent
public typealias GroupChatThread = EMChatThread
public typealias MessagePinOperation = EMMessagePinOperation
public typealias MessagePinInfo = EMMessagePinInfo
#elseif canImport(AgoraChat)
import AgoraChat
public typealias ChatClient = AgoraChatClient
public typealias ChatClientListener = AgoraChatClientDelegate
public typealias ChatEventsListener = AgoraChatManagerDelegate
public typealias ChatError = AgoraChatError
public typealias ChatErrorCode = AgoraChatErrorCode
public typealias ChatMessage = AgoraChatMessage
public typealias ChatMessageBody = AgoraChatMessageBody
public typealias ChatTextMessageBody = AgoraChatTextMessageBody
public typealias ChatImageMessageBody = AgoraChatImageMessageBody
public typealias ChatVideoMessageBody = AgoraChatVideoMessageBody
public typealias ChatAudioMessageBody = AgoraChatVoiceMessageBody
public typealias ChatFileMessageBody = AgoraChatFileMessageBody
public typealias ChatCombineMessageBody = AgoraChatCombineMessageBody
public typealias ChatMessageAttachmentStatus = AgoraChatDownloadStatus
public typealias ChatLocationMessageBody = AgoraChatLocationMessageBody
public typealias ChatCustomMessageBody = AgoraChatCustomMessageBody
public typealias ChatCMDMessageBody = AgoraChatCmdMessageBody
public typealias ChatMessageBodyType = AgoraChatMessageBodyType
public typealias ChatroomEventsListener = AgoraChatroomManagerDelegate
public typealias ChatRoom = AgoraChatroom
public typealias UserInfo = AgoraChatUserInfo
public typealias ChatroomBeKickedReason = AgoraChatroomBeKickedReason
public typealias ConnectionState = AgoraChatConnectionState
public typealias ChatSDKOptions = AgoraChatOptions
public typealias RecallInfo = AgoraChatRecallMessageInfo
public typealias CursorResult = AgoraChatCursorResult
public typealias GroupEventsListener = AgoraChatGroupManagerDelegate
public typealias MultiDeviceEventsListener = AgoraChatMultiDevicesDelegate
public typealias MultiDeviceEvent = AgoraChatMultiDevicesEvent
public typealias ContactEventsListener = AgoraChatContactManagerDelegate
public typealias ContactRequestInterface = IAgoraChatContactManager
public typealias MessageReactionChange = AgoraChatMessageReactionChange
public typealias MessageReaction = AgoraChatMessageReaction
public typealias MessageReactionOperation = AgoraChatMessageReactionOperation
public typealias ChatConversation = AgoraChatConversation
public typealias ChatConversationType = AgoraChatConversationType
public typealias GroupLeaveReason = AgoraChatGroupLeaveReason
public typealias ChatGroup = AgoraChatGroup
public typealias ChatGroupOption = AgoraChatGroupOptions
public typealias SilentModeResult = AgoraChatSilentModeResult
public typealias SilentModeParam = AgoraChatSilentModeParam
public typealias Contact = AgoraChatContact
public typealias UserInfoType = AgoraChatUserInfoType
public typealias GroupChatThreadListener = AgoraChatThreadManagerDelegate
public typealias GroupChatThreadEvent = AgoraChatThreadEvent
public typealias GroupChatThread = AgoraChatThread
public typealias MessagePinOperation = AgoraChatMessagePinOperation
public typealias MessagePinInfo = AgoraChatMessagePinInfo
#endif



