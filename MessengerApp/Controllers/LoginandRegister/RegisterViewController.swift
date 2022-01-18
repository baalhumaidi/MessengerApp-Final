//
//  RegisterViewController.swift
//  MessengerApp
//
//  Created by administrator on 03/01/2022.
//

import UIKit
import SwiftUI
import FirebaseAuth
import JGProgressHUD
class RegisterViewController: UIViewController {
    let spinner = JGProgressHUD(style: .light)
    
    @IBOutlet weak var profilePic: UIImageView!
    
    @IBOutlet weak var firstName: UITextField!
    
    @IBOutlet weak var lastName: UITextField!
    
    @IBOutlet weak var emailField: UITextField!
    
    @IBOutlet weak var passwordField: UITextField!
    
    
    //MARK: Register Process
    
    
    @IBAction func RegiserButton(_ sender: UIButton) {
        firstName.resignFirstResponder()
        lastName.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let Fname = firstName.text, let Lname = lastName.text, let email = emailField.text?.lowercased(), let password = passwordField.text,
              !Fname.isEmpty,!Lname.isEmpty,
              !email.isEmpty, !password.isEmpty,
              password.count >= 6
        else{
            alertErrorLogin("error","Please enter all information and password should be equal or more than 6 characters to create a new account")
            return
        }
        spinner.show(in: view)
        DataBaseManager.shared.userExists(with: email) { [weak self] exists  in
            guard let strongself = self else {return}
            DispatchQueue.main.async {
                
                strongself.spinner.dismiss(animated: true)
                
            }
            guard !exists else {
                strongself.alertErrorLogin("error", "The email Address is already exist")
                print("user Already Exist")
                return
            }
            // firebase auth and to create new account
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] AuthResult , Error in
                guard let strongSelf = self else { return}
                guard let result = AuthResult, Error == nil else {
                    strongself.alertErrorLogin("error", "error creating user \(String(describing: Error))")
                    print ("error creating user\(String(describing: Error))")
                    return }
                
                let userdata = userData(firstname: Fname, lastname: Lname, emailaddress: email)
                DataBaseManager.shared.insertUser(with:userdata ) { sucess in
                    if sucess {
                        
                        guard let image = strongSelf.profilePic.image,
                              let data = image.pngData() else {
                                  return
                              }
                        let filename = userdata.profilePicfilename
                        StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
                            switch result {
                            case .success(let downloadUrl):
                                UserDefaults.standard.setValue(downloadUrl, forKey: "profile_picture_url")
                                print(downloadUrl)
                            case .failure(let error):
                                print("Storage maanger error: \(error)")
                            }
                        })
                        
                        print("success in inserting user ")
                    }
                    else {
                        print("failed to inset user ")
                    }
                }
                UserDefaults.standard.setValue("\(Fname) \(Lname)", forKey: "name")
                UserDefaults.standard.setValue(email, forKey: "email")
                strongself.navigationController?.dismiss(animated: true, completion:  nil)
                
                //   strongself.navigationController?.popViewController(animated: false )
            }
        }
    }
    
    func  alertErrorLogin(_ title: String,_ Msesage: String){
        let alert = UIAlertController (title: title, message: Msesage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
        present(alert, animated: true)
    }
    
    // MARK: viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Account"
        // Do any additional setup after loading the view.
        profilePic.isUserInteractionEnabled = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(ChangeProfilePic))
        profilePic.addGestureRecognizer(gesture)
    }
    override func viewDidLayoutSubviews() {
        profilePic.layer.masksToBounds = true
        profilePic.layer.borderWidth = 2
        profilePic.layer.borderColor = UIColor.gray.cgColor
        profilePic.layer.cornerRadius = profilePic.frame.size.width/2 // to make the profile pic circular
        profilePic.contentMode = .scaleAspectFill
    }
    

    @objc func ChangeProfilePic(){
        choosingdifferentway()
    }
    
}


//MARK: Picking the profile Picture
extension RegisterViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    func choosingdifferentway(){
        let ActionSheet = UIAlertController (title: "Profile Picture", message: "How would you Like to select profile Picture", preferredStyle: .actionSheet)
        ActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        ActionSheet.addAction(UIAlertAction(title: "Take Photo ", style: .default, handler: {[weak self] _ in
            self?.presentCamera()   }   ))
        ActionSheet.addAction(UIAlertAction(title: "Choose Photo", style: .default, handler: {  [weak self] _ in
            self?.presentPhotoPicker() }  ))
        present(ActionSheet, animated: true, completion: nil)
    }
    
    func presentCamera(){
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
        
    }
    
    func presentPhotoPicker(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc,animated: true)
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage
        else {return}
        profilePic.image = selectedImage
        
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
}
