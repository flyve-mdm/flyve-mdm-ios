/*
 *   Copyright © 2017 Teclib. All rights reserved.
 *
 * UserController.swift is part of flyve-mdm-ios
 *
 * flyve-mdm-ios is a subproject of Flyve MDM. Flyve MDM is a mobile
 * device management software.
 *
 * flyve-mdm-ios is free software: you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 3
 * of the License, or (at your option) any later version.
 *
 * flyve-mdm-ios is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * ------------------------------------------------------------------------------
 * @author    Hector Rondon
 * @date      31/07/17
 * @copyright Copyright © 2017 Teclib. All rights reserved.
 * @license   GPLv3 https://www.gnu.org/licenses/gpl-3.0.html
 * @link      https://github.com/flyve-mdm/flyve-mdm-ios-agent
 * @link      https://flyve-mdm.com
 * ------------------------------------------------------------------------------
 */

import UIKit
import MessageUI
/// UserController class
class UserController: UIViewController {
    // MARK: Properties
    /// `cellIdMain`
    let cellIdMain = "cellIdMain"
    /// `cellIdInfo`
    let cellIdInfo = "cellIdInfo"
    /// `userInfo`
    var userInfo: UserModel!
    
    /// `userTableView UITableView`
    lazy var userTableView: UITableView = {
        
        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.tableFooterView = UIView()
        table.rowHeight = UITableViewAutomaticDimension
        table.estimatedRowHeight = 100
        table.isScrollEnabled = true
        table.register(SupervisorMainCell.self, forCellReuseIdentifier: self.cellIdMain)
        table.register(SupervisorInfoCell.self, forCellReuseIdentifier: self.cellIdInfo)
        
        return table
    }()
    
    // MARK: Init
    /// `override viewWillAppear`
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    /// `override loadView`
    override func loadView() {
        
        if let dataUserObject = getStorage(key: "dataUser") as? UserModel {
            userInfo = dataUserObject
        }
        
        super.loadView()
        self.setupViews()
        self.addConstraints()
    }
    
    /// `override setupViews`
    func setupViews() {
        self.view.backgroundColor = .white
        
        let saveButton = UIBarButtonItem(title: "edit".localized,
                                         style: UIBarButtonItemStyle.plain,
                                         target: self,
                                         action: #selector(self.edit))
        
        let cancelButton = UIBarButtonItem(title: "cancel".localized,
                                           style: UIBarButtonItemStyle.plain,
                                           target: self,
                                           action: #selector(self.cancel))
        
        self.navigationItem.rightBarButtonItem = saveButton
        self.navigationItem.leftBarButtonItem = cancelButton
        
        self.view.addSubview(self.userTableView)
    }
    
    // MARK: Constraints
    /// `addConstraints()`
    func addConstraints() {
        userTableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        userTableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
        userTableView.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
        userTableView.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
    }
    
    // MARK: Methods
    /// go `UserFormController`
    func edit() {
        let userCntroller = UserFormController(style: .grouped, userInfo: userInfo, edit: true)

        navigationController?.pushViewController(userCntroller, animated: true)
    }
    
    /// back main screen
    func cancel() {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: MFMailComposeViewControllerDelegate
extension UserController: MFMailComposeViewControllerDelegate {
    
    /// implemente delegate `didFinishWith`
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: MFMessageComposeViewControllerDelegate
extension UserController: MFMessageComposeViewControllerDelegate {
    /// implemente delegate `didFinishWith`
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: UITableViewDelegate
extension UserController: UITableViewDelegate {
    /// tells the delegate that the specified row is now selected.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
}

// MARK: UITableViewDataSource
extension UserController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdMain, for: indexPath) as? SupervisorMainCell

            cell?.photoImageView.image = userInfo.picture
            cell?.nameLabel.text = "\(userInfo.firstName) \(userInfo.lastName)"
            cell?.detailLabel.text = ""
            
            return cell!
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdInfo, for: indexPath) as? SupervisorInfoCell
            
            if indexPath.row == 1 {
                
                cell?.nameLabel.text = userInfo.phone
                cell?.firstBotton.image = UIImage(named: "call")?.withRenderingMode(.alwaysTemplate)
                cell?.secondBotton.image = UIImage(named: "message")?.withRenderingMode(.alwaysTemplate)
                
            } else if indexPath.row == 2 {
                
                cell?.nameLabel.text = userInfo.emails.first?.email ?? "Email"
                cell?.firstBotton.image = UIImage(named: "email")?.withRenderingMode(.alwaysTemplate)
                cell?.footerView.isHidden = true
            }
            return cell!
        }
    }
}
