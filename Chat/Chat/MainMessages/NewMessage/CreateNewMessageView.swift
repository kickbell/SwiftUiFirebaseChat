//
//  CreateNewMessageView.swift
//  Chat
//
//  Created by jc.kim on 5/19/22.
//

import SwiftUI
import FirebaseFirestoreSwift

class CreatNewMessageViewModel: ObservableObject {
    @Published var users: [ChatUser] = []
    @Published var errorMessage = ""

    init() {
        fetchAllUsers()
    }
    
    private func fetchAllUsers() {
        FirebaseManager.shard.firestore.collection("users")
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

    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject private var vm = CreatNewMessageViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(vm.users) { user in
                    Text(user.email)
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
//        MainMessagesView()
        CreateNewMessageView()
    }
}
