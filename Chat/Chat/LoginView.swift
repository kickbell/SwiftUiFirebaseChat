//
//  ContentView.swift
//  SwiftUiFirebaseChat
//
//  Created by ios on 2022/05/02.
//

import SwiftUI
import Firebase

class FirebaseManager: NSObject {
    
    let auth: Auth
    let storage: Storage
    
    static let shard = FirebaseManager()
    
    override init() {
        FirebaseApp.configure()
        
        self.auth = Auth.auth()
        self.storage = Storage.storage()
        
        super.init()
    }
}

struct LoginView: View {
    
    @State var isLoginMode = false
    @State var email = ""
    @State var password = ""
    
    @State var shouldShowImagePicker = false
    
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Picker(selection: $isLoginMode,
                           content: {
                        Text("Login").tag(true)
                        Text("Create Account").tag(false)},
                           label: { Text("Picker Here") })
                    .pickerStyle(.segmented)
                    
                    if !isLoginMode {
                        Button {
                            shouldShowImagePicker.toggle()
                        } label: {
                            VStack {
                                if let image = self.image {
                                    Image(uiImage: image)
                                        .resizable()
                                        .frame(width: 128, height: 128)
                                        .scaledToFill()
                                        .cornerRadius(64)
                                    
                                } else {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 64))
                                        .padding()
                                        .foregroundColor(.black)
                                }
                            }
                            .overlay(
                                RoundedRectangle(cornerRadius: 64)
                                    .stroke(.black, lineWidth: 3)
                            )
                        }
                    }
                    
                    Group {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        SecureField("Password", text: $password)
                    }
                    .padding(10)
                    .background(.white)
                    
                    Button {
                        handleAction()
                    } label: {
                        HStack {
                            Spacer()
                            Text(isLoginMode ? "Login" : "Create Account")
                                .padding(.vertical, 15)
                                .foregroundColor(.white)
                                .font(.system(size: 15, weight: .bold))
                            Spacer()
                        }.background(.blue)
                    }
                    
                    Text(self.loginStatusMessage)
                        .foregroundColor(.red)
                    
                }.padding()
            }
            .navigationTitle(isLoginMode ? "Login" : "Create Account")
            .background(Color.init(white: 0, opacity: 0.05).ignoresSafeArea())
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $shouldShowImagePicker) {
            ImagePicker(image: $image)
        }
    }
    
    @State var image: UIImage?
    
    private func handleAction() {
        if isLoginMode {
            loginUser()
            print("기존 자격증명으로 Firebase에 로그인해야 합니다.")
        } else {
            createNewAccount()
            print("firebase auth 내부에 새 계정을 등록하고 어떻게 든 저장소에 이미지를 저장하십시오.")
        }
    }
    
    @State var loginStatusMessage = ""
    
    private func createNewAccount() {
        FirebaseManager.shard.auth.createUser(withEmail: email, password: password) { result, err in
            if let err = err {
                print("user create fail : \(err.localizedDescription)")
                self.loginStatusMessage = "user create fail : \(err.localizedDescription)"
                return
            }
            print("user create success : \(result?.user.uid ?? "")")
            self.loginStatusMessage = "user create success : \(result?.user.uid ?? "")"
            
            persistImageToStorage()
        }
    }
    
    private func loginUser() {
        FirebaseManager.shard.auth.signIn(withEmail: email, password: password) { result, err in
            if let err = err {
                print("login fail : \(err.localizedDescription)")
                self.loginStatusMessage = "login fail : \(err.localizedDescription)"
                return
            }
            print("login success : \(result?.user.uid ?? "")")
            self.loginStatusMessage = "login success : \(result?.user.uid ?? "")"
        }
    }
    
    private func persistImageToStorage() {
        guard let uid = FirebaseManager.shard.auth.currentUser?.uid else { return }
        let ref = FirebaseManager.shard.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else { return }
        ref.putData(imageData, metadata: nil) { metadata, err in
            if let err = err {
                self.loginStatusMessage = "Failed to push image to Storage: \(err.localizedDescription)"
                return
            }
            
            ref.downloadURL { url, err in
                if let err = err {
                    self.loginStatusMessage = "Failed to retrieve downloadURL: \(err.localizedDescription)"
                    return
                }
                
                self.loginStatusMessage = "Successfully stored image with url: \(url?.absoluteString ?? "")"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
