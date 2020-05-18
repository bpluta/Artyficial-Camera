//
//  CameraSetupError.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import Foundation

enum CameraSetupError: Error {
    case noCameraAvailable
    case cannotAddInputToSession
    case cannotAddOutputToSession

    var localizedDescription: String {
        switch self {
        case .noCameraAvailable:
            return "There is no camera available"
        case .cannotAddInputToSession:
            return "Device input could not be added to capture session"
        case .cannotAddOutputToSession:
            return "Device output could not be added to capture session"
        }
    }
}
