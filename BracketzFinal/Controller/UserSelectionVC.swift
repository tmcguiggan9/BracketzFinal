//
//  UserSelection.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/14/21.
//


import Foundation
import UIKit
import Firebase



class UserSelectionVC: UIViewController, UISearchControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
  
    var tournySize: Int?
    var tournyUsers = [String]()
    var finalTournyUsers = [User]()
    
    private let tableView = UITableView()
    
    
    private var users: [User]? {
        didSet {
            if let index = users!.firstIndex(of: currentUser!) {
                users!.remove(at: index)
            }
            configureTableView()
            tableView.reloadData()
        }
    }
    
    private var currentUser: User? {
        didSet {
            fetchAllUsers()
            finalTournyUsers.append(currentUser!)
            configureSearchController()
            configureUI()
            tournyUsers.append(currentUser!.uid)
        }
    }
    
    private let searchController = UISearchController(searchResultsController: nil)
    private var inSearchMode: Bool {
        return searchController.isActive && !searchController.searchBar.text!.isEmpty
    }
    
    private let collectionView: UICollectionView = {
        let viewLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: viewLayout)
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    
    private let sendInviteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Invites", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        button.setTitleColor(.gray, for: .normal)
        button.setHeight(height: 50)
        button.isEnabled = false
        button.addTarget(self, action: #selector(sendInvites), for: .touchUpInside)
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.backgroundColor = #colorLiteral(red: 0.04823023291, green: 0.04672234866, blue: 0.1949952411, alpha: 1)
        button.setTitleColor(.white, for: .normal)
        button.setHeight(height: 50)
        button.isEnabled = true
        button.addTarget(self, action: #selector(cancelTournament), for: .touchUpInside)
        return button
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PlayerCollectionCell.self, forCellWithReuseIdentifier: "PlayerCollectionCell")
        fetchCurrentUser()
        navigationItem.setHidesBackButton(true, animated: false)
        
        
        searchController.delegate = self
        view.backgroundColor = #colorLiteral(red: 0.9254901961, green: 0.9411764706, blue: 0.9450980392, alpha: 1)
    }
    
    
    @objc func cancelTournament() {
        navigationController?.popViewController(animated: true)

    }
    
    
    @objc func sendInvites() {
        navigationItem.hidesBackButton = true
        sendInviteButton.isEnabled = false
        sendInviteButton.backgroundColor = .gray
        
        Service.shared.sendInvitesAndCreateTournament(tournyUsers: tournyUsers, tournySize: tournySize!, view: self)
    }
    
    func fetchAllUsers() {
        Service.shared.fetchUsers { (users) in
            self.users = users
        }
    }
    
    func fetchCurrentUser() {
        guard let currentUid = Auth.auth().currentUser?.uid else {return}
        Service.shared.fetchUserData(uid: currentUid) { (currentUser) in
            self.currentUser = currentUser
        }
    }
    
    
    func configureUI() {
        let stack2 = UIStackView(arrangedSubviews: [sendInviteButton, cancelButton])
        stack2.axis = .vertical
        stack2.spacing = 20
        view.addSubview(stack2)
        stack2.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingLeft: 20, paddingBottom: 20, paddingRight: 20)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: stack2.topAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8)
    }
    
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "User Cell")
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - 100
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        
        
        
        view.addSubview(tableView)
    }
    
    
    func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.showsCancelButton = true
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = false
        
        
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.searchBar.placeholder = "Add users..."
        navigationItem.searchController = searchController
        definesPresentationContext = true
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key(rawValue: NSAttributedString.Key.foregroundColor.rawValue): UIColor.white], for: .normal)
        
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = .systemPurple
            textField.backgroundColor = .white
        }
    }
    
    
    func presentSearchController(_ searchController: UISearchController) {
        tableView.frame.origin.y = 100
    }
    
    
    func didDismissSearchController(_ searchController: UISearchController) {
        tableView.frame.origin.y = view.frame.height
    }
    
    
    func updateUsers() {
        collectionView.reloadData()
        
        if finalTournyUsers.count == tournySize {
            sendInviteButton.isEnabled = true
            searchController.searchBar.isUserInteractionEnabled = false
            searchController.searchBar.placeholder = "Tournament is full"
            sendInviteButton.setTitleColor(.white, for: .normal)
        }

        configureUI()
        configureTableView()
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return finalTournyUsers.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerCollectionCell", for: indexPath) as! PlayerCollectionCell
        cell.user = finalTournyUsers[indexPath.row]
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width - 50, height: 70)
        let estimatedSizeCell = PlayerCollectionCell(frame: frame)
        estimatedSizeCell.user = finalTournyUsers[indexPath.row]
        estimatedSizeCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width - 50, height: 70)
        let estimatedSize = estimatedSizeCell.systemLayoutSizeFitting(targetSize)
        
        return .init(width: view.frame.width - 50, height: estimatedSize.height)
    }
    
    
}

extension UserSelectionVC: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        //       guard let searchText = searchController.searchBar.text else { return }
    }
}



extension UserSelectionVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "User Cell", for: indexPath)
        cell.textLabel?.text = users![indexPath.row].username
        if users![indexPath.row].username == currentUser?.username {
            cell.isHidden = true
        }
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tournyUsers.append(users![indexPath.row].uid)
        finalTournyUsers.append(users![indexPath.row])
        users?.remove(at: indexPath.row)
        updateUsers()
        searchController.isActive = false
        
    }
}
