//
//  invitesVC.swift
//  BracketzFinal
//
//  Created by Edward McGuiggan on 5/18/21.
//

import UIKit
import Firebase

class InvitesVC: UITableViewController {
    
    var presenter: InvitesPresenter?
    
    init(currentUser: User) {
        super.init(nibName: nil, bundle: nil)
        presenter = InvitesPresenter(self, currentUser: currentUser)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Invite Cell")
        fetchInvites()
    }
    
    
    func fetchInvites() {
        guard let presenter = presenter else { return }
        presenter.fetchInvites()
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        while presenter!.invites == nil {
            return 0
        }
        return presenter!.invites!.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Invite Cell", for: indexPath)
        cell.textLabel?.text = presenter!.invites![indexPath.row]
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        presenter?.acceptInvite(indexPath: indexPath)
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            presenter?.deleteInvite(indexPath: indexPath)
        }
    }
}
