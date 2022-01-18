//
//  ViewController.swift
//  MessengerApp
//
//  Created by administrator on 03/01/2022.
//

import UIKit
import FirebaseAuth
import Firebase
import JGProgressHUD

class LoginViewController: UIViewController {
    
    
    let spinner = JGProgressHUD(style: .light)
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    //MARK: Login Process
    @IBAction func LoginButtonPressed(_ sender: Any) {
        guard let email = emailField.text?.lowercased(), let password = passwordField.text,
              !email.isEmpty, !password.isEmpty,
              password.count >= 6
        else{
            alertErrorLogin("error","Please enter the email address and password and password should be equal or more than 6 characters")
            return
        }
        spinner.show(in: view)
        // MARK: firebase auth and login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] AuthResult , Error in
            guard let strongself = self else{return }
            DispatchQueue.main.async {
                strongself.spinner.dismiss()
            }
            guard let result = AuthResult, Error == nil else {
                strongself.alertErrorLogin("error", "there is an error in logging in")
                print ("error Logging In user")
                
                return }
            let user = result.user
            let safeEmail = DataBaseManager.safeEmail(emailaddress: email)
            DataBaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userInfo = data as? [String: Any],
                          let firstName = userInfo["firstname"] as? String,
                          let lastName = userInfo["lastname"] as? String else{
                              return
                          }
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("failed to read data with error \(error)")
                }
            }
            UserDefaults.standard.setValue(email, forKey: "email") // save the user's email
            
            DispatchQueue.main.async {
                
                //self.alertErrorLogin("congratulations", "Logged In")
                print("Logged in \(user)")
                // not dismissing the page?
                
                strongself.dismiss(animated: true, completion:  nil)
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Log In"
        // emailField.delegate = self
        //  passwordField.delegate = self
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(Registernewaccount))
    }
    
    
    @objc private func Registernewaccount(){
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        navigationController?.pushViewController(vc, animated: true)
    }
    
}


extension LoginViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField{
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            LoginButtonPressed(Any?.self)
            //            LoginButton(Any?.self)
        }
        
        return true
    }
}

extension LoginViewController {
    //Alert function
    func  alertErrorLogin(_ title: String,_ Msesage: String){
        let alert = UIAlertController (title: title, message: Msesage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
        
    }
}
