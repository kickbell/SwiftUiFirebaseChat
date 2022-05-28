//
//  CreateNewMessageView.swift
//  Chat
//
//  Created by jc.kim on 5/19/22.
//

import SwiftUI
import FirebaseFirestoreSwift
import SDWebImageSwiftUI

class CreatNewMessageViewModel: ObservableObject {
    @Published var users: [ChatUser] = []
    @Published var errorMessage = " "
    
    let userName: (String) -> String = {
        $0.components(separatedBy: "@").first ?? ""
    }

    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shard.firestore.collection("users")
            .whereField("email", isNotEqualTo: "devjck@cashwalk.io")
            .getDocuments { snapshots, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch users:\(error)"
                    print("Failed to fetch users:\(error)")
                    return
                }
                snapshots?.documents.forEach { snapshot in
                    do {
                        let user = try snapshot.data(as: ChatUser.self)
                        self.users.append(user)
                    } catch {
                        self.errorMessage = error.localizedDescription
                        print(error.localizedDescription)
                    }
                }
            }
    }
}

struct CreateNewMessageView: View {
    
    let didSelectedUser: (ChatUser) -> ()

    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var vm = CreatNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users) { user in
                    Button {
                        didSelectedUser(user)
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 15) {
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .placeholder { Rectangle().foregroundColor(.gray) }
                                .indicator(.activity)
                                .transition(.fade(duration: 0.5))
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipped()
                                .cornerRadius(50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 50)
                                            .stroke(.black, lineWidth: 2)
                                )
                            Text(vm.userName(user.email))
                                .foregroundColor(.black)
                            Spacer()
                        }.padding(.horizontal)
                        Divider()
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            
        }
    }
}

struct CreateNewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
//        CreateNewMessageView()
    }
}
