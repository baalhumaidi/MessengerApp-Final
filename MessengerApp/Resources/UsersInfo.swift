//
//  UsersInfo.swift
//  MessengerApp
//
//  Created by administrator on 03/01/2022.
//

import Foundation
import Firebase

import FirebaseCore

// final so this class cant be inheritied
class DataBaseManager{
    
    static let shared = DataBaseManager()
    //MARK:  the database reference doesnt work
    
    //  var ref: DatabaseReference!
    var database = Database.database().reference()
    
    static func  safeEmail(emailaddress: String)-> String {
        var safeEmail = emailaddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}


struct userData{
    let firstname : String
    let lastname : String
    let emailaddress : String
    // let profilepic : binary? or String? or URL ?
    var safeEmail :String {
        var safeEmail = emailaddress.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePicfilename: String {
        return "\(safeEmail)_ProfilePic.png"
    }
}


// MARK: - account management
extension DataBaseManager {
    
    // have a completion handler because the function to get data out of the database is asynchrounous so we need a completion block
    
    public func userExists(with email:String, completion: @escaping ((Bool) -> Void)) {
        // will return true if the user email does not exist
        
        // firebase allows you to observe value changes on any entry in your NoSQL database by specifying the child you want to observe for, and what type of observation you want
        // let's observe a single event (query the database once)
        
        var safeEmail = DataBaseManager.safeEmail(emailaddress: email)
        
        //
        database.child(safeEmail).observeSingleEvent(of: .value) { snapshot in
            
            // snapshot has a value property that can be optional if it doesn't exist
            // to check if the e-mail is excited in database
            guard snapshot.value as? [String: Any] != nil else {
                // otherwise... let's create the account
                completion(false)
                return
            }
            // if we are able to do this, that means the email exists already!
            
            completion(true) // the caller knows the email exists already
        }
    }
    //completion: @escaping (Bool) -> Void)
    public func insertUser(with user: userData,completion: @escaping (Bool) -> Void){
        // pass data as a dictionary
        database.child(user.safeEmail).setValue(["firstname": user.firstname,
                                                 "lastname": user.lastname]) { error, _ in
            guard error == nil else {
                print("failed to insert user Info")
                completion(false)
                return}
            self.database.child("users").observeSingleEvent(of: .value) { snapshot in
                // snapshot is not the value itself
                
                if var usersCollection = snapshot.value as? [[String: String]] {
                    // if var so we can make it mutable so we can append more contents into the array, and update it
                    
                    // append to user dictionary
                    let newElement = [
                        "name": user.firstname + " " + user.lastname,
                        "email": user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    
                    self.database.child("users").setValue(usersCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                        
                    }}
                else{
                    // create that array
                    let newCollection: [[String: String]] = [
                        [
                            "name": user.firstname + " " + user.lastname,
                            "email": user.safeEmail
                        ]
                    ]
                    self.database.child("users").setValue(newCollection) { error, _ in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>) -> Void){
        
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String: String]] else {
                print("cant fetch data ")
                completion(.failure(DatabaseError.failedToFetch))
                
                return
            }
            print("sucess in fetching")
            completion(.success(value))
        }
    }
    
    public func getDataFor(path: String, completion: @escaping (Result<Any, Error>) -> Void) {
        database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error {
        case failedToFetch
    }
    
}

//Mark: Sending messages / conversations
extension DataBaseManager{
    //Create a new coversation with new user and first message sent
    public func createNewConversation( with otherUserEmail: String,name: String, firstMessage: Message,completion: @escaping (Bool)->Void){
        //1. put conversation in the user's conversation collection, and then
        //2. once we create that new entry, create the root convo with all the messages in it
        
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String
                ,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String
                
        else {
            return
        }
        let safeEmail = DataBaseManager.safeEmail(emailaddress: currentEmail) // cant have certain characters as keys
        
        // find the conversation collection for the given user (might not exist if user doesn't have any convos yet)
        
        let ref = database.child("\(safeEmail)")
        // use a ref so we can write to this as well
        
        ref.observeSingleEvent(of: .value) { [weak self] snapshot in
            // what we care about is the conversation for this user
            guard var userNode = snapshot.value as? [String: Any] else {  // error // user not found??
                // we should have a user
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationId = "conversation_\(firstMessage.messageId)"
            
            let newConversationData: [String:Any] = [
                //      "id": conversationId,
                "id" : conversationId,
                "other_user_email": otherUserEmail,
                "name": name,   // sender name
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    
                ],
                
            ]
            
            let recipient_newConversationData: [String:Any] = [
                "id": conversationId,
                "other_user_email": safeEmail,
                "name": currentName,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false,
                    
                ],
                
            ]
            
            // update recipient conversation entry
            
            
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self] snapshot in
                if var conversations = snapshot.value as? [[String: Any]] {
                    // append
                    conversations.append(recipient_newConversationData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }else {
                    // reciepient user doesn't have any conversations, we create them
                    // create
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationData])
                }
            }
            // update current user conversation entry
            
            if var conversations = userNode["conversations"] as? [[String: Any]] {
                // conversation array exists for current user, you should append
                
                // points to an array of a dictionary with quite a few keys and values
                // if we have this conversations pointer, we would like to append to it
                
                conversations.append(newConversationData)
                
                userNode["conversations"] = conversations // we appended a new one
                
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                    
                }
            }else {
                // create this conversation
                // conversation array doesn't exist
                
                userNode["conversations"] = [
                    newConversationData
                ]
                
                ref.setValue(userNode) { [weak self] error, _ in
                    guard error == nil else {
                        completion(false)
                        return
                    }
                    //  completion(true)
                    self?.finishCreatingConversation(name: name,
                                                     conversationID: conversationId,
                                                     firstMessage: firstMessage,
                                                     completion: completion)
                }
            }
        }
    }
    
    
    
    private func finishCreatingConversation(name: String, conversationID:String, firstMessage: Message, completion: @escaping (Bool) -> Void){
        //        {
        //            "id": String,
        //            "type": text, photo, video
        //            "content": String,
        //            "date": Date(),
        //            "sender_email": String,
        //            "isRead": true/false,
        //        }
        
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DataBaseManager.safeEmail(emailaddress: myEmail)
        
        let collectionMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false,
            "name": name,
        ]
        
        let value: [String:Any] = [
            "messages": [
                collectionMessage
            ]
        ]
        
        print("adding convo: \(conversationID)")
        
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else {
                completion(false)
                return
            }
            completion(true)
        }
        
    }
    //return all conversations with a specific email
    public func getAllConversations(for email: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        database.child("\(email)/conversations").observe(.value) { snapshot in
            // new conversation created? we get a completion handler called
            guard let value = snapshot.value as? [[String:Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap { dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                          return nil
                      }
                
                // create model
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            
            completion(.success(conversations))
            
        }
    }
    
    
    
    // get all messages for a given conversation
    public func getAllMessegesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        print(id)// doesnt work? may be the ID?
        database.child("\(id)/messages").observe(.value) { snapshot in   // its not getting the first messsage?
            // new conversation created? we get a completion handler called
            guard let value = snapshot.value as? [[String:Any]] else {
                print(snapshot.value)
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from: dateString)
                else {
                    return nil
                }
                
                let sender = Sender(photoUrl: "", senderId: senderEmail, displayName: name)
                
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
                
            }
            
            completion(.success(messages))
            
        }
    }
    
    
    
    // send a message with targetconversation
    public func sendMessage(to conversation: String,otherUserEmail: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        // return bool if successful
        
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        
        
        
        self.database.child("\(conversation)/messages").observeSingleEvent(of: .value) { [weak self] snapshot in
            
            guard let strongSelf = self else {
                return
            }
            
            guard var currentMessages = snapshot.value as? [[String: Any]] else {
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else {
                completion(false)
                return
            }
            
            let currentUserEmail = DataBaseManager.safeEmail(emailaddress: myEmail)
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name,
            ]
            
            currentMessages.append(newMessageEntry)
            
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error == nil else {
                    
                    completion(false)
                    return
                }
                completion(true)
                
                strongSelf.database.child("\(currentUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                    guard var currentUserConversations = snapshot.value as? [[String: Any]] else {
                        completion(false)
                        return
                    }
                    let updatedValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    
                    var targetConversation: [String: Any]?
                    var position = 0
                    for conversationDictionary in currentUserConversations {
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation { //
                            targetConversation = conversationDictionary
                            break
                        }
                        position += 1
                    }
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalconversation = targetConversation else {
                        return
                    }
                    currentUserConversations[position] = finalconversation
                    strongSelf.database.child("\(currentUserEmail)/conversations").setValue(currentUserConversations) { error, _  in
                        guard error == nil else {
                            return
                        }
                        
                        // update latest message for reciepient user
                        strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
                            guard var otherUserConversations = snapshot.value as? [[String: Any]] else {
                                completion(false)
                                return
                            }
                            let updatedValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]
                            
                            
                            var targetConversation: [String: Any]?
                            var position = 0
                            for conversationDictionary in otherUserConversations {
                                if let currentId = conversationDictionary["id"] as? String, currentId == conversation { //
                                    targetConversation = conversationDictionary
                                    break
                                }
                                position += 1
                            }
                            targetConversation?["latest_message"] = updatedValue
                            guard let finalconversation = targetConversation else {
                                return
                            }
                            otherUserConversations[position]=(finalconversation)
                            strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _  in
                                guard error == nil else {
                                    return
                                }
                                
                                // update latest message for reciepient user
                                completion(true)
                            }
                        })
                    }
                })
            }
        }
    }
    
    public func conversationExists(iwth targetRecipientEmail: String, completion: @escaping (Result<String, Error>) -> Void) {
        let safeRecipientEmail = DataBaseManager.safeEmail(emailaddress: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DataBaseManager.safeEmail(emailaddress: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value, with: { snapshot in
            guard let collection = snapshot.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            // iterate and find conversation with target sender
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
            }) {
                // get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                print("----- \(id)")
                completion(.success(id))
                return
            }
            
            completion(.failure(DatabaseError.failedToFetch))
            return
        })
    }
    
}




// above
// when user tries to start a convo, we can pull all these users with one request
/*
 users => [
 [
 "name":
 "safe_email":
 ],
 [
 "name":
 "safe_email":
 ],
 ]
 */
// try to get a reference to an existing user's array
// if doesn't exist, create it, if it does, append to it
