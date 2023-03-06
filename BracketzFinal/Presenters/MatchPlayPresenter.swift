//
//  MatchPlayPresenter.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 3/6/23.
//

import Foundation
import Firebase

class MatchPlayPresenter {
    
    var tournySize = Int()
    var user1 = String()
    var user2 = String()
    var view: MatchPlayVC
    var timer = Timer()
    var timerCount = 10
    var didWin = false
    var didTie = false
    var didLose = false
    var user1Move: String = ""
    var user2Move: String = ""
    var users: [User]?
    var tourny: Tournament
    var currentUser: User
    var matchID: String?
    
    init(_ view: MatchPlayVC, tournySize: Int, users: [User], tourny: Tournament, currentUser: User, matchID: String) {
        self.view = view
        self.tournySize = tournySize
        self.users = users
        self.tourny = tourny
        self.currentUser = currentUser
        self.matchID = matchID
        user1 = users[0].uid
        user2 = users[1].uid
    }
    
    func startMatch() {
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
    }
    
    func updateUserMoves(currentTitle: String) {
        if currentUser.uid == user1 {
            REF_TOURNAMENTS.child(tourny.tournamentID).child("matches").child(matchID!).updateChildValues(["user1move": currentTitle])
        } else {
            REF_TOURNAMENTS.child(tourny.tournamentID).child("matches").child(matchID!).updateChildValues(["user2move": currentTitle])
        }
    }
    
    func observeOpponentMove() {
        if user1 == currentUser.uid {
            REF_TOURNAMENTS.child(tourny.tournamentID).child("matches").child(matchID!).child("user2move").observe(.value) { (snapshot) in
                guard let move = snapshot.value as? String else { return }
                self.view.opponentMoveText = move
            }
        } else {
            REF_TOURNAMENTS.child(tourny.tournamentID).child("matches").child(matchID!).child("user1move").observe(.value) { (snapshot) in
                guard let move = snapshot.value as? String else { return }
                self.view.opponentMoveText = move
            }
        }
    }
    
    @objc func timerAction(){
        view.timerLabel.text = String(timerCount)
        timerCount -= 1
        
        if timerCount <= 2 {
            view.timerLabel.textColor = .red
        }
        
        if timerCount == -1 {
            view.rockButton.isEnabled = false
            view.paperButton.isEnabled = false
            view.scissorsButton.isEnabled = false
            view.timerLabel.isHidden = true
        }
        
        if timerCount == -2 {
            view.rpsLabel.text = "ROCK"
        }
        
        if timerCount == -3 {
            view.rpsLabel.text = "PAPER"
        }
        
        if timerCount == -4 {
            view.rpsLabel.text = "SCISSORS"
        }
        
        if timerCount == -5 {
            view.rpsLabel.text = "SHOOT!"
            view.opponentMove.text = view.opponentMoveText
            view.myMove.text = view.myMoveText
        }
        
        if timerCount == -7 {
            timer.invalidate()
            checkWinLogic()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                if self.didWin {
                    self.observeTournament()
                } else if self.didLose {
                    
                    REF_TOURNAMENTS.child(self.tourny.tournamentID).child("matches").child(self.matchID!).removeValue()
                    
                    REF_TOURNAMENTS.child(self.tourny.tournamentID).child("tournamentUsers").runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                        var value = currentData.value as? [String]
                        
                        if value == nil {
                            value = []
                        }
                        
                        if let index = value?.firstIndex(of: self.currentUser.uid) {
                            value?.remove(at: index)
                        }
                        currentData.value = value
                        return TransactionResult.success(withValue: currentData)
                    }
                    
                    
                    REF_USERS.child(self.currentUser.uid).child("unresolvedTournaments").observeSingleEvent(of: .value) { (snapshot) in
                        guard var invites = snapshot.value as? [String] else { return }
                        if let index = invites.firstIndex(of: self.tourny.tournamentID) {
                            invites.remove(at: index)
                        }
                        REF_USERS.child(self.currentUser.uid).updateChildValues(["unresolvedTournaments": invites])
                    }
                    
                    let controller = LoserVC()
                    self.view.navigationController?.pushViewController(controller, animated: true)
                } else if self.didTie {
                    self.resetMatchPlayUI()
                }
            }
        }
    }
    
    func observeTournament() {
        let newTournySize = tournySize/2
        if newTournySize == 1 {
            REF_TOURNAMENTS.child(self.tourny.tournamentID).removeValue()
            REF_USERS.child(self.currentUser.uid).child("unresolvedTournaments").observeSingleEvent(of: .value) { (snapshot) in
                guard var invites = snapshot.value as? [String] else { return }
                if let index = invites.firstIndex(of: self.tourny.tournamentID) {
                    invites.remove(at: index)
                }
                REF_USERS.child(self.currentUser.uid).updateChildValues(["unresolvedTournaments": invites])
            }
            let controller = WinnerVC()
            view.navigationController?.pushViewController(controller, animated: true)
            
        } else {
            view.shouldPresentLoadingView(true, message: "Waiting for other matches to end...")
            REF_TOURNAMENTS.child(self.tourny.tournamentID).child("acceptedUsers").runTransactionBlock { (currentData: MutableData) -> TransactionResult in
                var value = currentData.value as? Int
                
                if value == nil {
                    value = 0
                }
                
                currentData.value = value! + 1
                return TransactionResult.success(withValue: currentData)
            }
            
            REF_TOURNAMENTS.child(tourny.tournamentID).child("tournamentUsers").observe(.value) { (snapshot) in
                guard let users = snapshot.value as? [String] else { return }
                
                if users.count == newTournySize {
                    self.view.shouldPresentLoadingView(false)
                    let newTourny = Tournament(self.tourny.tournamentID, tournamentUsers: users, false)
                    let controller = LobbyVC(currentUser: self.currentUser, tournySize: newTournySize, tourny: newTourny)
                    self.view.navigationController?.popToRootViewController(animated: true)
                    self.view.navigationController?.pushViewController(controller, animated: true)
                }
            }
        }
    }
    
    func resetMatchPlayUI() {
        self.didTie = false
        self.timerCount = 10
        view.timerLabel.text = "10"
        view.timerLabel.textColor = .green
        view.myMove.text = ""
        view.opponentMove.text = ""
        view.rockButton.isEnabled = true
        view.paperButton.isEnabled = true
        view.scissorsButton.isEnabled = true
        view.rockButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        view.paperButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        view.scissorsButton.setTitleColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1), for: .normal)
        view.rockButton.backgroundColor = .white
        view.paperButton.backgroundColor = .white
        view.scissorsButton.backgroundColor = .white
        view.timerLabel.isHidden = false
        self.startMatch()
    }
    
    func checkWinLogic() {
        if view.myMoveText == "rock" {
            if view.opponentMoveText == "rock"  {
                view.rpsLabel.text = "TIE"
                didTie = true
            }
            if view.opponentMoveText == "paper" {
                view.rpsLabel.text = "YOU LOSE!"
                didLose = true
            }
            if view.opponentMoveText == "scissors" || view.opponentMoveText == ""{
                view.rpsLabel.text = "YOU WIN"
                didWin = true
            }
        } else if view.myMoveText == "paper" {
            if view.opponentMoveText == "rock" || view.opponentMoveText == ""{
                view.rpsLabel.text = "YOU WIN!"
                didWin = true
            }
            if view.opponentMoveText == "paper" {
                view.rpsLabel.text = "TIE"
                didTie = true
            }
            if view.opponentMoveText == "scissors" {
                view.rpsLabel.text = "YOU LOSE"
                didLose = true
            }
        } else if view.myMoveText == "scissors" {
            if view.opponentMoveText == "rock" {
                view.rpsLabel.text = "YOU LOSE!"
                didLose = true
            }
            if view.opponentMoveText == "paper" || view.opponentMoveText == ""{
                view.rpsLabel.text = "YOU WIN!"
                didWin = true
            }
            if view.opponentMoveText == "scissors" {
                view.rpsLabel.text = "TIE"
                didTie = true
            }
        } else {
            view.rpsLabel.text = "YOU LOSE!"
            didLose = true
        }
    }
}
