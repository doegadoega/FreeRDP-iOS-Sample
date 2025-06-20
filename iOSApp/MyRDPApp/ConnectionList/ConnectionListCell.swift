//
//  ConnectionListCell.swift
//  MyRDPApp
//
//  Created by Hiroshi Egami on 2025/06/19.
//

import UIKit

class ConnectionListCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel! {
        didSet {
            self.nameLabel.text = ""
        }
    }
    
    @IBOutlet weak var hostNameLabel: UILabel! {
        didSet {
            self.hostNameLabel.text = ""
        }
    }
    
    private var connection: RDPConnection?
    
    func update(connection: RDPConnection?) {
        guard let model = connection
        else {
            return
        }
        
        self.nameLabel.text = model.name
        self.hostNameLabel.text = model.host
        
        self.connection = model
    }
}
