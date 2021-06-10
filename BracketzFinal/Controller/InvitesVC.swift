//
//  invitesVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/18/21.
//

import UIKit
import Firebase

class InvitesVC: UITableViewController {
    

    
    private var invites: [String]? {
        didSet {
            tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Invite Cell")
        fetchInvites()
    }
    
    
    func fetchInvites() {
        let uid = Auth.auth().currentUser?.uid
        Service.shared.fetchInvites(uid: uid!) { (invites) in
            self.invites = invites
        }
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        while invites == nil {
            return 0
        }
        return invites!.count
    }
 
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Invite Cell", for: indexPath)
        cell.textLabel?.text = invites![indexPath.row]
        return cell
    }
  
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.popViewController(animated: true)
        let controller = LobbyVC()
        
        REF_TOURNAMENTS.child(invites![indexPath.row]).child("acceptedUsers").observeSingleEvent(of: .value) { (snapshot) in
            guard var presentUsers = snapshot.value as? Int else { return }
            presentUsers += 1
            REF_TOURNAMENTS.child(self.invites![indexPath.row]).updateChildValues(["acceptedUsers": presentUsers])
        }
        
        
        REF_TOURNAMENTS.child(invites![indexPath.row]).child("tournamentUsers").observeSingleEvent(of: .value) { (snapshot) in
            guard let users = snapshot.value as? [String] else { return }
            controller.tourny = Tournament(self.invites![indexPath.row], tournamentUsers: users)
            controller.tournySize = users.count
        }
        navigationController?.pushViewController(controller, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let uid = Auth.auth().currentUser?.uid
            REF_TOURNAMENTS.child(invites![indexPath.row]).removeValue()
            invites?.remove(at: indexPath.row)
            REF_USERS.child(uid!).updateChildValues(["unresolvedTournaments": invites!])
            tableView.reloadData()
        }
    }
}
