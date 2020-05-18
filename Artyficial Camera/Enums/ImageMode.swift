//
//  ImageMode.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import Foundation

enum ImageMode: CaseIterable {
    case whole
    case background
    case foreground
    
    var icon: String {
        switch self {
        case .whole:
            return "capture_full"
        case .background:
            return "capture_background"
        case .foreground:
            return "capture_foreground"
        }
    }
}
