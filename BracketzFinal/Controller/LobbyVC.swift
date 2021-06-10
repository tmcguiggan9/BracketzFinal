//
//  LobbyVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/18/21.
//

import UIKit
import Firebase



class LobbyVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    

    var count = 1
    var presentUsers = Int()
    let currentUser = Auth.auth().currentUser?.uid
    var tournyUserIDs = [String]()
    var tournySize = Int()
    var waitingOn = Int()
    let tournyBuyIn = 1
    
    
    var matchesArray: [String]? {
        didSet {
            if matchesArray?.count == tournySize/2 {
                setMatch()
            }
        }
    }
    
    
    var users: [User]? {
        didSet {
            if users?.count == tournySize {
                if count == 1{
                    collectionView.reloadData()
                    configureUI()
                    observeTournament()
                }
            }
        }
    }
    
    
    var tourny: Tournament? {
        didSet {
            fetchUsers()
        }
    }
    
     
    private let collectionView: UICollectionView = {
        let viewLayout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: viewLayout)
        collectionView.backgroundColor = .white
        return collectionView
    }()
    
    
    var startingTournyLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    
    var waitingOnLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PlayerCollectionCell.self, forCellWithReuseIdentifier: "PlayerCollectionCell")
        
    }
    
    func observeTournament() {
        Service.shared.observePresentUsers(uid: tourny!.tournamentID) { (presentUsers) in
            self.waitingOnLabel.text = "waiting on \(self.tournySize - presentUsers) users"
            if presentUsers == self.tournySize {
                self.tourny?.acceptedUsers = self.tournySize
                self.collectionView.backgroundColor = .lightGray
                
                if self.currentUser == self.users![0].uid {
                    self.configureTournament()
                } else {
                    self.count += 1
                    self.observeMatches()
                    for x in 0..<self.users!.count {
                        self.tournyUserIDs.append(self.users![x].uid)
                    }
                }
            }
        }
    }
    
    
    func configureTournament() {
        if count == 1 {
            for x in 0..<users!.count {
                if x%2 == 0 {
                    var matchUsers = [User]()
                    var usernames = [String]()
                    matchUsers.append(users![x])
                    matchUsers.append(users![x+1])
                    usernames.append(users![x].uid)
                    usernames.append(users![x+1].uid)
                    tournyUserIDs.append(users![x].uid)
                    tournyUserIDs.append(users![x+1].uid)
                    
                    let values = ["users": usernames] as [String: Any]
                    REF_TOURNAMENTS.child(tourny!.tournamentID).child("matches").childByAutoId().updateChildValues(values)
                }
            }
            observeMatches()
            count += 1
        }
    }
    
    func setMatch() {
        let sortedMatches = matchesArray!.sorted()
        var matchIndex = Int()
        var myMatchId = String()
        var finalUsers = [User]()
        
        for x in 0..<tournyUserIDs.count {
            if x%2 == 0 {
                var matchUsers = [User]()
                matchUsers.append(users![x])
                matchUsers.append(users![x+1])
                
                if tournyUserIDs[x] == currentUser || tournyUserIDs[x+1] == currentUser {
                    matchIndex = x/2
                    finalUsers = matchUsers
                    myMatchId = sortedMatches[matchIndex]
                }
            }
            
        }
        
        waitingOnLabel.textColor = .green
        waitingOnLabel.text = "Pot: $\(tournyBuyIn)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.shouldPresentLoadingView(true, message: "Configuring round...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.shouldPresentLoadingView(false)
                let controller = MatchPlayVC(finalUsers, self.tourny!, myMatchId, self.tournySize)
                self.navigationController?.popToRootViewController(animated: true)
                self.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
    
    
    func observeMatches() {
        Service.shared.observeMatches(uid: tourny!.tournamentID) { (matches) in
            if matches.count == self.tournySize/2 {
                self.matchesArray = matches
            }
        }
    }
    
    
    func fetchUsers() {
        var array = [User]()
        for x in tourny!.tournamentUsers {
            Service.shared.fetchUserData(uid: x) { (user) in
                array.append(user)
                self.users = array
            }
        }
    }
    
    
    func configureUI() {
        configureNavigationBar(withTitle: "Lobby", prefersLargeTitles: false)
        
        view.addSubview(waitingOnLabel)
        waitingOnLabel.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingLeft: 8, paddingBottom: 20, paddingRight: 8)
        
        view.addSubview(collectionView)
        collectionView.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: waitingOnLabel.topAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 8, paddingRight: 8)
        
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users!.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerCollectionCell", for: indexPath) as! PlayerCollectionCell
        cell.user = users![indexPath.row]
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width - 50, height: 70)
        let estimatedSizeCell = PlayerCollectionCell(frame: frame)
        estimatedSizeCell.user = users![indexPath.row]
        estimatedSizeCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width - 50, height: 70)
        let estimatedSize = estimatedSizeCell.systemLayoutSizeFitting(targetSize)
        
        return .init(width: view.frame.width - 50, height: estimatedSize.height)
    }
}
