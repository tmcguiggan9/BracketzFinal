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
        if let invites = invites {
            Service.shared.addUserToInviteList(invites: invites, row: indexPath.row, view: self)
        }
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
