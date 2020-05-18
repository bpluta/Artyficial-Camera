//
//  CameraViewModel.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 16/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import UIKit

class CameraViewModel: ObservableObject {
    
    @Published var selectedFilter: FilterPickerItem
    @Published var imageProcessingMode: ImageMode
    @Published var cameraPosition: CameraPosition
    
    @Published var maskingIntensity: CGFloat = 0.7
    
    @Published var shouldDisplayFilterImages: Bool = false
    @Published var shouldDisplaySwitchCameraButton: Bool = false
    @Published var shouldDisplaySwitchImageModeButton: Bool = false
    @Published var shouldDisplayCameraCaptureButton: Bool = false
    @Published var shouldDisplayReturnToCaptureModeButton: Bool = false
    @Published var shouldDisplaySaveImageButton: Bool = false
    @Published var shouldDisplaySlider: Bool = false
    @Published var shouldDisplayDepthInfo: Bool = false
    
    @Published var availableFilters: [FilterPickerItem] {
        willSet {
            newValue.forEach { currentItem in
                if newValue.contains(where: { $0 == currentItem }) {
                    assertionFailure("Filter data list contains non unique filter types")
                }
            }
        }
    }
    
    @Published var mode: CameraViewMode {
        didSet {
            displayComponents(of: mode)
        }
    }
    
    var isDepthDataAvailable: Bool = false {
        didSet {
            displayComponents(of: mode)
        }
    }
    
    private var isSliderSupported: Bool {
        isDepthDataAvailable &&
            mode == .edit &&
            imageProcessingMode != .whole &&
            selectedFilter.type != .none
    }
    
    init() {
        assert(!Filter.allCases.isEmpty, "There should be at least one filter provided")
        selectedFilter = Filter.allCases.first!.pickerItemData
        availableFilters = Filter.allCases.map { $0.pickerItemData }
        cameraPosition = .front
        imageProcessingMode = .whole
        mode = .capture
        displayComponents(of: mode)
    }
    
    private func displayComponents(of mode: CameraViewMode) {
        switch mode {
        case .capture:
            shouldDisplayFilterImages = false
            shouldDisplaySwitchCameraButton = true
            shouldDisplaySwitchImageModeButton = false
            shouldDisplayCameraCaptureButton = true
            shouldDisplayReturnToCaptureModeButton = false
            shouldDisplaySaveImageButton = false
            shouldDisplaySlider = isSliderSupported
            shouldDisplayDepthInfo = selectedFilter.type != .none
        case .edit:
            shouldDisplayFilterImages = true
            shouldDisplaySwitchCameraButton = false
            shouldDisplaySwitchImageModeButton = isDepthDataAvailable
            shouldDisplayCameraCaptureButton = false
            shouldDisplayReturnToCaptureModeButton = true
            shouldDisplaySaveImageButton = true
            shouldDisplaySlider = isSliderSupported
            shouldDisplayDepthInfo = false
        }
    }
    
    func changeCameraPosition() {
        let allCases = CameraPosition.allCases
        let currentElementIndex = allCases.firstIndex(where: { $0 == cameraPosition })
        cameraPosition = allCases[(currentElementIndex! + 1) % allCases.count]
    }
    
    func changeImageProcessingMode() {
        let allCases = ImageMode.allCases
        let currentElementIndex = allCases.firstIndex(where: { $0 == imageProcessingMode })
        imageProcessingMode = allCases[(currentElementIndex! + 1) % allCases.count]
        shouldDisplaySlider = isSliderSupported
    }
}

extension CameraViewModel: FilterPickerDelegate {
    func selectFilter(filter: FilterPickerItem) {
        guard availableFilters.contains(where: { $0 == filter }) else { return }
        if filter != selectedFilter {
            selectedFilter = filter
            shouldDisplaySlider = isSliderSupported
            shouldDisplayDepthInfo = mode == .capture && selectedFilter.type != .none
        }
        return
    }
}
