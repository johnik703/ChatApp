//
//  ChatInputContainerView.swift
//  gameofchats
//
//  Created by John Nik on 4/8/17.
//  Copyright © 2017 johnik703. All rights reserved.
//

import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate {
    
    var chatLogController: ChatLogController? {
        
        didSet {
            sendButton.addTarget(chatLogController, action: #selector(chatLogController?.handleSend), for: .touchUpInside)
            
            
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(chatLogController?.handleUploadTap)))
        }
    }
    
    let uploadImageView: UIImageView = {
        
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "upload_image")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        return uploadImageView
        
    }()
    
    lazy var inputTextField: UITextField = {
        
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
        
    }()
    
    let sendButton = UIButton(type: .system)
//    let uploadImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = UIColor.white
        
        addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor, constant: 5).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        
        //what is handle?
//        sendButton.addTarget(self, action: #selector(self.chatLogController?.handleSend), for: .touchUpInside)
        addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        
        addSubview(self.inputTextField)
        
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 5).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        let seperatorLineView = UIView()
        seperatorLineView.backgroundColor = UIColor.black
        seperatorLineView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(seperatorLineView)
        
        seperatorLineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        seperatorLineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        seperatorLineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        seperatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true

        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        chatLogController?.handleSend()
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
