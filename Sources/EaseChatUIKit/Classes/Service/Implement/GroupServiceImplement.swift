//
//  GroupServiceImplement.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/11/6.
//

import UIKit

@objc public class GroupServiceImplement: NSObject {
    
    private var responseDelegates: NSHashTable<GroupServiceListener> = NSHashTable<GroupServiceListener>.weakObjects()
    
    private var threadDelegates: NSHashTable<GroupChatThreadEventListener> = NSHashTable<GroupChatThreadEventListener>.weakObjects()
    
    
    public override init() {
        super.init()
        ChatClient.shared().groupManager?.add(self, delegateQueue: .main)
        if Appearance.chat.contentStyle.contains(.withMessageThread) {
            ChatClient.shared().threadManager?.add(self, delegateQueue: .main)
        }
    }
    
    deinit {
        ChatClient.shared().groupManager?.removeDelegate(self)
        ChatClient.shared().threadManager?.remove(self)
    }
}

extension GroupServiceImplement: GroupService {
    public func bindGroupChatThreadEventListener(listener: GroupChatThreadEventListener) {
        if self.threadDelegates.contains(listener) {
            return
        }
        self.threadDelegates.add(listener)
    }
    
    public func unbindGroupChatThreadEventListener(listener: GroupChatThreadEventListener) {
        if self.threadDelegates.contains(listener) {
            self.threadDelegates.remove(listener)
        }
    }
    
    
    public func fetchGroupInfo(groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.getGroupSpecificationFromServer(withId: groupId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func bindGroupEventsListener(listener: GroupServiceListener) {
        if self.responseDelegates.contains(listener) {
            return
        }
        self.responseDelegates.add(listener)
    }
    
    public func unbindGroupEventsListener(listener: GroupServiceListener) {
        if self.responseDelegates.contains(listener) {
            self.responseDelegates.remove(listener)
        }
    }
    
    public func createGroup(subject: String, description: String, inviterIds: [String], message: String, option: ChatGroupOption, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.createGroup(withSubject: subject, description: description, invitees: inviterIds, message: message, setting: option, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func getJoinedGroups(page: UInt, pageSize: UInt, needMemberCount: Bool, needRole: Bool, completion: @escaping ([ChatGroup]?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.getJoinedGroupsFromServer(withPage: Int(page), pageSize: Int(pageSize), needMemberCount: needMemberCount, needRole: needRole, completion: { groups, error in
            completion(groups,error)
        })
    }
    
    public func invite(userIds: [String], to groupId: String, message: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.addMembers(userIds, toGroup: groupId, message: message,completion: { group, error in
            completion(group,error)
        })
    }
    
    public func remove(userIds: [String], from groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.removeMembers(userIds, fromGroup: groupId,completion: { group, error in
            completion(group,error)
        })
    }
    
    public func transfer(groupId: String, userId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.updateGroupOwner(groupId, newOwner: userId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func addAdmin(userId: String, to groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.addAdmin(userId, toGroup: groupId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func removeAdmin(userId: String, from groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.removeAdmin(userId, fromGroup: groupId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func mute(userIds: [String], duration: TimeInterval, groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.muteMembers(userIds, muteMilliseconds: Int(duration), fromGroup: groupId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func unmute(userIds: [String], groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.unmuteMembers(userIds, fromGroup: groupId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func getAnnouncement(groupId: String, completion: @escaping (String?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.getGroupAnnouncement(withId: groupId, completion: { announcement, error in
            completion(announcement,error)
        })
    }
    
    public func update(type: GroupInfoEditType,content: String, groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        switch type {
        case .name:
            ChatClient.shared().groupManager?.updateGroupSubject(content, forGroup: groupId, completion: { group, error in
                completion(group,error)
            })
        case .alias:
            ChatClient.shared().groupManager?.setMemberAttribute(groupId, userId: ChatClient.shared().currentUsername ?? "", attributes: ["nickName" : content],completion: { error in
                completion(nil,error)
            })
        case .description:
            ChatClient.shared().groupManager?.updateDescription(content, forGroup: groupId, completion: { group, error in
                completion(group,error)
            })
        case .announcement:
            ChatClient.shared().groupManager?.updateGroupAnnouncement(withId: groupId, announcement: content,completion: { group, error in
                completion(group,error)
            })
        case .threadName:
            ChatClient.shared().threadManager?.updateChatThreadName(content, threadId: groupId, completion: { error in
                completion(nil,error)
            })
        default:
            break
        }
    }
    
    public func update(ext: String, groupId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.updateGroupExt(withId: groupId, ext: ext,completion: { group, error in
            completion(group,error)
        })
    }
    
    public func agreeJoinApplication(groupId: String, userId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.approveJoinGroupRequest(groupId, sender: userId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func declineJoinApplication(groupId: String, userId: String, reason: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.declineJoinGroupRequest(groupId, sender: userId, reason: reason, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func acceptInvitation(groupId: String, inviterId: String, completion: @escaping (ChatGroup?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.acceptInvitation(fromGroup: groupId, inviter: inviterId, completion: { group, error in
            completion(group,error)
        })
    }
    
    public func declineInvitation(groupId: String, inviterId: String, reason: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().groupManager?.declineGroupInvitation(groupId, inviter: inviterId, reason: reason, completion: { error in
            completion(error)
        })
    }
    
    public func setMemberAttributes(attributes: Dictionary<String, String>, groupId: String, userId: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().groupManager?.setMemberAttribute(groupId, userId: userId,completion: { error in
            completion(error)
        })
    }
    
    public func fetchMemberAttribute(groupId: String, userId: String, completion: @escaping (ChatError?, Dictionary<String, String>?) -> Void) {
        ChatClient.shared().groupManager?.fetchMemberAttribute(groupId, userId: userId, completion: { attributes, error in
            completion(error,attributes)
        })
    }
    
    public func fetchMembersAttribute(groupId: String, userIds: [String], keys:[String], completion: @escaping (ChatError?, Dictionary<String, Dictionary<String, String>>?) -> Void) {
        ChatClient.shared().groupManager?.fetchMembersAttributes(groupId, userIds: userIds, keys: keys, completion: { attributes, error in
            completion(error,attributes)
        })
    }
    
    public func fetchParticipants(groupId: String, cursor: String, pageSize: UInt, completion: @escaping (CursorResult<NSString>?, ChatError?) -> Void) {
        ChatClient.shared().groupManager?.getGroupMemberListFromServer(withId: groupId, cursor: cursor, pageSize: Int(pageSize), completion: { result, error in
            completion(result,error)
        })
    }
    
    public func disband(groupId: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().groupManager?.destroyGroup(groupId, finishCompletion: { error in
            completion(error)
        })
    }
    
    public func leave(groupId: String, completion: @escaping (ChatError?) -> Void) {
        ChatClient.shared().groupManager?.leaveGroup(groupId, completion: { error in
            completion(error)
        })
    }
}

extension GroupServiceImplement: GroupEventsListener {
    public func groupInvitationDidReceive(_ aGroupId: String, groupName aGroupName: String, inviter aInviter: String, message aMessage: String?) {
        for listener in self.responseDelegates.allObjects {
            listener.onReceivedNewGroupInvitation?(groupId: aGroupId, groupName: aGroupName, userId: aInviter, invitation: aMessage ?? "")
        }
    }
    
    public func groupInvitationDidAccept(_ aGroup: ChatGroup, invitee aInvitee: String) {
        for listener in self.responseDelegates.allObjects {
            listener.onInviterAcceptedInvitationOfGroup?(groupId: aGroup.groupId, userId: aInvitee)
        }
    }
    
    public func groupInvitationDidDecline(_ aGroup: ChatGroup, invitee aInvitee: String, reason aReason: String?) {
        for listener in self.responseDelegates.allObjects {
            listener.onInviterDeclinedInvitationOfGroup?(groupId: aGroup.groupId, userId: aInvitee, reason: aReason ?? "")
        }
    }
    
    public func didJoin(_ aGroup: ChatGroup, inviter aInviter: String, message aMessage: String?) {
        for listener in self.responseDelegates.allObjects {
            listener.onCurrentUserJoinedGroup?(groupId: aGroup.groupId, invitation: aMessage ?? "")
        }
    }
    
    public func didLeave(_ aGroup: ChatGroup, reason aReason: GroupLeaveReason) {
        for listener in self.responseDelegates.allObjects {
            listener.onCurrentUserLeft?(groupId: aGroup.groupId, reason: aReason)
        }
    }
    
    public func joinGroupRequestDidDecline(_ aGroupId: String, reason aReason: String?) {
        
        for listener in self.responseDelegates.allObjects {
            listener.onGroupJoinApplicationDeclined?(groupId: aGroupId, reason: aReason ?? "")
        }
    }
    
    public func joinGroupRequestDidReceive(_ aGroup: ChatGroup, user aUsername: String, reason aReason: String?) {
        for listener in self.responseDelegates.allObjects {
            listener.onReceivedNewGroupApplication?(groupId: aGroup.groupId, userId: aUsername, reason: aReason ?? "")
        }
    }
    
    public func joinGroupRequestDidApprove(_ aGroup: ChatGroup) {
        for listener in self.responseDelegates.allObjects {
            listener.onGroupJoinApplicationApproved?(groupId: aGroup.groupId)
        }
    }
    
    public func groupOwnerDidUpdate(_ aGroup: ChatGroup, newOwner aNewOwner: String, oldOwner aOldOwner: String) {
        for listener in self.responseDelegates.allObjects {
            listener.onGroupOwnerUpdated?(groupId: aGroup.groupId, ownerId: aNewOwner, userId: aOldOwner)
        }
    }
    
    public func userDidJoin(_ aGroup: ChatGroup, user aUsername: String) {
        for listener in self.responseDelegates.allObjects {
            listener.onUserJoinedGroup?(groupId: aGroup.groupId, userId: aUsername)
        }
    }
    
    public func userDidLeave(_ aGroup: ChatGroup, user aUsername: String) {
        for listener in self.responseDelegates.allObjects {
            listener.onUserLeaveGroup?(groupId: aGroup.groupId, userId: aUsername)
        }
    }
    
    public func onAttributesChangedOfGroupMember(_ groupId: String, userId: String, attributes: [String : String]? = nil, operatorId: String) {
        for listener in self.responseDelegates.allObjects {
            listener.onAttributesChangedOfGroupMember?(groupId: groupId, userId: userId, operatorId: operatorId, attributes: attributes ?? [:])
        }
    }
}

extension GroupServiceImplement: GroupChatThreadListener {
    
    public func onChatThreadCreate(_ event: GroupChatThreadEvent) {
        for listener in self.threadDelegates.allObjects {
            listener.onGroupChatThreadEventOccur(type: .created, event: event)
        }
    }
    
    public func onChatThreadUpdate(_ event: GroupChatThreadEvent) {
        for listener in self.threadDelegates.allObjects {
            listener.onGroupChatThreadEventOccur(type: .updated, event: event)
        }
    }
    
    public func onChatThreadDestroy(_ event: GroupChatThreadEvent) {
        for listener in self.threadDelegates.allObjects {
            listener.onGroupChatThreadEventOccur(type: .destroyed, event: event)
        }
    }
    
    public func onUserKickOutOfChatThread(_ event: GroupChatThreadEvent) {
        for listener in self.threadDelegates.allObjects {
            listener.onGroupChatThreadEventOccur(type: .userKicked, event: event)
        }
    }
}
