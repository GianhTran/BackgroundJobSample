//
//  RecordCell.swift
//  LocationTracking
//
//  Created by Le Tuan on 29/3/21.
//

import UIKit

class RecordCell: UITableViewCell {

    @IBOutlet fileprivate weak var locationLabel: UILabel!
    @IBOutlet fileprivate weak var trackingTimeLabel: UILabel!
    
    var record: LocationData? {
        didSet {
            locationLabel.text = String(format: "Location: %@", record?.locationDisplay ?? "")
            trackingTimeLabel.text = record?.timeDisplay
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
