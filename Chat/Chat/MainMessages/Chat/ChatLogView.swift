//
//  ChatLogView.swift
//  Chat
//
//  Created by ios on 2022/05/30.
//

import SwiftUI
import Firebase
import FirebaseFirestoreSwift


class ChatLogViewModel: ObservableObject {
    
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages: [ChatMessage] = []
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    
    
    private func fetchMessages() {
        guard let fromId = FirebaseManager.shard.auth.currentUser?.uid else { return }
        guard let toId = chatUser?.uid else { return }
        
        FirebaseManager.shard.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for messages: \(error)"
                    print("Failed to listen for messages: \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach { change in
                    guard change.type == .added else { return }
                    do {
                        var chatMessage = try change.document.data(as: ChatMessage.self)
                        chatMessage.documentId = change.document.documentID
                        self.chatMessages.append(chatMessage)
                    } catch {
                        self.errorMessage = "Failed to Decoding Error: \(error)"
                        print(error)
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self.count += 1
                    }
                }
            }
    }
    
    func handleSend() {
        guard let fromId = FirebaseManager.shard.auth.currentUser?.uid else {
            print("not exist fromId...")
            return
        }
        guard let toId = chatUser?.uid else {
            print("not exist toId...")
            return
        }
        
        let document = FirebaseManager.shard.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData: [String: Any] = [
            "documentId": "",
            "fromId": fromId,
            "toId": toId,
            "text": self.chatText,
            "timestamp": Timestamp()
        ]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                print("Failed to save message into Firestore: \(error)")
                return
            }
            print("Sending Message Success.")
            self.chatText = ""
            self.count += 1
        }
        
        let recipientMessageDocument = FirebaseManager.shard.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "Failed to save message into Firestore: \(error)"
                print("Failed to save message into Firestore: \(error)")
                return
            }
            print("Recipient Message Success.")
            print(messageData)
        }
    }
    
    @Published var count = 0
}

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.vm = .init(chatUser: chatUser)
    }
    
    @ObservedObject var vm: ChatLogViewModel
    
    var body: some View {
        ZStack {
            messagesView
            Text(vm.errorMessage)
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func scrollToBottom(_ proxy: ScrollViewProxy) -> some View {
        return HStack { Spacer().background(.blue) }
            .id(#function.description)
            .onReceive(vm.$count, perform: { _ in
                withAnimation(.easeOut(duration: 0.5)) {
                    proxy.scrollTo(#function.description, anchor: .bottom)
                }
            })
    }
    
    private var messagesView: some View {
        ScrollView {
            ScrollViewReader { proxy in
                ForEach(vm.chatMessages) { message in
                    MessageView(message: message)
                }
                scrollToBottom(proxy)
            }
        }
        .background(Color.init(white: 0.95))
        .safeAreaInset(edge: .bottom) {
            chatBottomBar
                .background(Color(.systemBackground).ignoresSafeArea())
        }
    }
    
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $vm.chatText)
                    .opacity(vm.chatText.isEmpty ? 0.5: 1)
            }
            .frame(height: 40)
            
            Button {
                vm.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.blue)
            .cornerRadius(8)
        }
        .padding(.horizontal)
        .padding(.vertical, 5)
    }
}


struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        VStack {
            if message.fromId == FirebaseManager.shard.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(.black)
                    }
                    .padding()
                    .background(.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 17))
                .padding(.leading, 5)
                .padding(.top, -4)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(chatUser: .init(uid: "nHebQEWFGDcOnHKgTSGqHBM0g6u2",
                                        email: "devjck@cashwalk.io",
                                        profileImageUrl: "https://firebasestorage.googleapis.com:443/v0/b/nudgechatapp.appspot.com/o/nHebQEWFGDcOnHKgTSGqHBM0g6u2?alt=media&token=03848b9f-b13f-4e51-93cf-9591793604f6"))
        }
    }
}



