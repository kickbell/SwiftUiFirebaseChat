//
//  MainMessagesView.swift
//  Chat
//
//  Created by jc.kim on 5/7/22.
//

import SwiftUI
import FirebaseFirestoreSwift
import SDWebImageSwiftUI
import Firebase

struct RecentMessage: Identifiable {
  var id: String { documentID }
  let documentID: String
  let text: String
  let email: String
  let fromId: String
  let toId: String
  let profileImageUrl: String
  let tiemstamp: Timestamp
  
  init(documentId: String, data: [String: Any]) {
    self.documentID = documentId
    self.text = data["text"] as? String ?? ""
    self.email = data["email"] as? String ?? ""
    self.fromId = data["fromId"] as? String ?? ""
    self.toId = data["toId"] as? String ?? ""
    self.profileImageUrl = data["profileImageUrl"] as? String ?? ""
    self.tiemstamp = data["tiemstamp"] as? Timestamp ?? Timestamp(date: Date())
  }
}

class MainMessagesViewModel: ObservableObject {
  
  @Published var errorMessage = ""
  @Published var chatUser: ChatUser?
  @Published var recentMessages: [RecentMessage] = []
  
  var userName: String {
    return self.chatUser?.email.components(separatedBy: "@").first ?? ""
  }
  
  init() {
    DispatchQueue.main.async {
      self.isUserCurrentlyLoggedOut = FirebaseManager.shard.auth.currentUser?.uid == nil
    }
    
    fetchCurrentUser()
    fetchRecentMessages()
  }
  
  private func fetchRecentMessages() {
    guard let uid = FirebaseManager.shard.auth.currentUser?.uid else {
      return
    }
    
    FirebaseManager.shard.firestore
      .collection("recent_messages")
      .document(uid)
      .collection("messages")
      .order(by: "timestamp")
      .addSnapshotListener { querySnapshot, error in
        if let error = error {
          self.errorMessage = "Failed to listen for recent messages: \(error)"
          print("Failed to listen for recent messages: \(error)")
          return
        }
        
        querySnapshot?.documentChanges.forEach { change in
          let docId = change.document.documentID
          if let index = self.recentMessages.firstIndex(where: { $0.documentID == docId }) {
            self.recentMessages.remove(at: index)
          }
          self.recentMessages.insert(.init(documentId: docId, data: change.document.data()), at: 0)
        }
      }
    
  }
  
  func fetchCurrentUser() {
    guard let uid = FirebaseManager.shard.auth.currentUser?.uid else {
      self.errorMessage = "Could to find firebase uid"
      return
    }
    
    FirebaseManager.shard.firestore.collection("users")
      .document(uid).getDocument(as: ChatUser.self) { result in
        switch result {
        case let .success(chatuser):
          self.chatUser = chatuser
        case let .failure(error) :
          self.errorMessage = error.localizedDescription
        }
      }
  }
  
  @Published var isUserCurrentlyLoggedOut = false
  
  func handleSignOut() {
    isUserCurrentlyLoggedOut.toggle()
    try? FirebaseManager.shard.auth.signOut()
  }
}

struct MainMessagesView: View {
  
  @State var shouldShowLogOutOptions = false
  
  @State var shouldNavigateToChatLogView = false
  
  @ObservedObject private var vm = MainMessagesViewModel()
  
  private var customNavBar: some View {
    HStack(spacing: 16) {
      WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
        .resizable()
        .placeholder(Image(systemName: "person.fill"))
        .scaledToFill()
        .frame(width: 50, height: 50)
        .clipped()
        .cornerRadius(50)
        .overlay(RoundedRectangle(cornerRadius: 44)
          .stroke(Color(.label), lineWidth: 1)
        )
      
      VStack(alignment: .leading, spacing: 4) {
        Text(vm.userName)
          .font(.system(size: 24, weight: .bold))
        
        HStack {
          Circle()
            .foregroundColor(.green)
            .frame(width: 14, height: 14)
          Text("online")
            .font(.system(size: 12))
            .foregroundColor(.gray)
        }
      }
      Spacer()
      Button {
        shouldShowLogOutOptions.toggle()
      } label: {
        Image(systemName: "gear")
          .font(.system(size: 24, weight: .bold))
          .foregroundColor(.black)
      }
    }
    .padding()
    .actionSheet(isPresented: $shouldShowLogOutOptions) {
      .init(title: Text("Settings"),
            message: Text("What do you want to do?"),
            buttons: [
              .destructive(Text("Sign Out"), action: {
                vm.handleSignOut()
              }),
              .cancel()
            ]
      )
    }
    .fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil) {
      LoginView(didCompleteLoginProcess: {
        self.vm.isUserCurrentlyLoggedOut = false
        self.vm.fetchCurrentUser()
      })
    }
  }
  
  private var messageView: some View {
    ScrollView {
      ForEach(vm.recentMessages) { recentMessage in
        NavigationLink {
          ChatLogView(chatUser: self.chatUser)
        } label: {
          VStack {
            HStack(spacing: 16) {
              WebImage(url: URL(string: recentMessage.profileImageUrl))
                .resizable()
                .placeholder(Image(systemName: "person.fill"))
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                  .stroke(Color(.label), lineWidth: 1)
                )
              
              VStack(alignment: .leading, spacing: 8) {
                Text(recentMessage.email.components(separatedBy: "@").first ?? "")
                  .font(.system(size: 16, weight: .bold))
                Text(recentMessage.text)
                  .font(.system(size: 14))
                  .foregroundColor(.gray)
                  .multilineTextAlignment(.leading)
                
              }
              Spacer()
              Text("22d")
              //                            Text("\(recentMessage.tiemstamp.dateValue())")
                .font(.system(size: 14, weight: .semibold))
            }
            Divider()
              .padding(.vertical, 8)
          }
          .padding(.horizontal)
          .foregroundColor(.black)
        }
      }.padding(.bottom, 50)
    }
  }
  
  @State var shouldShowNewMessageScreen = false
  
  private var newMessageButton: some View {
    Button {
      shouldShowNewMessageScreen.toggle()
    } label: {
      HStack {
        Spacer()
        Text(" + New Message ")
          .font(.system(size: 16, weight: .bold))
        Spacer()
      }
      .foregroundColor(.white)
      .padding(.vertical)
      .background(.blue)
      .cornerRadius(32)
      .padding(.horizontal)
      .shadow(radius: 15)
    }
    .fullScreenCover(isPresented: $shouldShowNewMessageScreen) {
      CreateNewMessageView(didSelectedUser: { user in
        print(user)
        self.shouldNavigateToChatLogView.toggle()
        self.chatUser = user
      })
    }
  }
  
  @State var chatUser: ChatUser?
  
  var body: some View {
    NavigationView {
      VStack {
        customNavBar
        messageView
        
        NavigationLink("", isActive: $shouldNavigateToChatLogView) {
          ChatLogView(chatUser: self.chatUser)
        }
      }
      .overlay(
        newMessageButton, alignment: .bottom)
      .navigationBarHidden(true)
    }
  }
  
}

struct MainMessagesView_Previews1: PreviewProvider {
  static var previews: some View {
    MainMessagesView()
      .preferredColorScheme(.dark)
    
    MainMessagesView()
  }
}
