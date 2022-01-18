//
//  ChatViewController.swift
//  MessengerApp
//
//  Created by administrator on 04/01/2022.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth

struct Message : MessageType {
    
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
    
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}


struct Sender: SenderType{
    var photoUrl: String
    var senderId: String
    var displayName: String
    
    
}


//MARK:
class ChatViewController: MessagesViewController {
    
    
    public static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    var isNewConversation = false
    
    var messeges = [Message]()
    
    
    var id : String?        // to be guard to conversationID
    var email : String?  //to be guard to otherUserEmail

    
    
    var mysender : Sender?  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else { // we can add as? String here,
            return Sender(photoUrl: "", senderId: "something", displayName: "noone")
        }
        
        let safeEmail = DataBaseManager.safeEmail(emailaddress: email)
        
        return Sender(photoUrl: "",
                      senderId: safeEmail,
                      displayName: "Sender Name")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
        // Do any additional setup after loading the view.
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        if let conversationId = id {
            print("\(conversationId)")
            listenForMessages(id:conversationId, shouldScrollToBottom: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        DataBaseManager.shared.getAllMessegesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting messages: \(messages)")
                guard !messages.isEmpty else {
                    print("messages are empty")
                    return
                }
                self?.messeges = messages
                
                DispatchQueue.main.async {
                    
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
                
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
}

extension ChatViewController : InputBarAccessoryViewDelegate{
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let theSender = self.mysender, let messageID = CreateMessageId() else {
                  print ("error ")
                  return
              }
        
        print("the message Id recieved in inputBar = \(messageID)")
        print(" sending: \(text)")
        let newMessage = Message(sender: theSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        // send messeges here
        guard let otherUserEmail = email else {
            return
        }
        if isNewConversation {
            //create conversation in database
            
            
            DataBaseManager.shared.createNewConversation(with: otherUserEmail,name: self.title ?? "user", firstMessage: newMessage) { [weak self] success in
                if success {
                    print("message sent to data base")
                    self?.isNewConversation = false
                    //
                    let newConversationId = "conversation_\(newMessage.messageId)"
                    self?.id = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = ""
                }
                else
                {
                    print("not Sent to database")
                }
            }
        }
        else {
            //  what we do for existing conversation
            guard let conversationId = id, let name = self.title else {
                return
            }
            DataBaseManager.shared.sendMessage(to: conversationId , otherUserEmail: otherUserEmail, name: name , newMessage: newMessage) {[weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = ""
                    print("message send in existing conversation with this user")
                }
                else{
                    print("failed to send to the user in existing messages")
                }
            }
        }
    }
    
    func CreateMessageId()-> String? {
        // we need date , otherUserEmail, senderEmail, random Ind, to generate MessageId
        
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, let otherUserEmail = email  else
        {
            // print ("no curreent Email in create Message ID")
            return nil
        }
        let safeCurrentEmail = DataBaseManager.safeEmail(emailaddress: currentUserEmail )
        let dateString = Self.dateFormatter.string(from: Date())      // used Self with Capital S because its static
        
        let newID = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        //  print("creadted message Id : \(newID)")
        return newID
    }
}

extension ChatViewController : MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate{
    func currentSender() -> SenderType {
        if let sender = mysender {
            return sender
        }
        fatalError("The sender should be Cashed")
        
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messeges[indexPath.section]
        
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messeges.count
    }
    
    
    
}

extension ChatViewController {
    private func validateAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil {
            // present login view controller
            let vc = storyboard?.instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            //navigationController?.pushViewController(nav, animated: true)
            present(nav, animated: false)// false // to make the delay between this page and the login page is less
            
        }
        
    }
}
