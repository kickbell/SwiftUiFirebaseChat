//
//  MainMessagesView.swift
//  Chat
//
//  Created by jc.kim on 5/7/22.
//

import SwiftUI

struct MainMessagesView: View {
    var body: some View {
        NavigationView {
            
            VStack {
                // custom nav bar
                HStack(spacing: 16) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 34, weight: .heavy))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("USER NAME")
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
                    Image(systemName: "gear")
                }
                .padding()
                
                ScrollView {
                    ForEach(0..<10, id: \.self) { num in
                        VStack {
                            HStack(spacing: 16) {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 32))
                                    .padding(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 44)
                                            .stroke(.black, lineWidth: 1)
                                    )
                                    
                                VStack(alignment: .leading) {
                                    Text("Username")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Message sent to user")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    
                                }
                                Spacer()
                                Text("22d")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            Divider()
                                .padding(.vertical, 8)
                        }.padding(.horizontal)
                    }
                }
                .overlay(
                    Button {
                        
                    } label: {
                        HStack {
                            Spacer()
                            Text("+ New Message")
                                .font(.system(size: 16, weight: .bold))
                            Spacer()
                        }
                        .foregroundColor(.white)
                        .padding(.vertical)
                        .background(.blue)
                        .cornerRadius(32)
                        .padding(.horizontal)
                    }, alignment: .bottom)
                .navigationBarHidden(true)
                


                
                    
            }
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
