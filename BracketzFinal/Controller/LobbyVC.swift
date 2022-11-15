//
//  LobbyVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/18/21.
//

import UIKit
import Firebase



class LobbyVC: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    var presenter: LobbyPresenter?


    var presentUsers = Int()
    
    var waitingOn = Int()
    let isPublic = false
    
    
    init(currentUser: User, tournySize: Int, tourny: Tournament) {
        super.init(nibName: nil, bundle: nil)
        presenter = LobbyPresenter(self, currentUser: currentUser, tournySize: tournySize, tourny: tourny)
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
    
    func reloadData() {
        collectionView.reloadData()
    }
    
    func dimBackground() {
        collectionView.backgroundColor = .lightGray
    }
    
    func observeTournament() {
        presenter?.observeTournament()
    }
    
    func checkIfCurrentUserIsHost() {
        presenter?.checkIfCurrentUserIsHost()
    }
    
    
    func configureTournament() {
        if presenter!.count == 1 {
            for x in 0..<presenter!.users!.count {
                if x%2 == 0 {
                    var matchUsers = [User]()
                    var usernames = [String]()
                    matchUsers.append(presenter!.users![x])
                    matchUsers.append(presenter!.users![x+1])
                    usernames.append(presenter!.users![x].uid)
                    usernames.append(presenter!.users![x+1].uid)
                    presenter!.tournyUserIDs.append(presenter!.users![x].uid)
                    presenter!.tournyUserIDs.append(presenter!.users![x+1].uid)
                    
                    let values = ["users": usernames] as [String: Any]
                    REF_TOURNAMENTS.child(presenter!.tourny!.tournamentID).child("matches").childByAutoId().updateChildValues(values)
                }
            }
            observeMatches()
            presenter!.count += 1
        }
    }
    
    func setMatch() {
    }
    
    
    func observeMatches() {
        Service.shared.observeMatches(uid: presenter!.tourny!.tournamentID) { (matches) in
            if matches.count == self.presenter!.tournySize/2 {
                self.presenter!.matchesArray = matches
            }
        }
    }
    
    
    func fetchUsers() {
        var array = [User]()
        for x in presenter!.tourny!.tournamentUsers {
            Service.shared.fetchUserData(uid: x) { (user) in
                array.append(user)
                self.presenter!.users = array
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
        return presenter!.users!.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PlayerCollectionCell", for: indexPath) as! PlayerCollectionCell
        cell.user = presenter!.users![indexPath.row]
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .init(top: 16, left: 0, bottom: 16, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let frame = CGRect(x: 0, y: 0, width: view.frame.width - 50, height: 70)
        let estimatedSizeCell = PlayerCollectionCell(frame: frame)
        estimatedSizeCell.user = presenter!.users![indexPath.row]
        estimatedSizeCell.layoutIfNeeded()
        
        let targetSize = CGSize(width: view.frame.width - 50, height: 70)
        let estimatedSize = estimatedSizeCell.systemLayoutSizeFitting(targetSize)
        
        return .init(width: view.frame.width - 50, height: estimatedSize.height)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
