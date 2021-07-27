//
//  BookMarkController.swift
//  locationBook
//
//  Created by Bekzod Khaitboev on 7/24/21.
//

import UIKit

class BookMarkController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
        if let nav = tabBarController?.viewControllers![1] as? UINavigationController {
            for vc in nav.viewControllers {
                if vc.isKind(of: LocationController.self) {
                    let locationVC = vc as! LocationController
                    delegate = locationVC
                }
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let locations = UserDefaults.standard.array(forKey: "locations") as? [String] {
            self.locations = locations
        }
    }
    // MARK: - Properties
    var locations = [String]() {
        didSet {
            tableView.reloadData()
        }
    }
    var delegate: SearchDelegate?
}
// MARK: - UITableViewDelegate/DataSource
extension BookMarkController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "locationCell", for: indexPath)
        cell.textLabel?.text = locations[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        UIView.animate(withDuration: 0.4, delay: 0, options: .layoutSubviews) {
            self.tabBarController?.selectedIndex = 1
        } completion: { _ in
            self.delegate?.searchAndMoveMap(with: self.locations[indexPath.row], info: self.locations[indexPath.row])
        }
    }
}
