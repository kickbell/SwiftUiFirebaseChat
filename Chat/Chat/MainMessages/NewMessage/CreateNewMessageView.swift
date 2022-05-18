//
//  CreateNewMessageView.swift
//  Chat
//
//  Created by jc.kim on 5/19/22.
//

import SwiftUI

struct CreateNewMessageView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                ForEach(0..<10) { num in
                    Text("New User...")
                }
            }
            .navigationTitle("New Message")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button {
                        
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
        CreateNewMessageView()
    }
}
