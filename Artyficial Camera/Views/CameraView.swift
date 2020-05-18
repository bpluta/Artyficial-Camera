//
//  CameraView.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 16/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import SwiftUI

public struct CameraView: View {
    private let headerHeight: CGFloat = 60
    private let footerHeight: CGFloat = 180
    private let aspectRatio: CGFloat = 4/3
    
    private let camera = CameraCaptureView()
    
    @ObservedObject var viewModel = CameraViewModel()
    
    public init() {
        setupRotationChangeHandler()
    }
    
    public var body: some View {
        GeometryReader { metrics in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VStack {
                    self.cameraPreview(width: metrics.size.width, height: metrics.size.height)
                    Spacer()
                }
                VStack {
                    self.header
                    Spacer()
                    self.footer(width: metrics.size.width)
                }
            }
        }.onReceive(self.viewModel.$selectedFilter, perform: { _ in
            self.changeFilter()
        })
    }
    
    private var header: some View {
        VStack {
            HStack {
                if self.viewModel.shouldDisplayReturnToCaptureModeButton {
                    self.returnToCaptureModeButton
                    Spacer()
                }
                if self.viewModel.shouldDisplaySwitchImageModeButton {
                    self.switchImageModeButton
                }
                if self.viewModel.shouldDisplayDepthInfo {
                    Spacer()
                    Text("Depth data is captured only with no filter applied")
                        .foregroundColor(.white)
                        .font(.caption)
                        .fontWeight(.regular)
                }
                if self.viewModel.shouldDisplaySwitchCameraButton {
                    Spacer()
                    self.switchCamerasButton
                }
                if self.viewModel.shouldDisplaySaveImageButton {
                    Spacer()
                    self.saveImageButton
                }
            }
            .padding(20)
            .frame(height: self.headerHeight)
        }.background(Color.black)
    }
    
    private func footer(width: CGFloat) -> some View {
        VStack {
            Spacer()
            if self.viewModel.shouldDisplaySlider {
                Slider(value: self.$viewModel.maskingIntensity, in: 0.3...1.0, onEditingChanged: { isDragging in
                    if !isDragging {
                        self.changeMaskingIntensity()
                    }
                })
                .frame(height: 30)
                .padding(.horizontal, 20)
            }
            self.filterPicker(width: width)
            if self.viewModel.shouldDisplayCameraCaptureButton {
                self.captureButton
            }
            Spacer()
        }.background(Color.black)
        .frame(height: self.footerHeight)
    }
    
    private func cameraPreview(width: CGFloat, height: CGFloat) -> some View {
        let previewSize = getCameraPreviewSize(width: width, height: height, aspectRatio: self.aspectRatio)
        return
            camera
                .frame(
                    width: previewSize.width, height: previewSize.height
            )
            .padding(
                .top,
                self.getCameraOutputOffset(screenHeight: height, cameraOutputSize: previewSize)
            ).clipped()
    }
    
    private func filterPicker(width: CGFloat) -> some View {
        FilterPickerView(
            withImage: self.$viewModel.shouldDisplayFilterImages,
            filterPickerDelegate: self.viewModel,
            filters: Filter.allCases)
                .background(Color.black)
                .frame(width: width, alignment: .center)
    }
    
    private var captureButton: some View {
        HStack {
            Spacer()
            Button(action: self.takePhoto) {
                Circle()
                .fill(Color.white)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 5)
                        .padding(-5)
                )
                .padding(8)
                .frame(width: 70, height: 70, alignment: .center)
            }
            Spacer()
        }
        .padding(20)
    }
    
    private var returnToCaptureModeButton: some View {
        Button(action: {
            self.backToCaptureMode()
        }) {
            HStack {
                Image("back_arrow")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.white)
                    .frame(width: 12, height: 30)
                Text("Back")
                    .foregroundColor(.white)
            }
        }
    }
    
    private var saveImageButton: some View {
        Button(action: {
            self.saveImage()
        }) {
            Text("Save")
                .foregroundColor(.white)
        }
    }
    
    private var switchCamerasButton: some View {
        Button(action: {
            self.changeCamera()
        }) {
            Image("change_camera")
               .renderingMode(.template)
               .resizable()
               .scaledToFit()
               .foregroundColor(Color.white)
               .frame(width: 30, height: 30)
        }
    }
    
    private var switchImageModeButton: some View {
        Button(action: {
            self.changeImageMode()
        }) {
            Image(self.viewModel.imageProcessingMode.icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .foregroundColor(Color.white)
                .frame(width: 30, height: 30)
        }
    }
    
    private func getCameraOutputOffset(screenHeight: CGFloat, cameraOutputSize: CGSize) -> CGFloat {
        headerHeight + (screenHeight - (headerHeight + footerHeight) - cameraOutputSize.height) / 2
    }
    
    private func getCameraPreviewSize(width: CGFloat, height: CGFloat, aspectRatio: CGFloat) -> CGSize {
        let previewAspectRatio = aspectRatio
        let offsetFromTop = headerHeight
        let canvasHeight = height - offsetFromTop
        let canvasWidth = width
        let canvasRatio = canvasHeight / canvasWidth
        
        var previewHeight = height
        var previewWidth = width
        
        if canvasRatio > previewAspectRatio {
            previewWidth = canvasWidth
            previewHeight = previewWidth * previewAspectRatio
        } else {
            previewWidth = canvasHeight > canvasWidth ? canvasWidth : canvasHeight
            previewHeight = previewWidth / previewAspectRatio
        }
        return CGSize(width: previewWidth, height: previewHeight)
    }
    
    private func saveImage() {
        camera.saveImage()
    }
    
    private func backToCaptureMode() {
        viewModel.mode = .capture
        camera.restartSession()
    }
    
    private func takePhoto() {
        viewModel.isDepthDataAvailable = false
        viewModel.mode = .edit
        camera.takePhoto()
        viewModel.isDepthDataAvailable = camera.isDepthDataAvailable
    }
    
    private func changeCamera() {
        viewModel.changeCameraPosition()
        camera.switchCamera(to: viewModel.cameraPosition)
    }
    
    private func changeImageMode() {
        viewModel.changeImageProcessingMode()
        camera.setImageMode(to: viewModel.imageProcessingMode)
        changeMaskingIntensity()
    }
    
    private func changeFilter() {
        camera.changeFilter(to: viewModel.selectedFilter.type)
    }
    
    private func changeMaskingIntensity() {
        camera.setMaskingIntensity(to: viewModel.maskingIntensity)
    }
    
    private func setupRotationChangeHandler() {
        NotificationCenter.default.addObserver(camera.cameraDelegate, selector: #selector(camera.cameraDelegate.handleDeviceOrientationChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
}

#if DEBUG
struct CameraView_Previews: PreviewProvider {
    static var previews: some View {
        CameraView()
    }
}
#endif
