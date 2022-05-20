//
//  ChatUser.swift
//  Chat
//
//  Created by jc.kim on 5/15/22.
//

import Foundation

struct ChatUser: Codable, Identifiable {
    var id: String { uid }
    let uid: String
    let email: String
    let profileImageUrl: String
}
