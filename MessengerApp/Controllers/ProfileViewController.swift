//
//  ProfileViewController.swift
//  MessengerApp
//
//  Created by administrator on 03/01/2022.
//

import UIKit
import Firebase
import FirebaseAuth




class ProfileViewController: UIViewController {
    
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var emailLabel: UILabel!
    // var data = [String]()
    let data = ["Log out"]
    @IBOutlet weak var myTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "profile "
        myTableView.dataSource = self
        myTableView.delegate = self
 
        // Do any additional setup after loading the view.
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                profileImage.isUserInteractionEnabled = true
                let gesture = UITapGestureRecognizer(target: self, action: #selector(ChangeProfilePic))
                profileImage.addGestureRecognizer(gesture)
        
        setupProfilePic()
        userInfo()
    
    }
        @objc func ChangeProfilePic(){
           choosingdifferentway()
        }
    
    func userInfo(){
        guard let name = UserDefaults.standard.value(forKey: "name") as? String, let email = UserDefaults.standard.value(forKey: "email") as? String
        else {return}
        nameLabel.text = String("Name: \(name)")
        emailLabel.text = String("Email: \(email)")
    }
    func saveNewProfile(){
        guard let image = profileImage.image,
              let data = image.pngData() else {
                  return
              }
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else
        {return}
        let safeEmail = DataBaseManager.safeEmail(emailaddress: email)
        let filename = "\(safeEmail)_ProfilePic.png"
        StorageManager.shared.uploadProfilePicture(with: data, fileName: filename, completion: { result in
            switch result {
            case .success(let downloadUrl):
                UserDefaults.standard.setValue(downloadUrl, forKey: "profile_picture_url")
                print(downloadUrl)
            case .failure(let error):
                print("Storage maanger error: \(error)")
            }
        })
    }
    
    func setupProfilePic(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String
        else {
            return
        }
        let safeEmail = DataBaseManager.safeEmail(emailaddress: email)
        let filename = safeEmail + "_ProfilePic.png"
        let path = "images/" + filename
        StorageManager.shared.downloadURL(for: path) { [weak self] result in
            switch result{
                
            case .success(let url):
                self?.DownloadImage(url: url)
            case .failure(let error):
                print("failed to get URL: \(error)")
            }
        }
    }
    
    func DownloadImage(url: URL){
        URLSession.shared.dataTask(with: url) { data, _ , error in
            guard let data = data, error == nil else {
                return
            }
            DispatchQueue.main.async {
                // self.profileImage.backgroundColor = .red
                self.profileImage.contentMode = .scaleAspectFill
                self.profileImage.layer.cornerRadius = self.profileImage.frame.size.width/2
                let image = UIImage(data:data)
                self.profileImage.image = image
            }
        }.resume()
    }
    
    
}
extension ProfileViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    
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
        profileImage.image = selectedImage
        saveNewProfile()
        
    }
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        
    }
}


extension ProfileViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = myTableView.dequeueReusableCell(withIdentifier: "SingleCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true) // unhighlight the cell
        // logout the user
        
        // show alert
        
        let actionSheet = UIAlertController(title: "", message: "", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [weak self] _ in
            // action that is fired once selected
            
            guard let strongSelf = self else {
                return
            }
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                // Remove Key-Value Pair
                UserDefaults.standard.removeObject(forKey: "email")
                // Remove Key-Value Pair
                UserDefaults.standard.removeObject(forKey: "name")
                // present login view controller
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: "LoginViewController")as! LoginViewController
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                
                //  strongSelf.navigationController?.present(nav, animated: true, completion: nil)
                strongSelf.tabBarController?.present(nav, animated: true, completion: nil)
            }
            catch {
                print("failed to logout")
            }
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
}




class MyTabBarController: UITabBarController{
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //   print(" we are in Tab bar ")
        self.selectedIndex = 0
    }
}
