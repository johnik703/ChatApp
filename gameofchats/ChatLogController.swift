//
//  ChatLogController.swift
//  gameofchats
//
//  Created by John Nik on 4/6/17.
//  Copyright © 2017 johnik703. All rights reserved.
//

import UIKit
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var user: User? {
        
        didSet {
            navigationItem.title = user?.name
            
            observeMessages()
        }
        
    }
    
    var messages = [Message]()
    
    func observeMessages() {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = user?.id else {
            return
        }
        
        let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(uid).child(toId)
        
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child("messages").child(messageId)
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else {
                    return
                }
                
                                
                
                self.messages.append(Message(dictionary: dictionary))
                
                DispatchQueue.main.async {
                    print("collectionView reloaddata")
                    self.collectionView?.reloadData()
                    
                    //scroll to the last index
                    
                    let indexpath = IndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexpath, at: .bottom, animated: true)
                    
                }
                
                
                
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
    }
    
   
    
    
    
    let cellId = "cellId"
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
//        collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
//        navigationItem.title = "Chat Log Controller"
        collectionView?.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        
        let chatInputContainerview = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        
        chatInputContainerview.chatLogController = self
        
        return chatInputContainerview
        
        
//        let containerView = UIView()
//        containerView.frame = CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50)
//        containerView.backgroundColor = UIColor.white
        
                
//        return containerView
        
    }()
    
    func handleUploadTap() {
        
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? NSURL{
            
            
            //we selected video
            
            handleVideoSelectedForUrl(url: videoUrl as URL)
            
           
        } else {
            
            //we selected an image
           handleImageSelectedForInfo(info: info as [String : AnyObject])
            
        }
        
        
        dismiss(animated: true, completion: nil)
        
    }
    private func handleVideoSelectedForUrl(url: URL) {
        
        let filename = NSUUID().uuidString + ".mov"
        let uploadTask = FIRStorage.storage().reference().child("message_movies").child(filename).putFile(url as URL, metadata: nil, completion: { (metadata, error) in
            
            if error != nil {
                print("Failed upload of video!", error!)
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
//                print(videoUrl)
                
                //all we are missing now is imageUrl
                if let thumbmailImage = self.thumbmailImageForFileUrl(fileUrl: url) {
                    
                    self.uploadToFirebaseStorageUsingImage(image: thumbmailImage, completiion: { (imageUrl) in
                        
                        let properties: [String: AnyObject] = ["imageUrl": imageUrl as AnyObject, "imageWidth": thumbmailImage.size.width as AnyObject, "imageHeight": thumbmailImage.size.height as AnyObject, "videoUrl": videoUrl as AnyObject]
                        
                        self.sendMessageWithProperties(properties: properties)
                        
                    })
                }
            }
         })
        
        uploadTask.observe(.progress) { (snapshot) in
            
            if let completeUniCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completeUniCount)
            }
//            print(snapshot.progress?.completedUnitCount)
            
        }
        uploadTask.observe(.success) { (snapshot) in
            
            self.navigationItem.title = self.user?.name
            
        }

        
    }
    
    private func thumbmailImageForFileUrl(fileUrl: URL) -> UIImage? {
        
        
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            
            let thumbmailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbmailCGImage)
            
        } catch let err {
//            print(err)
        }
        
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String: AnyObject]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            uploadToFirebaseStorageUsingImage(image: selectedImage, completiion: { (imageUrl) in
                
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)

                
            })
            
//            uploadToFirebaseStorageUsingImage(image: selectedImage)
        }

        
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completiion: @escaping (_ imageUrl: String) -> ()) {
        
        let imageName = NSUUID().uuidString
        let ref = FIRStorage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            
            ref.put(uploadData, metadata: nil, completion: { (metadata, error) in
                
                if error != nil {
                    print("Failed to upload image", error!)
                    return
                }
                
                if let imageUrl = metadata?.downloadURL()?.absoluteString {
                    
                    completiion(imageUrl)
                    
//                    self.sendMessageWithImageUrl(imageUrl: imageUrl, image: image)
                    
                }
                
//                print(metadata?.downloadURL()?.absoluteString)
                
            })
            
        }
        
        
    }
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // scroll containerView

    override var inputAccessoryView: UIView? {
        
        get {
            return inputContainerView
        }
        
    }
    
    override var canBecomeFirstResponder: Bool {
        
        return true
        
    }
    
    func setupKeyboardObservers() {
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: .UIKeyboardDidShow, object: nil)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
//        
//        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
    }
    // keyboard show hide remove
    override func viewDidDisappear(_ animated: Bool) {
        
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    func handleKeyboardDidShow() {
        
        if messages.count > 0 {
            
            let indexPath = IndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath, at: .top, animated: true)
            
        }
 
    }
    
    func handleKeyboardWillShow(notification: NSNotification) {
        
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
        containerViewBottomAncher?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!) { 
            self.view.layoutIfNeeded()
        }
        
    }
    
    func handleKeyboardWillHide(notification: NSNotification) {
        
//        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
        containerViewBottomAncher?.constant = 0
        UIView.animate(withDuration: keyboardDuration!) {
            self.view.layoutIfNeeded()
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        //orientaion enable
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        cell.chatLogController = self
        
        let message = messages[indexPath.item]
        
        cell.message = message
        
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)
        
        
        if let text = message.text {
            // a text message
            cell.bubbleWidthAncher?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
            
        } else if message.imageUrl != nil {
            
            cell.bubbleWidthAncher?.constant = 200
            cell.textView.isHidden = true
            
        }
        
//        if message.videoUrl != nil {
//            
//            cell.playButton.isHidden = false
//            
//        } else {
//            cell.playButton.isHidden = true
//        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
        
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message) {
        
        
        if let profileImageUrl = self.user?.profileImageUrl {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == FIRAuth.auth()?.currentUser?.uid {
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAncher?.isActive = true
            cell.bubbleViewLeftAncher?.isActive = false
        } else {
            cell.bubbleView.backgroundColor = UIColor.lightGray
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAncher?.isActive = false
            cell.bubbleViewLeftAncher?.isActive = true
        }
        
        if let messageImageUrl = message.imageUrl {
            
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
            cell.bubbleView.backgroundColor = UIColor.clear
            
        } else {
            cell.messageImageView.isHidden = true
        }

    
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        let message = messages[indexPath.item]
        
        if let text = message.text {
            
            height = estimateFrameForText(text: text).height + 20
            
        } else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue {
            
            // h1 / w1 = h2 / w2
            //solve for h1
            // h1 = h2 / w2 * w1
            
            height = CGFloat(imageHeight / imageWidth * 200)
            
            
        }
        
        let width = UIScreen.main.bounds.width
        return CGSize(width: width, height: height)
        
    }
    
    private func estimateFrameForText(text: String) -> CGRect {
        
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16)], context: nil)
        
    }
    
    var containerViewBottomAncher: NSLayoutConstraint?
    
    func handleSend() {
        
        let properties = ["text": inputContainerView.inputTextField.text!] as [String : AnyObject]
        
        sendMessageWithProperties(properties: properties)
        
        
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage) {
        
        let properties = ["imageUrl": imageUrl, "imageWidth": image.size.width, "imageHeight": image.size.height] as [String : AnyObject]
        
        sendMessageWithProperties(properties: properties)
        
    }

    private func sendMessageWithProperties(properties: [String: AnyObject]) {
        
        let ref = FIRDatabase.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        
        let toId = user!.id
        
        let fromId = FIRAuth.auth()!.currentUser!.uid
        
        let timestamp = NSDate().timeIntervalSince1970 as NSNumber
        
        var values = ["toId": toId!, "fromId": fromId, "timestamp": timestamp] as [String : AnyObject]
        
        
        //append properties dictionary onto values somehow??
        //key $0, value $1
        properties.forEach({values[$0] = $1})
        
        //        childRef.updateChildValues(values)
        
        childRef.updateChildValues(values) { (error, ref) in
            
            if error != nil {
                print(error!)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            
            let userMessagesRef = FIRDatabase.database().reference().child("user-messages").child(fromId).child(toId!)
            
            let messageId = childRef.key
            userMessagesRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = FIRDatabase.database().reference().child("user-messages").child(toId!).child(fromId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
            
        }

        
    }
    
    // return enter clicking to send messages
    
   
    
    var startingFrame: CGRect?
    
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    //my custom zooming logic
    
    func performZoomingForStartingImageView(startingImageView: UIImageView) {
        
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            keyWindow.addSubview(blackBackgroundView!)
            
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                //math?
                //h2 / w2 = h1 / w1
                // h2 = h1 / w1 * w2
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
            }, completion: { (completed) in
                
//                zoomOutImageView.removeFromSuperview()
                
            })
            
//            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { 
//                
//                //math?
//                //h2 / w2 = h1 / w1
//                // h2 = h1 / w1 * w2
//                self.blackBackgroundView?.alpha = 1
//                self.inputContainerView.alpha = 0
//                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
//                
//                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
//                zoomingImageView.center = keyWindow.center
//                
//            }, completion: nil)
            
        }
    }
    
    func handleZoomOut(tapGesture: UITapGestureRecognizer) {
        
        if let zoomOutImageView = tapGesture.view {
            
            //need to animate back out to controller
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.layer.masksToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: { 
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                
            }, completion: { (completed) in
                
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
                
            })
            
//            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: { 
//                
//                zoomOutImageView.frame = self.startingFrame!
//                self.blackBackgroundView?.alpha = 0
//                
//            }, completion: { (completed: Bool) in
//                
//                // do something here later
//                zoomOutImageView.removeFromSuperview()
//                
//            })
            
        }
        
    }
    
}













