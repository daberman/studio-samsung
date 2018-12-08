//
//  BTPeripheralTableViewCell.swift
//  SmartTable
//
//  Created by Dan Berman on 12/7/18.
//  Copyright © 2018 Dan Berman. All rights reserved.
//

import UIKit

class BTPeripheralTableViewCell: UITableViewCell {

    @IBOutlet weak var peripheralNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
