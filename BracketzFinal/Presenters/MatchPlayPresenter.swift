//
//  MatchPlayPresenter.swift
//  BracketzFinal
//

import Foundation
import UIKit
import FirebaseDatabase

final class MatchPlayPresenter {
    let tournySize: Int
    let user1: String
    let user2: String
    unowned let view: MatchPlayVC
    let users: [User]
    var tourny: Tournament
    let currentUser: User
    let matchID: String

    private var timer: Timer?
    private var resultWorkItem: DispatchWorkItem?
    private var matchHandle: DatabaseHandle?
    private var tournamentUsersReference: DatabaseReference?
    private var tournamentUsersHandle: DatabaseHandle?
    private var currentRound = 1
    private var handledState: String?
    private var didLeaveMatch = false
    var timerCount = 10

    init(_ view: MatchPlayVC, tournySize: Int, users: [User], tourny: Tournament, currentUser: User, matchID: String) {
        self.view = view
        self.tournySize = tournySize
        self.users = users
        self.tourny = tourny
        self.currentUser = currentUser
        self.matchID = matchID
        user1 = users.first?.uid ?? ""
        user2 = users.dropFirst().first?.uid ?? ""
    }

    func startMatch() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerAction()
        }
    }

    func updateUserMoves(currentTitle: String) {
        Service.shared.submitMove(
            tournamentID: tourny.tournamentID,
            matchID: matchID,
            round: currentRound,
            userID: currentUser.uid,
            move: currentTitle
        )
    }

    func observeOpponentMove() {
        stopObservingMatch()
        matchHandle = Service.shared.observeMatch(tournamentID: tourny.tournamentID, matchID: matchID) { [weak self] state in
            self?.handleMatchState(state)
        }
    }

    @objc func timerAction() {
        view.timerLabel.text = String(max(timerCount, 0))
        timerCount -= 1

        if timerCount <= 2 {
            view.timerLabel.textColor = .red
        }

        if timerCount == -1 {
            view.rockButton.isEnabled = false
            view.paperButton.isEnabled = false
            view.scissorsButton.isEnabled = false
            view.timerLabel.isHidden = true
        } else if timerCount == -2 {
            view.rpsLabel.text = "ROCK"
        } else if timerCount == -3 {
            view.rpsLabel.text = "PAPER"
        } else if timerCount == -4 {
            view.rpsLabel.text = "SCISSORS"
        } else if timerCount == -5 {
            view.rpsLabel.text = "SHOOT!"
            view.opponentMove.text = view.opponentMoveText
            view.myMove.text = view.myMoveText
        } else if timerCount == -7 {
            timer?.invalidate()
            Service.shared.resolveMatch(tournamentID: tourny.tournamentID, matchID: matchID, round: currentRound)
        }
    }

    func observeTournament() {
        let newTournySize = tournySize / 2
        if newTournySize == 1 {
            REF_TOURNAMENTS.child(tourny.tournamentID).removeValue()
            Service.shared.removeInvite(tournamentID: tourny.tournamentID, uid: currentUser.uid)
            leaveMatch(for: WinnerVC())
            return
        }

        view.shouldPresentLoadingView(true, message: "Waiting for other matches to end...")
        REF_TOURNAMENTS.child(tourny.tournamentID).child("acceptedUsers").runTransactionBlock { currentData -> TransactionResult in
            let value = (currentData.value as? NSNumber)?.intValue ?? 0
            currentData.value = value + 1
            return TransactionResult.success(withValue: currentData)
        }

        stopObservingTournamentUsers()
        let reference = REF_TOURNAMENTS.child(tourny.tournamentID).child("tournamentUsers")
        tournamentUsersReference = reference
        tournamentUsersHandle = reference.observe(.value) { [weak self] snapshot in
            guard let self, let users = snapshot.value as? [String], users.count == newTournySize else { return }
            self.stopObservingTournamentUsers()
            self.view.shouldPresentLoadingView(false)
            let newTourny = Tournament(self.tourny.tournamentID, tournamentUsers: users, false)
            let controller = LobbyVC(currentUser: self.currentUser, tournySize: newTournySize, tourny: newTourny)
            self.didLeaveMatch = true
            self.view.navigationController?.popToRootViewController(animated: false)
            self.view.navigationController?.pushViewController(controller, animated: true)
        }
    }

    func resetMatchPlayUI() {
        timerCount = 10
        view.myMoveText = ""
        view.opponentMoveText = ""
        view.timerLabel.text = "10"
        view.timerLabel.textColor = .green
        view.myMove.text = ""
        view.opponentMove.text = ""
        view.rpsLabel.text = "SELECT YOUR MOVE"
        view.rockButton.isEnabled = true
        view.paperButton.isEnabled = true
        view.scissorsButton.isEnabled = true
        view.rockButton.setTitleColor(.white, for: .normal)
        view.paperButton.setTitleColor(.white, for: .normal)
        view.scissorsButton.setTitleColor(.white, for: .normal)
        view.rockButton.backgroundColor = .white
        view.paperButton.backgroundColor = .white
        view.scissorsButton.backgroundColor = .white
        view.timerLabel.isHidden = false
        startMatch()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        resultWorkItem?.cancel()
        resultWorkItem = nil
        stopObservingMatch()
        stopObservingTournamentUsers()
    }

    private func handleMatchState(_ state: LiveMatchState?) {
        guard let state, state.userIDs.contains(currentUser.uid), !didLeaveMatch else { return }
        currentRound = state.round
        let opponentMove = currentUser.uid == state.userIDs[0] ? state.user2Move : state.user1Move
        view.opponentMoveText = opponentMove ?? ""

        let stateKey = "\(state.round)-\(state.status.rawValue)"
        guard handledState != stateKey else { return }

        switch state.status {
        case .waiting:
            if handledState != nil {
                resetMatchPlayUI()
            }
            handledState = stateKey
        case .tie:
            handledState = stateKey
            timer?.invalidate()
            view.rpsLabel.text = "TIE"
            scheduleResultAction { [weak self] in
                guard let self else { return }
                Service.shared.restartTiedMatch(
                    tournamentID: self.tourny.tournamentID,
                    matchID: self.matchID,
                    round: state.round
                )
            }
        case .resolved:
            handledState = stateKey
            timer?.invalidate()
            guard let winnerID = state.winnerID, let loserID = state.loserID else { return }
            let didWin = winnerID == currentUser.uid
            view.rpsLabel.text = didWin ? "YOU WIN!" : "YOU LOSE!"
            scheduleResultAction { [weak self] in
                guard let self else { return }
                if didWin {
                    Service.shared.advanceWinner(
                        tournamentID: self.tourny.tournamentID,
                        winnerID: winnerID,
                        loserID: loserID
                    ) { [weak self] succeeded in
                        guard let self, succeeded else { return }
                        self.observeTournament()
                    }
                } else {
                    Service.shared.removeInvite(tournamentID: self.tourny.tournamentID, uid: self.currentUser.uid)
                    self.leaveMatch(for: LoserVC())
                }
            }
        }
    }

    private func scheduleResultAction(_ action: @escaping () -> Void) {
        resultWorkItem?.cancel()
        let workItem = DispatchWorkItem(block: action)
        resultWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: workItem)
    }

    private func leaveMatch(for controller: UIViewController) {
        guard !didLeaveMatch else { return }
        didLeaveMatch = true
        stop()
        view.navigationController?.pushViewController(controller, animated: true)
    }

    private func stopObservingMatch() {
        if let matchHandle {
            Service.shared.stopObservingMatch(tournamentID: tourny.tournamentID, matchID: matchID, handle: matchHandle)
        }
        matchHandle = nil
    }

    private func stopObservingTournamentUsers() {
        if let tournamentUsersHandle {
            tournamentUsersReference?.removeObserver(withHandle: tournamentUsersHandle)
        }
        tournamentUsersHandle = nil
        tournamentUsersReference = nil
    }

    deinit {
        stop()
    }
}
