//
//  LobbyPresenter.swift
//  BracketzFinal
//

import Foundation
import FirebaseDatabase

final class LobbyPresenter {
    unowned let view: LobbyVC
    let currentUser: User
    let tournySize: Int
    let tournyBuyIn = 1
    var tourny: Tournament
    private(set) var users = [User]()

    private var presentUsersHandle: DatabaseHandle?
    private var matchesHandle: DatabaseHandle?
    private var didStartRound = false
    private var didNavigateToMatch = false

    init(_ view: LobbyVC, currentUser: User, tournySize: Int, tourny: Tournament) {
        self.view = view
        self.currentUser = currentUser
        self.tournySize = tournySize
        self.tourny = tourny
        fetchUsers()
    }

    func fetchUsers() {
        let userIDs = tourny.tournamentUsers
        guard userIDs.count == tournySize else {
            view.presentError("This tournament has an invalid number of players.")
            return
        }

        var usersByID = [String: User]()
        var remainingFetches = userIDs.count

        for userID in userIDs {
            Service.shared.fetchUserData(uid: userID) { [weak self] user in
                guard let self else { return }
                if let user {
                    usersByID[userID] = user
                }
                remainingFetches -= 1
                guard remainingFetches == 0 else { return }

                self.users = userIDs.compactMap { usersByID[$0] }
                guard self.users.count == userIDs.count else {
                    self.view.presentError("One or more player profiles could not be loaded.")
                    return
                }

                self.view.reloadData()
                self.view.configureUI()
                self.observeTournament()
            }
        }
    }

    func observeTournament() {
        stopObservingPresentUsers()
        presentUsersHandle = Service.shared.observePresentUsers(tournamentID: tourny.tournamentID) { [weak self] presentUsers in
            guard let self else { return }
            let waitingCount = max(self.tournySize - presentUsers, 0)
            self.view.waitingOnLabel.text = "Waiting on \(waitingCount) users"

            guard presentUsers >= self.tournySize else { return }
            self.startRoundIfNeeded()
        }
    }

    func stop() {
        stopObservingPresentUsers()
        if let matchesHandle {
            Service.shared.stopObservingMatches(tournamentID: tourny.tournamentID, handle: matchesHandle)
        }
        matchesHandle = nil
    }

    private func startRoundIfNeeded() {
        guard !didStartRound else { return }
        didStartRound = true
        tourny.acceptedUsers = tournySize
        view.dimBackground()
        stopObservingPresentUsers()
        observeMatches()

        guard currentUser.uid == users.first?.uid else { return }
        Service.shared.configureRound(tournamentID: tourny.tournamentID, userIDs: users.map(\.uid)) { [weak self] succeeded in
            guard let self, !succeeded else { return }
            self.view.presentError("The tournament round could not be created.")
        }
    }

    private func observeMatches() {
        guard matchesHandle == nil else { return }
        matchesHandle = Service.shared.observeMatches(tournamentID: tourny.tournamentID) { [weak self] matches in
            guard let self,
                  BracketRules.matchesAreComplete(matches, expectedUserIDs: self.users.map(\.uid)),
                  let match = BracketRules.match(for: self.currentUser.uid, in: matches) else {
                return
            }
            self.enterMatch(match)
        }
    }

    private func enterMatch(_ match: TournamentMatch) {
        guard !didNavigateToMatch else { return }
        let usersByID = Dictionary(uniqueKeysWithValues: users.map { ($0.uid, $0) })
        let matchedUsers = match.userIDs.compactMap { usersByID[$0] }
        guard matchedUsers.count == 2 else { return }

        didNavigateToMatch = true
        stop()
        view.waitingOnLabel.textColor = .green
        view.waitingOnLabel.text = "Pot: $\(tournyBuyIn)"
        view.shouldPresentLoadingView(true, message: "Configuring round...")

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.view.shouldPresentLoadingView(false)
            let controller = MatchPlayVC(matchedUsers, self.tourny, match.matchID, self.tournySize, self.currentUser)
            self.view.navigationController?.popToRootViewController(animated: false)
            self.view.navigationController?.pushViewController(controller, animated: true)
        }
    }

    private func stopObservingPresentUsers() {
        if let presentUsersHandle {
            Service.shared.stopObservingPresentUsers(tournamentID: tourny.tournamentID, handle: presentUsersHandle)
        }
        presentUsersHandle = nil
    }

    deinit {
        stop()
    }
}
