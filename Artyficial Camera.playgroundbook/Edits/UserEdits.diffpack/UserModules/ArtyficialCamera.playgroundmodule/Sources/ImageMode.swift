//
//  ImageMode.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import UIKit

enum ImageMode: CaseIterable {
    case whole
    case background
    case foreground
    
    var icon: UIImage {
        switch self {
        case .whole:
            return #imageLiteral(resourceName: "capture_full.png")
        case .background:
            return #imageLiteral(resourceName: "capture_background.png")
        case .foreground:
            return #imageLiteral(resourceName: "capture_foreground.png")
        }
    }
}
