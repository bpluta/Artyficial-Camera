//
//  FilterPickerItem.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import Foundation

struct FilterPickerItem {
    let name: String
    let imageName: String?
    let type: Filter
    
    static func ==(lhs: FilterPickerItem, rhs: FilterPickerItem) -> Bool {
        lhs.type == rhs.type
    }
    
    static func !=(lhs: FilterPickerItem, rhs: FilterPickerItem) -> Bool {
        lhs.type != rhs.type
    }
}
