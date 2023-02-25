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
    var currentUser: User
    var tournySize: Int
    var tourny: Tournament
    var presentUsers = Int()
    var waitingOn = Int()
    let isPublic = false
    
    
    init(currentUser: User, tournySize: Int, tourny: Tournament) {
        self.currentUser = currentUser
        self.tournySize = tournySize
        self.tourny = tourny
        super.init(nibName: nil, bundle: nil)
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
        presenter = LobbyPresenter(self, currentUser: currentUser, tournySize: tournySize, tourny: tourny)
        
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
