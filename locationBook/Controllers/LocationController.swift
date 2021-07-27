//
//  ViewController.swift
//  locationBook
//
//  Created by Bekzod Khaitboev on 7/23/21.
//

import UIKit
import YandexMapsMobile

class LocationController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: YMKMapView!
    // MARK: - Properties
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search..."
        searchBar.backgroundColor = .clear
        searchBar.searchTextField.backgroundColor = .white
        searchBar.delegate = self
        return searchBar
    }()
    private lazy var locateButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .white
        button.setImage(UIImage(named: "locateIcon")!, for: .normal)
        button.layer.cornerRadius = 56 / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(locateButtonTapped), for: .touchUpInside)
        button.isUserInteractionEnabled = true
        return button
    }()
    // Mapkit properties
    private var searchManager: YMKSearchManager?
    private var searchSession: YMKSearchSession?
    var setVisibleOn: Bool = true
    let scale = UIScreen.main.scale
    let mapKit = YMKMapKit.sharedInstance()
    lazy var userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup searchBar
        navigationItem.titleView = searchBar
        // setup locateButton
        tabBarController!.view.addSubview(locateButton)
        locateButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        locateButton.widthAnchor.constraint(equalToConstant: 56).isActive = true
        locateButton.bottomAnchor.constraint(equalTo: tabBarController!.view.safeAreaLayoutGuide.bottomAnchor, constant: -90).isActive = true
        locateButton.rightAnchor.constraint(equalTo: tabBarController!.view.rightAnchor, constant: -16).isActive = true
        // configureMapkit
        configureMapkitForSearching()
    }
    // MARK: - Functions
    private func configureMapkitForUserLocation() {
        // getting user location and moving map
        searchBar.text = nil
        mapView.mapWindow.map.isRotateGesturesEnabled = false
        userLocationLayer.setVisibleWithOn(setVisibleOn)
        setVisibleOn.toggle()
        userLocationLayer.isHeadingEnabled = true
        userLocationLayer.setAnchorWithAnchorNormal(
            CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.5 * mapView.frame.size.height * scale),
            anchorCourse: CGPoint(x: 0.5 * mapView.frame.size.width * scale, y: 0.83 * mapView.frame.size.height * scale))
        userLocationLayer.setObjectListenerWith(self)
    }
    private func configureMapkitForSearching() {
        // configuring map for searchign
        searchManager = YMKSearch.sharedInstance().createSearchManager(with: .combined)
        mapView.mapWindow.map.addCameraListener(with: self)
        mapView.mapWindow.map.addTapListener(with: self)
        mapView.mapWindow.map.addInputListener(with: self)
        mapView.mapWindow.map.move(with: YMKCameraPosition(
            target: YMKPoint(latitude: 59.945933, longitude: 30.320045),
            zoom: 14,
            azimuth: 0,
            tilt: 0))
    }
    @objc private func locateButtonTapped() {
        configureMapkitForUserLocation()
    }
    @objc private func showAddLocationView(with info: String) {
        if searchBar.text != "" {
            DispatchQueue.main.async {
                let addLocationVC = AddLocationController(infoTitle: info)
                addLocationVC.modalPresentationStyle = .custom
                addLocationVC.transitioningDelegate = self
                self.present(addLocationVC, animated: true, completion: nil)
            }
        }
    }
    private func showCustomView() {
        let slideVC = OverlayView()
        slideVC.modalPresentationStyle = .custom
        slideVC.transitioningDelegate = self
        slideVC.delegate = self
        self.present(slideVC, animated: true, completion: nil)
        slideVC.searchBar.becomeFirstResponder()
    }
}
// MARK: - UISearchBarDelegate
extension LocationController: UISearchBarDelegate {
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.resignFirstResponder()
        showCustomView()
        return false
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
}
// MARK: - Mapkit - UserLocation
extension LocationController: YMKUserLocationObjectListener {
    func onObjectAdded(with view: YMKUserLocationView) {
        view.arrow.setIconWith(UIImage(named:"UserArrow")!)
        
        let pinPlacemark = view.pin.useCompositeIcon()
        
        pinPlacemark.setIconWithName("locationIndicator",
            image: UIImage(named:"locationIndicator")!,
            style:YMKIconStyle(
                anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
                rotationType:YMKRotationType.rotate.rawValue as NSNumber,
                zIndex: 1,
                flat: true,
                visible: true,
                scale: 1,
                tappableArea: nil))

        view.accuracyCircle.fillColor = UIColor.blue
    }

    func onObjectRemoved(with view: YMKUserLocationView) {
        view.pin.useCompositeIcon().removeAll()
    }

    func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
}
// MARK: - Mapkit - Searching
extension LocationController: YMKMapCameraListener {
    func onCameraPositionChanged(with map: YMKMap, cameraPosition: YMKCameraPosition, cameraUpdateReason: YMKCameraUpdateReason, finished: Bool) {}
    func onSearchResponse(_ response: YMKSearchResponse) {}
    func onSearchError(_ error: Error) {
        let searchError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
        var errorMessage = "Unknown error"
        if searchError.isKind(of: YRTNetworkError.self) {
            errorMessage = "Network error"
        } else if searchError.isKind(of: YRTRemoteError.self) {
            errorMessage = "Remote server error"
        }
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
}
// MARK: - SearchDelegate
extension LocationController: SearchDelegate {
    func searchAndMoveMap(with text: String, info: String) {
        let responseHandler = {(searchResponse: YMKSearchResponse?, error: Error?) -> Void in
            if let response = searchResponse {
                updateUI(response: response)
            } else {
                self.onSearchError(error!)
            }
        }
        func updateUI(response: YMKSearchResponse) {
            let mapObjects = mapView.mapWindow.map.mapObjects
            mapObjects.clear()
            if let searchResult = response.collection.children.first {
                if let point = searchResult.obj?.geometry.first?.point {
                    mapView.mapWindow.map.move(with: YMKCameraPosition(
                        target: point,
                        zoom: 14,
                        azimuth: 0,
                        tilt: 0),
                                               animationType: YMKAnimation(type: YMKAnimationType.smooth, duration: 2))
                    let placemark = mapObjects.addPlacemark(with: point)
                    placemark.setIconWith(UIImage(named: "locationIndicator")!)
                }
            }
        }
        searchSession = searchManager!.submit(
            withText: text,
            geometry: YMKVisibleRegionUtils.toPolygon(with: mapView.mapWindow.map.visibleRegion),
            searchOptions: YMKSearchOptions(),
            responseHandler: responseHandler)
        // set searchBar's text
        searchBar.text = text
        // show AddLocationVC
        showAddLocationView(with: info)
    }
}
// MARK: - Mapkit
extension LocationController: YMKLayersGeoObjectTapListener, YMKMapInputListener {
    func onObjectTap(with: YMKGeoObjectTapEvent) -> Bool {
        let event = with
        let metadata = event.geoObject.metadataContainer.getItemOf(YMKGeoObjectSelectionMetadata.self)
        if let selectionMetadata = metadata as? YMKGeoObjectSelectionMetadata {
            mapView.mapWindow.map.selectGeoObject(withObjectId: selectionMetadata.id, layerId: selectionMetadata.layerId)
            return true
        }
        return false
    }
    
    func onMapTap(with map: YMKMap, point: YMKPoint) {
        mapView.mapWindow.map.deselectGeoObject()
    }
    
    func onMapLongTap(with map: YMKMap, point: YMKPoint) {
    }
}
// MARK: - UIViewControllerTransitionDelegate
extension LocationController: UIViewControllerTransitioningDelegate {
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        if searchBar.text == "" {
            return PresentationController(presentedViewController: presented, presenting: presenting)
        } else {
            return AddLocationPresentationController(presentedViewController: presented, presenting: presenting)
        }
    }
}

