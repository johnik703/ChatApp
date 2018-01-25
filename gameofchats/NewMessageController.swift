//
//  NewMessageController.swift
//  gameofchats
//
//  Created by John Nik on 3/29/17.
//  Copyright © 2017 johnik703. All rights reserved.
//

import UIKit
import Firebase

class NewMessageController: UITableViewController {

    let cellId = "cellId"
    
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancell))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        
        fetchUser()
        
        
       
    }
    
    func fetchUser() {
        
        FIRDatabase.database().reference().child("users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.id = snapshot.key
                user.setValuesForKeys(dictionary)
                
                self.users.append(user)
                
                DispatchQueue.main.async {
                    
                    self.tableView.reloadData()
                    
                }
                
//                print(user.name, user.email)
            }
            
            
            
        }, withCancel: nil)
        
    }
    
    func handleCancell() {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    var messagesController: ViewController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismiss(animated: true) { 
            
            let user = self.users[indexPath.row]
            
            self.messagesController?.showChatControllerForUser(user: user)
            
        }
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
//        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = user.email
        cell.timeLabel.text = nil
        
//        print(user.name, user.email)
        
//        cell?.imageView?.image = UIImage(named: "basketball.jpeg")
        
        if let profileImageUrl = user.profileImageUrl {
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
            
//            let url = URL(string: profileImageUrl)
//            URLSession.shared.dataTask(with: url!, completionHandler: { (data, response, error) in
//                
//                if error != nil {
//                    print(error!)
//                    return
//                }
//                
//                DispatchQueue.main.sync {
//                    
//                    cell.profileImageView.image = UIImage(data: data!)
//                    
//                }
//                
//            }).resume()
            
        }
        
        return cell
        
    }
    
}






















