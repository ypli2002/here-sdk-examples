/*
* Copyright (C) 2020-2023 HERE Europe B.V.
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
* SPDX-License-Identifier: Apache-2.0
* License-Filename: LICENSE
*/

import heresdk
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var viewFrame: UIView!
    @IBOutlet private weak var venueIdLoad: UIButton!
    @IBOutlet private weak var levelSwitcher: LevelSwitcher!
    @IBOutlet private weak var drawingSwitcher: DrawingSwitcher!
    @IBOutlet private weak var geometryNameLabel: UILabel!
    @IBOutlet private weak var venueSearch: VenueSearch!
    @IBOutlet private weak var indoorRoutingUIConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnDrop: UIButton!
    @IBOutlet weak var tblView: UITableView!
    
    var mapView: MapView!
    var mapScheme: MapScheme = .normalDay
    var venueEngine: VenueEngine!
    var moveToVenue: Bool = false
    var venueTapHandler: VenueTapHandler?
    var venueMapList = [String]()
    var selectedVenue : String!

    //Label text preference as per user choice
    var labelPref = ["OCCUPANT_NAMES", "SPACE_NAME", "INTERNAL_ADDRESS"]

    // Set value for hrn with your platform catalog HRN value if you want to load non default collection.
    var hrn: String = "YOUR_CATALOG_HRN"
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        mapView = MapView(frame: viewFrame.bounds)
        viewFrame.addSubview(mapView)

        venueIdLoad?.setTitle("loading...", for: .disabled)

        // Load the map scene using a map scheme to render the map with.
        mapView.mapScene.loadScene(mapScheme: MapScheme.normalDay, completion: onLoadScene)
        
        self.tblView.isHidden = true
    }

    @IBAction func onClickDropButton(_ sender: Any) {
        if tblView.isHidden {
            animate(toogle: true)
        } else {
            animate(toogle: false)
        }
    }
    
    func animate(toogle: Bool) {
        if toogle {
            UIView.animate(withDuration: 0.3) {
                self.tblView.isHidden = false
            }
        } else {
            UIView.animate(withDuration: 0.3) {
                self.tblView.isHidden = true
            }
        }
        
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        let venueMap = venueEngine.venueMap
        let venueService = venueEngine.venueService
        venueService.removeServiceDelegate(self)
        venueService.removeVenueDelegate(self)
        venueMap.removeVenueSelectionDelegate(self)
        mapView.gestures.tapDelegate = nil
        mapView.gestures.longPressDelegate = nil
    }

    // Completion handler when loading a map scene.
    private func onLoadScene(mapError: MapError?) {
        guard mapError == nil else {
            print("Error: Map scene not loaded, \(String(describing: mapError))")
            return
        }

        // Configure the map.
        let camera = mapView.camera
        camera.lookAt(point: GeoCoordinates(latitude: 52.553013, longitude: 13.292189, altitude: 500.0))
        // Hide the extruded building layer, so that it does not overlap with the venues.
        mapView.mapScene.disableFeatures([MapFeatures.extrudedBuildings])

        // Create a venue engine object. Once the initialization is done, a completion handler
        // will be called.
        do {
            try venueEngine = VenueEngine { [weak self] in self?.onVenueEngineInit() }
        } catch {
            print("SDK Engine not instantiated: \(error)")
        }
        
    }

    private func onVenueEngineInit() {
        // Get VenueService and VenueMap objects.
        let venueMap = venueEngine.venueMap
        let venueService = venueEngine.venueService

        // Add needed delegates.
        venueService.addServiceDelegate(self)
        venueService.addVenueDelegate(self)
        venueMap.addVenueSelectionDelegate(self)

        // Connect VenueMap to switchers, to control selected drawing and level in the UI.
        levelSwitcher.setVenueMap(venueMap)
        drawingSwitcher.setVenueMap(venueMap)

        // Create a venue tap handler and set it as default tap delegate.
        venueTapHandler = VenueTapHandler(venueEngine: venueEngine,
                                         mapView: mapView,
                                         geometryLabel: geometryNameLabel)
        venueSearch.setup(venueMap, tapHandler: venueTapHandler)
        mapView.gestures.tapDelegate = self

        // Start VenueEngine. Once authentication is done, the authentication completion handler
        // will be triggered. Afterwards, VenueEngine will start VenueService. Once VenueService
        // is initialized, VenueServiceListener.onInitializationCompleted method will be called.
        venueEngine.start(callback: {
            error, data in if let error = error {
                print("Failed to authenticate, reason: " + error.localizedDescription)
            }
        })
        if ((hrn != "") && (hrn != "YOUR_CATALOG_HRN"))
        {
            // Set platform catalog HRN
            venueService.setHrn(hrn: hrn)
        }
        
        // Set label text preference
        venueService.setLabeltextPreference(labelTextPref: labelPref)
    }

    // Touch handler for the button which selects venues by id.
    @IBAction private func loadVenue(_ sender: Any) {
        // Try to parse a venue id.
        if selectedVenue == nil {
            print("Error: No ID selected yet.")
            return
        }
        
        if let id = Int32(selectedVenue) {
            if (venueEngine?.venueService.isInitialized() ?? false) && (id != venueEngine?.venueMap.selectedVenue?.venueModel.id) {
                print("Loading venue \(id).")
                // Disable the input UI while a venue loading and selection is in progress.
                venueIdLoad?.isEnabled = false
                moveToVenue = true
                // Select a venue by id.
                venueEngine?.venueMap.selectVenueAsync(venueId: id, completion: self.onVenueLoadError)
            } else {
                print("Venue service is not initialized! Status: \(String(describing: venueEngine?.venueService.getInitStatus()))")
            }
        }
    }
    
    private func onVenueLoadError(_ error: VenueErrorCode?) {
        print("Error: \(String(describing: error))")
            var errorMessage: String
            switch error {
            case .noNetwork:
                errorMessage = "The device has no internet connectivity"
            case .noMetaDataFound:
                errorMessage = "Meta data not present in platform collection catalog"
            case .hrnMissing:
                errorMessage = "HRN not provided. Please insert HRN"
            case .hrnMismatch:
                errorMessage = "HRN does not match with Auth key & secret"
            case .noDefaultCollection:
                errorMessage = "Default collection missing from platform collection catalog"
            case .mapIdNotFound:
                errorMessage = "Map ID requested is not part of the default collection"
            case .mapDataIncorrect:
                errorMessage = "Map data in collection is wrong"
            case .internalServerError:
                errorMessage = "Internal Server Error"
            case .serviceUnavailable:
                errorMessage = "Requested service is not available currently. Please try after some time"
            case .noMapInCollection:
                errorMessage = "No maps available in the collection"
            default:
                errorMessage = "Unknown Error encountered"
            }
            // Create a new alert
            let dialogMessage = UIAlertController(title: "Attention", message: errorMessage, preferredStyle: .alert)
            // Create OK button with action handler
            let okk = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                print("Ok button tapped")
            })
            // Add OK button to a dialog message
            dialogMessage.addAction(okk)
            // Present Alert to
            self.present(dialogMessage, animated: true, completion: nil)
            venueIdLoad?.isEnabled = true
            viewWillDisappear(true)
        }

    @IBAction private func onSearchTap(_ sender: Any) {
        venueSearch.isHidden = !venueSearch.isHidden
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        mapView.handleLowMemory()
    }
}

// Tap delegate for MapView
extension ViewController: TapDelegate {
    public func onTap(origin: Point2D) {
            // Otherwise, redirect the event to the venue tap handler.
            venueTapHandler?.onTap(origin: origin)
    }
}

// Delegate for the VenueService event.
extension ViewController: VenueServiceDelegate {
    func onInitializationCompleted(result: VenueServiceInitStatus) {
        if (result == .onlineSuccess) {
            print("Venue Service successfully initialized.")
            var index: Int
            index = 0
            //Get List of venues info
            let venueInfo:[VenueInfo]? = venueEngine?.venueMap.getVenueInfoList(completion: self.onVenueLoadError)
            if let venueInfo = venueInfo {
              for venueInfo in venueInfo {
                  print("Venue Identifier: \(venueInfo.venueIdentifier)." + " Venue Id: \(venueInfo.venueId)." + " Venue Name: \(venueInfo.venueName).")
                  let venueIdStr = venueInfo.venueIdentifier
                  venueMapList.insert(String(venueIdStr.dropFirst(41)), at: index)
                  index = index+1
              }
                self.tblView.delegate = self
                self.tblView.dataSource = self
                self.tblView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
                self.view.addSubview(tblView)
            }
        } else {
            print("Venue Service failed to initialize!")
        }
    }

    func onVenueServiceStopped() {
        print("Venue Service has stopped.")
    }
}

// Delegate for the venue loading event.
extension ViewController: VenueDelegate {
    func onGetVenueCompleted(venueId: Int32, venueModel: VenueModel?, online: Bool, venueStyle: VenueStyle?) {
        if venueModel == nil {
            print("Loading of venue \(venueId) failed!")
            venueIdLoad?.isEnabled = true
        }
    }
}

// Delegate for the venue selection event.
extension ViewController: VenueSelectionDelegate {
    func onSelectedVenueChanged(deselectedVenue: Venue?, selectedVenue: Venue?) {
        if let venueModel = selectedVenue?.venueModel {
            if moveToVenue {
                // Move camera to the selected venue.
                mapView.camera.lookAt(point: venueModel.center)
                moveToVenue = false
            }
        }
        DispatchQueue.main.async {
            self.venueIdLoad?.isEnabled = true
        }
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venueMapList.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell =  tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = String(venueMapList[indexPath.row])
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        btnDrop.setTitle(venueMapList[indexPath.row], for: .normal)
        selectedVenue = venueMapList[indexPath.row]
        animate(toogle: false)
    }
}
