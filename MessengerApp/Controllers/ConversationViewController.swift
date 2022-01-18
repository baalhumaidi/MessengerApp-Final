//
//  ConversationViewController.swift
//  MessengerApp
//
//  Created by administrator on 03/01/2022.
//

import UIKit
import FirebaseAuth
import SDWebImage

import Firebase
import JGProgressHUD

struct Conversation{
    let id : String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}
struct LatestMessage{
    let date: String
    let text: String
    let isRead: Bool
}


class ConversationViewController: UIViewController {
    
    var conversations = [Conversation]()
    
    let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var ChatTableView: UITableView!
    
    // check to see if user is signed in using ... user defaults
    // they are, stay on the screen. If not, show the login screen
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDid Load")
        validateAuth()
        
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(SearchForOthers))
        ChatTableView.delegate = self
        ChatTableView.dataSource = self
    
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // validateAuth()
        let name = getuserData()
        title = "Conversation \(name)"
        print("ViewDid Appear")
        startListeningForConversations()
        
    }
    
    
    @objc func SearchForOthers(){
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "NewConversationViewController") as! NewConversationViewController
        vc.completion = {[weak self] result in
            
            
            print("\(result)")
            self?.createNewConversation(result: result)
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
        
    }
    func getuserData() -> String{
        guard let name = UserDefaults.standard.value(forKey: "name") as? String else {
            return " "
        }
        print("name in getdata func \(name)")
        return name
    }
    
    private func startListeningForConversations(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        print("the email is \(email)")
        print("Start fetch Conversations ...  ")
        let safeEmail = DataBaseManager.safeEmail(emailaddress: email)
        DataBaseManager.shared.getAllConversations(for: safeEmail) { [weak self] result in
            switch result {
            case .success(let conversations):
                print("succesfully fetch the conversations ")
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
                
                DispatchQueue.main.async {
                    self?.ChatTableView.reloadData()
                }
            case .failure(let error):
                print("failed to fetch all Conversations: \(error)")
            }
        }
    }
    
    func createNewConversation(result:[String:String]){
        
        guard let name = result["name"],
              let email = result["email"]
                //  let  email = DataBaseManager.safeEmail(emailaddress: result.email or result["email"])
        else
        {
            return
        }
        DataBaseManager.shared.conversationExists(iwth: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            // check in databae if conversation with these two users exists
            // if it does / reuse the conversation ID
            // otherwise create new conversation
            switch result {
            case .success(let conversationId):
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                vc.email = email
                vc.id = conversationId
                vc.isNewConversation = false
                vc.title = name
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                vc.email = email
                //        vc.conversationId = nil
                vc.isNewConversation = true
                vc.title = name
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
        
    }
    
    
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



extension ConversationViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ChatTableView.dequeueReusableCell(withIdentifier: "SingleCell", for: indexPath) as! ConversationTableViewCell
        cell.userImageView.contentMode = .scaleAspectFill
        cell.userImageView.layer.masksToBounds = true
        cell.userImageView.layer.cornerRadius = 30
        
        //
        let path = "images/\(conversations[indexPath.row].otherUserEmail)_ProfilePic.png"
        StorageManager.shared.downloadURL(for: path) { [weak self] result  in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    // here where we should set the image to the table view using third library or so
                    cell.userImageView.sd_setImage(with: url, completed: nil)
                    
                }
            case .failure(let error):
                cell.userImageView.image = UIImage(systemName: "person.circle")
                print("failed to get image")
            }
        }
        print(conversations)
        cell.userNameLabel.text = conversations[indexPath.row].name
        cell.userMessageLabel.text = conversations[indexPath.row].latestMessage.text
        
        return cell
    }
    
    // when user taps on a cell, we want to push the chat screen onto the stack
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        openConverstion(conversations[indexPath.row])
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    
    func openConverstion(_ conversations: Conversation){
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        vc.title = conversations.name
        vc.email = conversations.otherUserEmail
        vc.id = conversations.id
        
        // vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
}

