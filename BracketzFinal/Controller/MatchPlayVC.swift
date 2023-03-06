//
//  GamePlayVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/24/21.
//

import UIKit
import Firebase

class MatchPlayVC: UIViewController {
    
    var presenter: MatchPlayPresenter?
    let currentUser: User
    private var tourny: Tournament?
    var opponentMoveText: String = ""
    var myMoveText: String = ""
    var loser = String()
    
    let rockButton: MoveButton = {
        let button = MoveButton(image: #imageLiteral(resourceName: "FIST"), move: "rock")
        button.addTarget(self, action: #selector(moveSelected(_:)), for: .touchUpInside)
        return button
    }()
    
    let paperButton: MoveButton = {
        let button = MoveButton(image: #imageLiteral(resourceName: "Paper2x"), move: "paper")
        button.addTarget(self, action: #selector(moveSelected(_:)), for: .touchUpInside)
        return button
    }()
    
    let scissorsButton: MoveButton = {
        let button = MoveButton(image: #imageLiteral(resourceName: "Scissors"), move: "scissors")
        button.addTarget(self, action: #selector(moveSelected(_:)), for: .touchUpInside)
        return button
    }()
    
    let opponentMove: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    let myMove: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    let rpsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    let opponentNameLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    let timerLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = .green
        label.textAlignment = .center
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        Service.shared.removeObserver(uid: self.tourny!.tournamentID)
        REF_TOURNAMENTS.child(tourny!.tournamentID).child("matches").removeAllObservers()
        if currentUser.uid == tourny!.tournamentUsers[0] {
            REF_TOURNAMENTS.child(tourny!.tournamentID).updateChildValues(["acceptedUsers": 0])
        }
        presenter!.observeOpponentMove()
        startMatch()
    }
    
    init(_ users: [User],_ tourny: Tournament,_ matchID: String,_ tournySize: Int,_ currentUser: User) {
        self.tourny = tourny
        self.currentUser = currentUser
        super.init(nibName: nil, bundle: nil)
        presenter = MatchPlayPresenter(self, tournySize: tournySize, users: users, tourny: tourny, currentUser: currentUser, matchID: matchID)
        configureOpponentLabel()
    }
    
    func configureOpponentLabel() {
        if let users = presenter!.users {
            if currentUser.uid == presenter!.user1 {
                opponentNameLabel.text = "Opponent: \(users[1].username)"
            } else {
                opponentNameLabel.text = "Opponent: \(users[0].username)"
            }
        }
        configureUI()
    }
    
    func configureUI() {
        let stack2 = UIStackView(arrangedSubviews: [rockButton, paperButton, scissorsButton])
        stack2.axis = .horizontal
        stack2.distribution = .fillEqually
        view.addSubview(stack2)
        stack2.anchor(left: view.leftAnchor, bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, height: 100)
        
        view.addSubview(opponentNameLabel)
        opponentNameLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(opponentMove)
        opponentMove.anchor(top: opponentNameLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 20, paddingLeft: 8, paddingRight: 8)
        
        view.addSubview(myMove)
        myMove.anchor(left: view.leftAnchor, bottom: stack2.topAnchor, right: view.rightAnchor, paddingLeft: 8, paddingBottom: 8, paddingRight: 8)
        
        view.addSubview(rpsLabel)
        rpsLabel.centerX(inView: view)
        rpsLabel.centerY(inView: view)
        
        view.addSubview(timerLabel)
        timerLabel.anchor(top: rpsLabel.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 8, paddingLeft: 8, paddingRight: 8)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startMatch() {
        rpsLabel.text = "SELECT YOUR MOVE"
        presenter!.startMatch()
    }
    
    @objc func moveSelected(_ sender: UIButton) {
        myMoveText = sender.currentTitle!
        print(sender.currentTitle!)
        rockButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        paperButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        scissorsButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        rockButton.backgroundColor = .white
        paperButton.backgroundColor = .white
        scissorsButton.backgroundColor = .white
        sender.backgroundColor = #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1)
        sender.setTitleColor(#colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1), for: .normal)
        if let currentTitle = sender.currentTitle {
            presenter!.updateUserMoves(currentTitle: currentTitle)
        }
    }
}
