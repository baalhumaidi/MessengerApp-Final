//
//  NewConversationViewController.swift
//  MessengerApp
//
//  Created by administrator on 03/01/2022.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: (([String: String]) -> Void)?
    
    let spinner = JGProgressHUD(style: .extraLight)
    private var users = [[String: String]]()
    private var results = [[String: String]]()
    private var hasFetched = false //
    
    
    @IBOutlet weak var labelForResult: UILabel!
    
    @IBOutlet weak var theSearchBar: UISearchBar!
    
    @IBOutlet weak var SearchTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SearchTableView.delegate = self
        SearchTableView.dataSource = self
        
        
        theSearchBar.delegate = self
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(DismissSelf))
        theSearchBar.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    @objc func DismissSelf(){
        dismiss(animated: true, completion: nil)
    }
    
    
}

extension NewConversationViewController: UISearchBarDelegate{
    //**** it will print error with every backspace because its text did change func
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            print("error")
            return
        }
        print("should start search")
        searchBar.resignFirstResponder()
        results.removeAll()
        spinner.show(in: view)
        self.searchforUsers(query: text)
        
    }

    
    
    func searchforUsers(query:String)
    {// check if array has firebase results
        if hasFetched {
            // if it does: filter
            filterUsers(with: query)
        }
        else{   // if not, fetch then filter
            DataBaseManager.shared.getAllUsers { [weak self] result in
                switch result {
                case .success(let usersCollection):
                    self?.hasFetched = true
                    self?.users = usersCollection
                    print(self?.users)
                    self?.filterUsers(with: query)
                case .failure(let error):
                    print("failed to find users \(error)")
                }
            }
            
        }
        
        
    }
    
    func filterUsers(with term: String){
        //update the UI  either show result or no result
        guard hasFetched else {
            return
        }
        spinner.dismiss(animated: true)
        results  = self.users.filter({
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        UpdateUI()
        
    }
    
    func UpdateUI(){
        
        if results.isEmpty{
            self.labelForResult.isHidden = false
            self.SearchTableView.isHidden = true
            labelForResult.text = ("No Result Found")
        }
        else {
            self.labelForResult.isHidden = true
            self.SearchTableView.isHidden = false
            self.SearchTableView.reloadData()
        }
    }
    
}


//Mark: TableView datasource and delegate
extension NewConversationViewController: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SearchTableView.dequeueReusableCell(withIdentifier: "SingleCell", for: indexPath)
        cell.textLabel?.text = results[indexPath.row]["name"]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        SearchTableView.deselectRow(at: indexPath, animated: true)
        //Start Conversation
        
        let targetUserData = results[indexPath.row]
        dismiss(animated: true, completion: {[weak self] in
            self?.completion?(targetUserData)
        }
        )}
    
}
