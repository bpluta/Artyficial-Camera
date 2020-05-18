//
//  Filter.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import CoreML
import CoreImage

enum Filter: CaseIterable {
    case none
    case night
    case stainedglass
    case roof
    
    var pickerItemData: FilterPickerItem {
        switch self {
        case .none:
            return FilterPickerItem(name: "No filter", imageName: nil, type: self)
        case .night:
            return FilterPickerItem(name: "Nocturnal", imageName: "night", type: self)
        case .stainedglass:
            return FilterPickerItem(name: "Stained", imageName: "stainedglass", type: self)
        case .roof:
            return FilterPickerItem(name: "Roof", imageName: "roof", type: self)
        }
    }
    
    private static let styleArray: MLMultiArray = {
        let styleArray = try? MLMultiArray(shape: [1], dataType: .double)
        styleArray?[0] = 1.0
        return styleArray!
    }()
    
    func apply(to buffer: CVImageBuffer) -> CIImage {
        guard self != .none else {
            return CIImage(cvImageBuffer: buffer)
        }
        var output: CVPixelBuffer?
        switch self {
        case .night:
            output = try? NightStyle().prediction(image: buffer, index: Self.styleArray).stylizedImage
        case .stainedglass:
            output = try? StainedGlassStyle().prediction(image: buffer, index: Self.styleArray).stylizedImage
        case .roof:
            output = try? RoofStyle().prediction(image: buffer, index: Self.styleArray).stylizedImage
        default:
            output = nil
        }
        return CIImage(cvImageBuffer: output!)
    }
}
