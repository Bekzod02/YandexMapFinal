//
//  OverlayView.swift
//  OverlayView
//
//  Created by Bekzod on 7/26/21.
//

import UIKit
import YandexMapsMobile

class OverlayView: UIViewController {
   
    // MARK: - Outlets
    @IBOutlet weak var slideIdicator: UIView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    var delegate: SearchDelegate?
    // Animation
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?
    // Mapkit properties
    var suggestResults: [YMKSuggestItem] = []
    let searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
    var suggestSession: YMKSearchSuggestSession!
    
    let BOUNDING_BOX = YMKBoundingBox(
        southWest: YMKPoint(latitude: 55.55, longitude: 37.42),
        northEast: YMKPoint(latitude: 55.95, longitude: 37.82))
    let SUGGEST_OPTIONS = YMKSuggestOptions()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Animation
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
        slideIdicator.roundCorners(.allCorners, radius: 10)
        // Mapkit
        suggestSession = searchManager.createSuggestSession()
        // Delegates
        searchBar.delegate = self
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }
    override func viewDidLayoutSubviews() {
        // Animation
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }
    // MARK: - Animation
    @objc func panGestureRecognizerAction(sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: view)
        // Not allowing the user to drag the view upward
        guard translation.y >= 0 else { return }
        // setting x as 0 because we don't want users to move the frame side ways!! Only want straight up or down
        view.frame.origin = CGPoint(x: 0, y: self.pointOrigin!.y + translation.y)
        
        if sender.state == .ended {
            let dragVelocity = sender.velocity(in: view)
            if dragVelocity.y >= 1300 {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Set back to original position of the view controller
                UIView.animate(withDuration: 0.3) {
                    self.view.frame.origin = self.pointOrigin ?? CGPoint(x: 0, y: 400)
                }
            }
        }
    }
}
// MARK: - Mapkit
extension OverlayView {
    func onSuggestResponse(_ items: [YMKSuggestItem]) {
        suggestResults = items
        tableView.reloadData()
    }
    func onSuggestError(_ error: Error) {
        let suggestError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if suggestError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if suggestError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
// MARK: - UITableViewDelegate/DataSource
extension OverlayView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.searchAndMoveMap(with: suggestResults[indexPath.row].title.text, info: suggestResults[indexPath.row].displayText!)
        dismiss(animated: true, completion: nil)
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = suggestResults[indexPath.row].displayText
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestResults.count
    }
}
// MARK: - UISearchBarDelegate
extension OverlayView: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let suggestHandler = {(response: [YMKSuggestItem]?, error: Error?) -> Void in
            if let items = response {
                self.onSuggestResponse(items)
            } else {
                self.onSuggestError(error!)
            }
        }
        suggestSession.suggest(
            withText: searchBar.text!,
            window: BOUNDING_BOX,
            suggestOptions: SUGGEST_OPTIONS,
            responseHandler: suggestHandler)
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        
        if suggestResults.isEmpty {
            dismiss(animated: true, completion: nil)
        }
    }
}
