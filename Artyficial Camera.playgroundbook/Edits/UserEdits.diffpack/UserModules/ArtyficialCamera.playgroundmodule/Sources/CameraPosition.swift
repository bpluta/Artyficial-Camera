//
//  CameraPosition.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import AVFoundation

enum CameraPosition: CaseIterable {
    case front
    case back
    
    var position: AVCaptureDevice.Position {
        switch self {
        case .front:
            return .front
        case .back:
            return .back
        }
    }
}

