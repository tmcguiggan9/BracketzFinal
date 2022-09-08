//
//  GamePlayVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/24/21.
//

import UIKit
import Firebase

class MatchPlayVC: UIViewController {
    
    var tournySize = Int()
    var user1 = String()
    var user2 = String()
    var user1Move: String = ""
    var user2Move: String = ""
    let currentUser = Auth.auth().currentUser?.uid
    private var users: [User]?
    private var tourny: Tournament?
    private var matchID: String?
    var timer = Timer()
    var timerCount = 10
    var opponentMoveText: String = ""
    var myMoveText: String = ""
    var didWin = false
    var didTie = false
    var didLose = false
    var loser = String()
    
    
    
    private let rockButton: MoveButton = {
        let button = MoveButton(image: #imageLiteral(resourceName: "FIST"), move: "rock")
        button.addTarget(self, action: #selector(moveSelected(_:)), for: .touchUpInside)
        return button
    }()
    
    
    private let paperButton: MoveButton = {
        let button = MoveButton(image: #imageLiteral(resourceName: "Paper2x"), move: "paper")
        button.addTarget(self, action: #selector(moveSelected(_:)), for: .touchUpInside)
        return button
    }()
    
    
    private let scissorsButton: MoveButton = {
        let button = MoveButton(image: #imageLiteral(resourceName: "Scissors"), move: "scissors")
        button.addTarget(self, action: #selector(moveSelected(_:)), for: .touchUpInside)
        return button
    }()
    
    
    private let opponentMove: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    
    private let myMove: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    
    private let rpsLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    
    private let timerLabel: UILabel = {
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
        if currentUser == tourny?.tournamentUsers[0] {
            REF_TOURNAMENTS.child(tourny!.tournamentID).updateChildValues(["acceptedUsers": 0])
        }
        observeOpponentMove()
        startMatch()
    }
    
    
    init(_ users: [User],_ tourny: Tournament,_ matchID: String,_ tournySize: Int) {
        self.users = users
        self.tournySize = tournySize
        self.tourny = tourny
        self.matchID = matchID
        user1 = users[0].uid
        user2 = users[1].uid
        
        super.init(nibName: nil, bundle: nil)
        
        let opponentNameLabel: UILabel = {
            let label = UILabel()
            label.text = ""
            label.font = UIFont.boldSystemFont(ofSize: 20)
            label.textColor = .black
            label.textAlignment = .center
            return label
        }()
        
        if currentUser == user1 {
            opponentNameLabel.text = "Opponent: \(users[1].username)"
        } else {
            opponentNameLabel.text = "Opponent: \(users[0].username)"
        }
        
        
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
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    
    @objc func timerAction(){
        timerLabel.text = String(timerCount)
        timerCount -= 1
     
        
        if timerCount <= 2 {
            timerLabel.textColor = .red
        }
        
        if timerCount == -1 {
            rockButton.isEnabled = false
            paperButton.isEnabled = false
            scissorsButton.isEnabled = false
            timerLabel.isHidden = true
        }
        
        if timerCount == -2 {
            rpsLabel.text = "ROCK"
        }
        
        if timerCount == -3 {
            rpsLabel.text = "PAPER"
        }
        
        if timerCount == -4 {
            rpsLabel.text = "SCISSORS"
        }
        
        if timerCount == -5 {
            rpsLabel.text = "SHOOT!"
            opponentMove.text = opponentMoveText
            myMove.text = myMoveText
        }
        
        if timerCount == -7 {
            timer.invalidate()
            checkWinLogic()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.didWin {
                        self.observeTournament()
                } else if self.didLose {
                    
                    REF_TOURNAMENTS.child(self.tourny!.tournamentID).child("matches").child(self.matchID!).removeValue()
                    
                    REF_TOURNAMENTS.child(self.tourny!.tournamentID).child("tournamentUsers").runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                        var value = currentData.value as? [String]
                        
                        if value == nil {
                            value = []
                        }
                        
                        if let index = value?.firstIndex(of: self.currentUser!) {
                            value?.remove(at: index)
                        }
                        currentData.value = value
                        return TransactionResult.success(withValue: currentData)
                    }
                    
                    
                    REF_USERS.child(self.currentUser!).child("unresolvedTournaments").observeSingleEvent(of: .value) { (snapshot) in
                        guard var invites = snapshot.value as? [String] else { return }
                        if let index = invites.firstIndex(of: self.tourny!.tournamentID) {
                            invites.remove(at: index)
                        }
                        REF_USERS.child(self.currentUser!).updateChildValues(["unresolvedTournaments": invites])
                    }
    
                    let controller = LoserVC()
                    self.navigationController?.pushViewController(controller, animated: true)
                } else if self.didTie {
                    self.didTie = false
                    self.timerCount = 10
                    self.timerLabel.text = "10"
                    self.timerLabel.textColor = .green
                    self.myMove.text = ""
                    self.opponentMove.text = ""
                    self.rockButton.isEnabled = true
                    self.paperButton.isEnabled = true
                    self.scissorsButton.isEnabled = true
                    self.rockButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
                    self.paperButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
                    self.scissorsButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
                    self.rockButton.backgroundColor = .white
                    self.paperButton.backgroundColor = .white
                    self.scissorsButton.backgroundColor = .white
                    self.timerLabel.isHidden = false
                    self.startMatch()
                }
            }
        }
    }
    
    func observeTournament() {
        let newTournySize = tournySize/2
        
        if newTournySize == 1 {
            
            REF_TOURNAMENTS.child(self.tourny!.tournamentID).removeValue()
            REF_USERS.child(self.currentUser!).child("unresolvedTournaments").observeSingleEvent(of: .value) { (snapshot) in
                guard var invites = snapshot.value as? [String] else { return }
                if let index = invites.firstIndex(of: self.tourny!.tournamentID) {
                    invites.remove(at: index)
                }
                REF_USERS.child(self.currentUser!).updateChildValues(["unresolvedTournaments": invites])
            }
            let controller = WinnerVC()
            navigationController?.pushViewController(controller, animated: true)
            
        } else {
            self.shouldPresentLoadingView(true, message: "Waiting for other matches to end...")
            REF_TOURNAMENTS.child(self.tourny!.tournamentID).child("acceptedUsers").runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                var value = currentData.value as? Int
                
                if value == nil {
                    value = 0
                }
                
                currentData.value = value! + 1
                return TransactionResult.success(withValue: currentData)
            }
            
            REF_TOURNAMENTS.child(tourny!.tournamentID).child("tournamentUsers").observe(.value) { (snapshot) in
                guard let users = snapshot.value as? [String] else { return }
                
                if users.count == newTournySize {
                    self.shouldPresentLoadingView(false)
                    let controller = LobbyVC()
                    controller.tourny = Tournament(self.tourny!.tournamentID, tournamentUsers: users, false)
                    controller.tournySize = newTournySize
                    self.navigationController?.popToRootViewController(animated: true)
                    self.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
    
    
    func checkWinLogic() {
        if myMoveText == "rock" {
            if opponentMoveText == "rock" {
                rpsLabel.text = "TIE"
                didTie = true
            }
            if opponentMoveText == "paper" {
                rpsLabel.text = "YOU LOSE!"
                didLose = true
            }
            if opponentMoveText == "scissors" {
                rpsLabel.text = "YOU WIN"
                didWin = true
            }
        } else if myMoveText == "paper" {
            if opponentMoveText == "rock" {
                rpsLabel.text = "YOU WIN!"
                didWin = true
            }
            if opponentMoveText == "paper" {
                rpsLabel.text = "TIE"
                didTie = true
            }
            if opponentMoveText == "scissors" {
                rpsLabel.text = "YOU LOSE"
                didLose = true
            }
        }else if myMoveText == "scissors" {
            if opponentMoveText == "rock" {
                rpsLabel.text = "YOU LOSE!"
                didLose = true
            }
            if opponentMoveText == "paper" {
                rpsLabel.text = "YOU WIN!"
                didWin = true
            }
            if opponentMoveText == "scissors" {
                rpsLabel.text = "TIE"
                didTie = true
            }
        }
    }
    
    
    func observeOpponentMove() {
        if user1 == currentUser {
            REF_TOURNAMENTS.child(tourny!.tournamentID).child("matches").child(matchID!).child("user2move").observe(.value) { (snapshot) in
                guard let move = snapshot.value as? String else { return }
                self.opponentMoveText = move
            }
        } else {
            REF_TOURNAMENTS.child(tourny!.tournamentID).child("matches").child(matchID!).child("user1move").observe(.value) { (snapshot) in
                guard let move = snapshot.value as? String else { return }
                self.opponentMoveText = move
            }
        }
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
        if currentUser == user1 {
            REF_TOURNAMENTS.child(tourny!.tournamentID).child("matches").child(matchID!).updateChildValues(["user1move": sender.currentTitle!])
        } else {
            REF_TOURNAMENTS.child(tourny!.tournamentID).child("matches").child(matchID!).updateChildValues(["user2move": sender.currentTitle!])
        }
    }
}
