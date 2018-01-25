//
//  ViewController.swift
//  gameofchats
//
//  Created by John Nik on 3/28/17.
//  Copyright © 2017 johnik703. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UITableViewController {

    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Add", style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
//        observeMessages()
        
//        observeUserMessages()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId() {
            
            FIRDatabase.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete message:", error!)
                    return
                }
                
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadTable()
                
//                //this is oone way of updating the table, but its actually not that safe.
//                self.messages.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                
            })
            
        }
        
        
    }
    
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    func observeUserMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            FIRDatabase.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                
                self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadTable()
            
        }, withCancel: nil)
        
    }
    
    private func fetchMessageWithMessageId(messageId: String) {
        
        let messageReference = FIRDatabase.database().reference().child("messages").child(messageId)
        messageReference.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let message = Message(dictionary: dictionary)
//                message.setValuesForKeys(dictionary)
                if let chatPartnerId = message.chatPartnerId() {
                    
                    self.messagesDictionary[chatPartnerId] = message
                }
                
                
                self.attemptReloadTable()
                
            }
            
        }, withCancel: nil)
        

        
    }
    
    private func attemptReloadTable() {
        
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
        
    }
    
    var timer: Timer?
    
    func handleReloadTable() {
        
        self.messages = Array(self.messagesDictionary.values)
        
        self.messages.sort(by: { (message1, message2) -> Bool in
            
            return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
            
        })
        
        DispatchQueue.main.async {
            print("reload table")
            self.tableView.reloadData()
        }
        
    }
    
    func observeMessages() {
        
        let ref = FIRDatabase.database().reference().child("messages")
        ref.observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                
                let message = Message(dictionary: dictionary)
//                message.setValuesForKeys(dictionary)
//                self.messages.append(message)
                
                if let toId = message.toId {
                    
                    self.messagesDictionary[toId] = message
                    
                    self.messages = Array(self.messagesDictionary.values)
                    
                    self.messages.sort(by: { (message1, message2) -> Bool in
                        
                        return (message1.timestamp?.intValue)! > (message2.timestamp?.intValue)!
                        
                    })
                    
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                
            }
            
            
            
        }, withCancel: nil)
        
    }
    
    
    
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cellId")
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        
        cell.message = message
        
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = FIRDatabase.database().reference().child("users").child(chatPartnerId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
//            print(snapshot)
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User()
            
            user.id = chatPartnerId
            
            user.setValuesForKeys(dictionary)
            
            self.showChatControllerForUser(user: user)
            
        }, withCancel: nil)
        
    }
    
    func handleNewMessage() {
        
        let newMessageController = NewMessageController()
        
        newMessageController.messagesController = self
        
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
        
    }
    
    func checkIfUserIsLoggedIn() {
        
        // user is not logged in
        if FIRAuth.auth()?.currentUser?.uid == nil {
            
            perform(#selector(handleLogout), with: nil, afterDelay: 0)
            
        } else {
            
            fetchUserAndSetupNavBarTitle()
            
        }
        
    }
    
    func fetchUserAndSetupNavBarTitle() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            
            return
            
        }
        
//        let uid = FIRAuth.auth()?.currentUser?.uid
        FIRDatabase.database().reference().child("users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
//                self.navigationItem.title = dictionary["name"] as? String
                
                let user = User()
                user.setValuesForKeys(dictionary)
                self.setupNavBarWithUser(user: user)
                
            }
            
        }, withCancel: nil)
    }
    
    func setupNavBarWithUser(user: User) {
        
        
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
//        titleView.backgroundColor = UIColor.red
        
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        titleView.addSubview(containerView)
        
        
        let profileImageview = UIImageView()
        profileImageview.contentMode = .scaleAspectFill
        profileImageview.layer.cornerRadius = 20
        profileImageview.layer.masksToBounds = true
        profileImageview.translatesAutoresizingMaskIntoConstraints = false
        if let profileImageUrl = user.profileImageUrl {
            
            profileImageview.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
            
        }
        
        containerView.addSubview(profileImageview)
        
        profileImageview.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageview.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        profileImageview.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageview.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        
        
        
        let nameLabel = UILabel()
        containerView.addSubview(nameLabel)
        
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageview.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageview.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageview.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
//        titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        
        
    }
    
    func showChatControllerForUser(user: User) {
        
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        
        navigationController?.pushViewController(chatLogController, animated: true)
        
    }
    
    func handleLogout() {
        
        do {
            try FIRAuth.auth()?.signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.messagesController = self
        present(loginController, animated: true, completion: nil)
        
    }


}

