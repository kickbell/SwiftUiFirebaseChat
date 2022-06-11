//
//  ChatMessage.swift
//  Chat
//
//  Created by jc.kim on 6/3/22.
//

import Foundation

struct ChatMessage: Decodable, Identifiable {
    var id: String { documentId ?? "" }
    
    var documentId: String?
    let fromId: String
    let toId: String
    let text: String
}

