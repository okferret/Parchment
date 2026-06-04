//
//  ChapterTableViewCell.swift
//  Parchment
//
//  Created by okferret on 2026/6/4.
//

#if canImport(UIKit)

import UIKit

/// ChapterTableViewCell
class ChapterTableViewCell: UITableViewCell {
    
    /// ChapterTableViewCell
    internal static var reusedID: String { "ChapterTableViewCell" }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}

#endif
