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
    var tourny: Tournament?
    
    init(_ view: LobbyVC, currentUser: User, tournySize: Int, tourny: Tournament) {
        self.view = view
        self.currentUser = currentUser
        self.tournySize = tournySize
        self.tourny = tourny
        fetchUsers()
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
            configureTournament()
        } else {
            self.count += 1
            observeMatches()
            for x in 0..<self.users!.count {
                self.tournyUserIDs.append(self.users![x].uid)
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
    
    func observeMatches() {
        Service.shared.observeMatches(uid: tourny!.tournamentID) { (matches) in
            if matches.count == self.tournySize/2 {
                self.matchesArray = matches
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
