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
    var tourny: Tournament
    var matchesArray = [String]()
    var users = [User]()
    
    init(_ view: LobbyVC, currentUser: User, tournySize: Int, tourny: Tournament) {
        self.view = view
        self.currentUser = currentUser
        self.tournySize = tournySize
        self.tourny = tourny
        fetchUsers()
    }
    
    func fetchUsers() {
        var usersByID = [String: User]()
        let userIDs = tourny.tournamentUsers

        for userID in userIDs {
            Service.shared.fetchUserData(uid: userID) { user in
                usersByID[userID] = user

                guard usersByID.count == userIDs.count else { return }
                self.users = userIDs.compactMap { usersByID[$0] }

                guard self.users.count == self.tournySize, self.count == 1 else { return }
                self.view.reloadData()
                self.view.configureUI()
                self.observeTournament()
            }
        }
    }
    
    func observeTournament() {
        Service.shared.observePresentUsers(uid: tourny.tournamentID) { (presentUsers) in
            self.view.waitingOnLabel.text = "waiting on \(self.tournySize - presentUsers) users"
            if presentUsers == self.tournySize {
                self.tourny.acceptedUsers = self.tournySize
                self.view.dimBackground()
                self.checkIfCurrentUserIsHost()
            }
        }
    }
    
    func checkIfCurrentUserIsHost() {
        guard let host = users.first else { return }

        if currentUser.uid == host.uid {
            configureTournament()
        } else {
            count += 1
            tournyUserIDs = users.map(\.uid)
            observeMatches()
        }
    }
    
    func configureTournament() {
        
            if count == 1, users.count == tournySize {
                for x in 0..<users.count {
                    if x%2 == 0 {
                        let usernames = [users[x].uid, users[x + 1].uid]
                        tournyUserIDs.append(contentsOf: usernames)
                        
                        let values = ["users": usernames] as [String: Any]
                        REF_TOURNAMENTS.child(tourny.tournamentID).child("matches").childByAutoId().updateChildValues(values)
                    }
                }
                observeMatches()
                count += 1
            }
    
    }
    
    func observeMatches() {
        Service.shared.observeMatches(uid: tourny.tournamentID) { (matches) in
            if matches.count == self.tournySize/2 {
                self.matchesArray = matches
                self.setMatch()
            }
        }
    }
    
    func setMatch() {
        let sortedMatches = matchesArray.sorted()
        guard users.count == tournyUserIDs.count,
              sortedMatches.count == tournySize / 2,
              let playerIndex = tournyUserIDs.firstIndex(of: currentUser.uid) else { return }

        let pairStartIndex = playerIndex - (playerIndex % 2)
        guard users.indices.contains(pairStartIndex + 1),
              sortedMatches.indices.contains(pairStartIndex / 2) else { return }

        let finalUsers = [users[pairStartIndex], users[pairStartIndex + 1]]
        let myMatchId = sortedMatches[pairStartIndex / 2]
        
        view.waitingOnLabel.textColor = .green
        view.waitingOnLabel.text = "Pot: $\(tournyBuyIn)"
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.view.shouldPresentLoadingView(true, message: "Configuring round...")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.view.shouldPresentLoadingView(false)
                let controller = MatchPlayVC(finalUsers, self.tourny, myMatchId, self.tournySize, self.currentUser)
                self.view.navigationController?.popToRootViewController(animated: true)
                self.view.navigationController?.pushViewController(controller, animated: true)
            }
        }
    }
}
