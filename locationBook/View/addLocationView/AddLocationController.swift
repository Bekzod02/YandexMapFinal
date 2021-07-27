//
//  OverlayView.swift
//  SlideOverTutorial
//
//  Created by Bekzod on 7/26/2021.
//

import UIKit

class AddLocationController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var slideIdicator: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var addLocationButton: UIButton!
    // MARK: - Properties
    var infoTitle: String?
    // Animation Properties
    var hasSetPointOrigin = false
    var pointOrigin: CGPoint?
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerAction))
        view.addGestureRecognizer(panGesture)
        
        slideIdicator.roundCorners(.allCorners, radius: 10)
        addLocationButton.roundCorners(.allCorners, radius: 10)
        
        if let locations = UserDefaults.standard.array(forKey: "locations") as? [String] {
            for location in locations {
                if infoTitle! == location {
                    addLocationButton.setTitle("Already added", for: .normal)
                    addLocationButton.isUserInteractionEnabled = false
                }
            }
        }
        infoLabel.text = infoTitle
    }
    init(infoTitle: String) {
        super.init(nibName: nil, bundle: nil)
        self.infoTitle = infoTitle
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLayoutSubviews() {
        if !hasSetPointOrigin {
            hasSetPointOrigin = true
            pointOrigin = self.view.frame.origin
        }
    }
    // MARK: - Functions
    @IBAction func addLocationTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: "Add location to reminders", message: infoTitle, preferredStyle: .alert)
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let action = UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            // save location
            if var locations = UserDefaults.standard.array(forKey: "locations") as? [String],
               let infoTitle = self?.infoTitle {
                locations.append(infoTitle)
                UserDefaults.standard.set(locations, forKey: "locations")
            }
            self?.dismiss(animated: true, completion: nil)
        }
        alert.addAction(cancel)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
}
// MARK: - Animation
extension AddLocationController {
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
