//
//  File.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 11/7/22.
//

import Foundation


class LobbyPresenter {
    var view: LobbyVC
    var currentUser: User
    var tournySize: Int
    let tournyBuyIn = 1
    var tournyUserIDs = [String]()
    var count = 1
    
    init(_ view: LobbyVC, currentUser: User, tournySize: Int, tourny: Tournament) {
        self.view = view
        self.currentUser = currentUser
        self.tournySize = tournySize
        self.tourny = tourny
    }
    
    var tourny: Tournament? {
        didSet {
            view.fetchUsers()
        }
    }
    
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
                    view.reloadData()
                    view.configureUI()
                    observeTournament()
                }
            }
        }
    }
    
    func observeTournament() {
        Service.shared.observePresentUsers(uid: tourny!.tournamentID) { (presentUsers) in
            self.view.waitingOnLabel.text = "waiting on \(self.tournySize - presentUsers) users"
            if presentUsers == self.tournySize {
                self.tourny!.acceptedUsers = self.tournySize
                self.view.dimBackground()
                self.checkIfCurrentUserIsHost()
            }
        }
    }
    
    func checkIfCurrentUserIsHost() {
        if currentUser.uid == self.users![0].uid {
            view.configureTournament()
        } else {
            self.count += 1
            view.observeMatches()
            for x in 0..<self.users!.count {
                self.tournyUserIDs.append(self.users![x].uid)
            }
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
                
                if tournyUserIDs[x] == currentUser.uid || tournyUserIDs[x+1] == currentUser.uid {
                    matchIndex = x/2
                    finalUsers = matchUsers
                    myMatchId = sortedMatches[matchIndex]
                }
            }
            
        }
        
        view.waitingOnLabel.textColor = .green
        view.waitingOnLabel.text = "Pot: $\(tournyBuyIn)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.view.shouldPresentLoadingView(true, message: "Configuring round...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.view.shouldPresentLoadingView(false)
                let controller = MatchPlayVC(finalUsers, self.tourny!, myMatchId, self.tournySize, self.currentUser)
                self.view.navigationController?.popToRootViewController(animated: true)
                self.view.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}
