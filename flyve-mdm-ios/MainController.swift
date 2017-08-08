/*
 *   Copyright © 2017 Teclib. All rights reserved.
 *
 * MainController.swift is part of flyve-mdm-ios
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
 * @date      13/07/17
 * @copyright Copyright © 2017 Teclib. All rights reserved.
 * @license   GPLv3 https://www.gnu.org/licenses/gpl-3.0.html
 * @link      https://github.com/flyve-mdm/flyve-mdm-ios
 * @link      https://flyve-mdm.com
 * ------------------------------------------------------------------------------
 */

import UIKit
import CocoaMQTT
import CoreLocation
import FlyveMDMInventory
import FileExplorer

class MainController: UIViewController {

    var mqtt: CocoaMQTT?
    var httpRequest: HttpRequest?
    var userInfo = [String: AnyObject]()
    var mdmAgent = [String: Any]()
    var supervisor = [String: AnyObject]()
    var topic = ""
    let cellId = "cellId"
    var location: Location!
    var isAdmin = false
    var deployFile = [AnyObject]()
    var removeFile = [AnyObject]()

    init(mdmAgent: [String: Any]) {

        self.mdmAgent = mdmAgent

        if let topic = mdmAgent["topic"] as? String {
            self.topic = topic
        }
        
        if let dataUserObject = getStorage(key: "dataUser") as? [String: AnyObject] {
            userInfo = dataUserObject
        }
        
        if let supervisorObject = getStorage(key: "supervisor") as? [String: AnyObject] {
            supervisor = supervisorObject
        }
        
        isAdmin = UserDefaults.standard.bool(forKey: "admin")

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        
        let notificationData = NotificationCenter.default
        notificationData.addObserver(self, selector: #selector(self.editUser), name: NSNotification.Name(rawValue: "editUser"), object: nil)

        setupViews()
        addConstraints()

        if let broker = mdmAgent["broker"] as? String,
            let port = mdmAgent["port"] as? UInt16,
            let user = userInfo["_serial"] as? String,
            let password = mdmAgent["mqttpasswd"] as? String,
            !broker.isEmpty, !user.isEmpty, !password.isEmpty {

            connectBroker(host: broker, port: port, user: user, password: password)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }

    func setupViews() {

        view.backgroundColor = .background
        view.addSubview(statusView)
        statusView.addSubview(loadingIndicatorView)
        view.addSubview(logoImageView)
        view.addSubview(mainTableView)
    }

    func addConstraints() {

        statusView.topAnchor.constraint(equalTo: view.topAnchor, constant: 22.0).isActive = true
        statusView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -14.0).isActive = true
        statusView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        statusView.heightAnchor.constraint(equalToConstant: 10).isActive = true

        loadingIndicatorView.centerXAnchor.constraint(equalTo: statusView.centerXAnchor).isActive = true
        loadingIndicatorView.centerYAnchor.constraint(equalTo: statusView.centerYAnchor).isActive = true
        loadingIndicatorView.widthAnchor.constraint(equalToConstant: 10).isActive = true
        loadingIndicatorView.heightAnchor.constraint(equalToConstant: 10).isActive = true

        logoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 72).isActive = true
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true

        mainTableView.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 48).isActive = true
        mainTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        mainTableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        mainTableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }

    lazy var logoImageView: UIImageView = {

        let imageView = UIImageView(image: UIImage(named: "logo"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.isUserInteractionEnabled = true

        let multiTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.showLog))
        multiTap.numberOfTapsRequired = 10
        imageView.addGestureRecognizer(multiTap)

        return imageView
    }()

    lazy var mainTableView: UITableView = {

        let table = UITableView(frame: .zero, style: .plain)
        table.delegate = self
        table.dataSource = self
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.tableFooterView = UIView()
        table.rowHeight = UITableViewAutomaticDimension
        table.estimatedRowHeight = 100
        table.register(MainCell.self, forCellReuseIdentifier: self.cellId)

        return table
    }()

    let loadingIndicatorView: UIActivityIndicatorView = {

        let loading = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        loading.translatesAutoresizingMaskIntoConstraints = false
        loading.hidesWhenStopped = true

        return loading
    }()

    let statusView: UIView = {

        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 5.0
        view.backgroundColor = .clear

        return view
    }()

    func showLog() {
        UserDefaults.standard.set(!isAdmin, forKey: "admin")
        UserDefaults.standard.synchronize()
        isAdmin = !isAdmin
        mainTableView.reloadData()
    }

    func goLogController() {
        navigationController?.pushViewController(TopicLogController(), animated: true)
    }

    func goEnrollmentController() {
        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: ViewController(userToken: "", invitationToken: ""))
    }
    
    func goFileExplorerController() {
        let fileExplorer = FileExplorerViewController()
        fileExplorer.canRemoveFiles = false
        fileExplorer.canRemoveDirectories = false
        
        self.present(fileExplorer, animated: true, completion: nil)
    }
    
    func goUserController() {
        self.present(UINavigationController(rootViewController: UserController()), animated: true, completion: nil)
    }
    
    func editUser() {
        
        if let dataUserObject = getStorage(key: "dataUser") as? [String: AnyObject] {
            userInfo = dataUserObject
            
            mainTableView.beginUpdates()
            mainTableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .automatic)
            mainTableView.endUpdates()
        }
    }
    
    func goSupervisorController() {
        self.present(UINavigationController(rootViewController: SupervisorController()), animated: true, completion: nil)
    }
}

extension MainController: UITableViewDelegate {

}

extension MainController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        if isAdmin {
            return 4
        } else {
            return 3
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: self.cellId, for: indexPath) as? MainCell

        if indexPath.row == 0 {
            cell?.titleLabel.text = "title_ supervised".localized.uppercased()
            cell?.descriptionLabel.text = "\(supervisor["support_name"] as? String ?? "Support name")"
            cell?.detailLabel.text = "\(supervisor["support_email"] as? String ?? "Email")"
            cell?.openBotton.addTarget(self, action: #selector(self.goSupervisorController), for: .touchUpInside)

        } else if indexPath.row == 1 {
            cell?.titleLabel.text = "title_user".localized.uppercased()
            cell?.descriptionLabel.text = "\(userInfo["firstname"] as? String ?? "") \(userInfo["lastname"] as? String ?? "")"
            
            if let email = userInfo["_email"] as? [AnyObject], email.count > 0 {
                cell?.detailLabel.text = email.first?["email"] as? String ?? "Email"
            }

            cell?.openBotton.addTarget(self, action: #selector(self.goUserController), for: .touchUpInside)

        } else if indexPath.row == 2 {
            cell?.titleLabel.text = "title_resources".localized.uppercased()
            cell?.openBotton.addTarget(self, action: #selector(self.goFileExplorerController), for: .touchUpInside)

        } else if indexPath.row == 3 {
            cell?.titleLabel.text = "log_report".localized.uppercased()
            cell?.openBotton.addTarget(self, action: #selector(self.goLogController), for: .touchUpInside)
        }

        return cell!
    }
}

extension MainController: CocoaMQTTDelegate {

    func connectBroker(host: String, port: UInt16, user: String, password: String) {

        self.mqttSetting(host: host, port: port, username: user, password: "\(password)")
        self.mqtt!.connect()

        loadingIndicatorView.startAnimating()
        statusView.backgroundColor = .clear
    }

    func mqttSetting(host: String, port: UInt16, username: String, password: String) {
        
        let message = "{ online: false }"
        let willMessage = CocoaMQTTWill(topic: "\(topic)/Status/Online", message: message)
        willMessage.qos = .qos0
        willMessage.retained = false
        
        mqtt = CocoaMQTT(clientID: username, host: host, port: port)
        mqtt!.username = username
        mqtt!.password = password
        mqtt!.willMessage = willMessage
        mqtt!.keepAlive = 60
        mqtt!.delegate = self
        mqtt!.enableSSL = true
        mqtt!.autoReconnect = true
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {

        completionHandler(true)
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
        print("didConnect \(host):\(port)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck: \(ack)，rawValue: \(ack.rawValue)")

        if ack == .accept {
            mqtt.subscribe("\(topic)/#", qos: CocoaMQTTQOS.qos1)
            mqtt.subscribe("/FlyvemdmManifest/Status/Version", qos: CocoaMQTTQOS.qos1)
            print("Subscribed to topic \(String(describing: topic))/#")
        }

        loadingIndicatorView.stopAnimating()

        if mqtt.connState == .connected {
            statusView.backgroundColor = .green

        } else {
            statusView.backgroundColor = .red
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage with message: \(String(describing: message.string!))")
    }

    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck with id: \(id)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
//        print(message.string ?? "Empty Message")

        let name = NSNotification.Name(rawValue: "MQTTMessageNotification")
        NotificationCenter.default.post(name: name, object: self, userInfo: ["message": message.string!, "topic": message.topic])
        
        if message.topic == "/FlyvemdmManifest/Status/Version" {
            setStorage(value: message.string as AnyObject, key: "manifest")
        }

        var messageBroker: [String: AnyObject]? = [String: AnyObject]()

        if let data = message.string?.data(using: .utf8) {
            do {
                messageBroker = try JSONSerialization.jsonObject(with: data, options: []) as? [String: AnyObject]
            } catch {
                print(error.localizedDescription)
            }

            if let messageQuery: String = messageBroker?["query"] as? String {
                if messageQuery == "Ping" {
                    replyPing()

                } else if messageQuery == "Geolocate" {
                    location = Location()
                    location.delegate = self
                    location.getCurrentLocation()
                    
                } else if messageQuery == "Inventory" {
                    replyInventory()
                }
            } else if let messageUnenroll: String = messageBroker?["unenroll"] as? String {
                if messageUnenroll == "now" {
                    replyUnenroll()
                }
            } else if let messageSubscribe: [AnyObject] = messageBroker?["subscribe"] as? [AnyObject] {
                
                if messageSubscribe.count > 0 {
                    if let fleet = messageSubscribe[0]["topic"] as? String {
                        subscribeFleet(fleet)
                    }
                }
            } else if let messageFile: [AnyObject] = messageBroker?["file"] as? [AnyObject] {
                
                if messageFile.count > 0 {
                    fileManage(messageFile)
                }
            }
        }
    }

    func replyPing() {
        let topicPing = "\(topic)/Status/Ping"
        mqtt?.publish(topicPing, withString: "!")
    }

    func replyUnenroll() {
        let topicUnenroll = "\(topic)/Status/Unenroll"
        let answer = "{\"unenroll\": \"unenrolled\"}"
        mqtt?.publish(topicUnenroll, withString: answer)
        mqtt?.disconnect()
        removeAllStorage()
        goEnrollmentController()
    }

    func replyGeolocate(latitude: Double, longitude: Double, datetime: Int) {
        let topicGeolocation = "\(topic)/Status/Geolocation"
        let answer = "{\"latitude\":\(latitude),\"longitude\":\(longitude),\"datetime\":\(datetime)}"
        mqtt?.publish(topicGeolocation, withString: answer)
    }
    
    func replyInventory() {
        let inventory = InventoryTask()
        inventory.execute(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") { result in
            
            let topicInventory = "\(topic)/Status/Inventory"
            mqtt?.publish(topicInventory, withString: result)
        }
    }
    
    func subscribeFleet(_ fleet: String) {
        mqtt!.subscribe("\(fleet)/#", qos: CocoaMQTTQOS.qos1)
        print("Subscribed to topic \(String(describing: fleet))/#")
    }
    
    func fileManage(_ files: [AnyObject]) {
        
        deployFile = files.filter {
            if (($0 as? [String: String] ?? [String: String]())["deployFile"]) != nil {
                return true
            } else {
                return false
            }
        }
        
        removeFile = files.filter {
            if (($0 as? [String: String] ?? [String: String]())["removeFile"]) != nil {
                return true
            } else {
                return false
            }
        }
        
        if deployFile.count > 0 {
            if let deeplink = getStorage(key: "deeplink") as? [String: String] {
                httpRequest = HttpRequest()
                httpRequest?.requestInitSession(userToken: deeplink["user_token"] ?? "")
                httpRequest?.delegate = self
            }
        }

        for file in removeFile {
            removeFileFleet(file as? [String : String])
        }
    }
    
    func removeFileFleet(_ file: [String: String]?) {
        
        guard let fileName = file?["removeFile"]?.replacingOccurrences(of: "%DOCUMENTS%/", with: "") else {
            return
        }
        
        let fileManager = FileManager.default
        
        if let documentsPath =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path {
            
            do {
                let filePathName = "\(documentsPath)/\(fileName)"
                try fileManager.removeItem(atPath: filePathName)
                
            } catch {
                print("Could not delete file: \(error)")
            }
        }
    }

    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic to \(topic)")
    }

    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic to \(topic)")
    }

    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("didPing")
    }

    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("didReceivePong")
    }

    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("mqttDidDisconnect")
        statusView.backgroundColor = .red
    }
}

extension MainController: HttpRequestDelegate {
    
    func responseInitSession(data: [String: AnyObject]) {
        
        if let session_token = data["session_token"] as? String {
            sessionToken = session_token
            httpRequest?.requestGetFullSession()
        }
    }
    
    func errorInitSession(error: [String: String]) {
        
    }
    
    func responseGetFullSession(data: [String: AnyObject]) {
        
        if let profiles_id = (data["session"]?["glpiactiveprofile"] as? [String: AnyObject])?["id"] as? Int, let guest_profiles_id = data["session"]?["plugin_flyvemdm_guest_profiles_id"] as? Int {
            
            if profiles_id == guest_profiles_id {
                httpRequest?.requestChangeActiveProfile(profilesID: "\(profiles_id)")
                
            } else {
                print("Error: Change active profile")
            }
        } else {
            print("Error: Change active profile")
        }
    }
    
    func errorGetFullSession(error: [String: String]) {
        
    }
    
    func responseChangeActiveProfile() {
        
        for files in deployFile {
            
            if let fileID = files["id"] as? String {
                DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
                    self?.httpRequest?.requestPluginFlyvemdmFile(fileID: fileID)
                }
            }
        }
    }
    
    func errorChangeActiveProfile(error: [String: String]) {
        
    }
}

extension MainController: LocationDelegate {

    func currentLocation(coordinate: CLLocationCoordinate2D) {

        let date = Date()
        let datetime = Int(date.timeIntervalSince1970/1000)

        replyGeolocate(latitude: coordinate.latitude, longitude: coordinate.longitude, datetime: datetime)
    }
}
