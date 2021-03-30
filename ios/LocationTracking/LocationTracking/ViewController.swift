//
//  ViewController.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet fileprivate weak var lastLocationLabel: UILabel!
    @IBOutlet fileprivate weak var lastTrackingTimeLabel: UILabel!
    @IBOutlet fileprivate weak var locationRecordsTableView: UITableView!
    
    var records: [LocationData] {
        return LocalDataManager.shared.getListLocationData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configTableView()
        LocationManager.shared.startTrackLocationTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(newUserLocationDetected), name: .newUserLocation, object: nil)
        refreshUI()
    }
    
    fileprivate func configTableView() {
        locationRecordsTableView.delegate = self
        locationRecordsTableView.dataSource = self
        locationRecordsTableView.register(UINib(nibName: "RecordCell", bundle: nil), forCellReuseIdentifier: "RecordCell")
        locationRecordsTableView.tableFooterView = UIView()
    }
    
    @objc func newUserLocationDetected() {
        DispatchQueue.main.async { [weak self] in
            self?.refreshUI()
        }
    }
    
    fileprivate func refreshUI() {
        locationRecordsTableView.reloadData()
        if let lastLocation = records.first {
            lastLocationLabel.text = lastLocation.lastLocationDisplay
            lastTrackingTimeLabel.text = lastLocation.lastTimeDisplay
        }
    }
}
// MARK: - Actions
extension ViewController {
    
    @IBAction fileprivate func clearRecordsAction(_ sender: UIButton) {
        LocalDataManager.shared.removeAllListLocalLocationData()
        refreshUI()
    }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return records.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RecordCell", for: indexPath) as! RecordCell
        if 0..<records.count ~= indexPath.row {
            cell.record = records[indexPath.row]
        }
        cell.selectionStyle = .none
        cell.backgroundColor = indexPath.row % 2 == 0 ?
            UIColor.white : UIColor.lightGray.withAlphaComponent(0.3)
        return cell
    }
}

