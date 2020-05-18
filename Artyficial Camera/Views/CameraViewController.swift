//
//  CameraViewController.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 14/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import UIKit
import SwiftUI
import AVFoundation
import Photos

final class CameraViewController: UIViewController {
    var previewView: UIImageView!
    
    var session: AVCaptureSession!
    var stillImageOutput: AVCapturePhotoOutput!
    
    var videoDeviceInput: AVCaptureDeviceInput!
    var videoDeviceOutput: AVCaptureVideoDataOutput!
    var depthDeviceOutput: AVCaptureDepthDataOutput!
    
    var rawCameraCapture: CVImageBuffer!
    var depthData: AVDepthData?
    
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let dataOutputQueue = DispatchQueue(label: "dataOutputQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)
    
    fileprivate(set) var setupStatus: CameraSetupStatus = .success
    fileprivate(set) var cameraPosition: CameraPosition = .front
    fileprivate(set) var imageMode: ImageMode = .whole
    fileprivate(set) var filter: Filter = .none
    fileprivate(set) var imageOrientation: AVCaptureVideoOrientation = .portrait
    
    fileprivate(set) var maskingIntensity: CGFloat = 0.0
    fileprivate(set) var maskScale: CGFloat = 0.0
    
    private var hasBeenInitialized = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handlePermissions()
        
        setupView()
        setupCamera()
        
        buildView()
        buildCameraPreview()
    }
}

// MARK: -Setup
extension CameraViewController {
    private func setupView() {
        setupCameraPreview()
    }
    
    private func setupCamera() {
        sessionQueue.sync {
            self.configureCaptureSession()
        }
        self.handleSetupStatus()
    }
    
    private func buildView() {
        buildCameraPreview()
    }
    
    private func setupCameraPreview() {
        previewView = UIImageView(frame: .zero)
    }
    
    private func buildCameraPreview() {
        view.addSubview(previewView)
        previewView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addConstraint(previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor))
        view.addConstraint(previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor))
        view.addConstraint(previewView.topAnchor.constraint(equalTo: view.topAnchor))
        view.addConstraint(previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor))
    }
    
    private func handleSetupStatus() {
        switch setupStatus {
        case .success:
            handleSetupSuccess()
        case .notAuthorized:
            handleNotAuthorized()
        case .failure:
            handleFailure()
        }
    }
    
    private func handleSetupSuccess() {
        hasBeenInitialized = true
        session.startRunning()
    }
    
    private func handleNotAuthorized() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Permission not granted",
                message: "App does not have permission to use camera. In order to change this, please go to privacy settings.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func handleFailure() {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Oops.. Something went wrong",
                message: "Some error occured during process of camera configuration. Please try again.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func handlePermissions() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { [weak self] granted in
                if !granted {
                    self?.setupStatus = .notAuthorized
                }
            })
        default:
            self.setupStatus = .notAuthorized
        }
    }
    
    private func configureCaptureSession() {
        guard setupStatus == .success else { return }

        session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .vga640x480
        do {
            let deviceInput = try configureDevice(session: session)
            try configureSessionInput(session: session, input: deviceInput)
            try configureSessionOutput(session: session)
        } catch {
            print(error.localizedDescription)
            setupStatus = .failure
        }
        session.commitConfiguration()
        updateOrientation()
    }
    
    private func configureDevice(session: AVCaptureSession) throws -> AVCaptureDeviceInput {
        guard let device = getCameraDevice(for: cameraPosition) else {
            throw CameraSetupError.noCameraAvailable
        }
        return try AVCaptureDeviceInput(device: device)
    }
    
    private func configureSessionInput(session: AVCaptureSession, input: AVCaptureDeviceInput) throws {
        if session.canAddInput(input) {
            session.addInput(input)
            videoDeviceInput = input
        } else {
            throw CameraSetupError.cannotAddInputToSession
        }
    }
    
    private func configureSessionOutput(session: AVCaptureSession) throws {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: dataOutputQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
            
            let videoConnection = output.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            
            videoDeviceOutput = output
            setupDepthOutput()
        } else {
            throw CameraSetupError.cannotAddOutputToSession
        }
    }
    
    private func setupDepthOutput() {
        guard let imageOutput = videoDeviceOutput else { return }
        if depthDeviceOutput != nil {
            session.removeOutput(depthDeviceOutput)
        }
        
        let depthOutput = AVCaptureDepthDataOutput()
        depthOutput.setDelegate(self, callbackQueue: dataOutputQueue)
        depthOutput.isFilteringEnabled = true
        
        depthOutput.connection(with: .depthData)?.isEnabled = true

        depthDeviceOutput = depthOutput
        session.addOutput(depthOutput)
        
        let outputRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        let videoRect = imageOutput.outputRectConverted(fromMetadataOutputRect: outputRect)
        let depthRect = depthOutput.outputRectConverted(fromMetadataOutputRect: outputRect)

        maskScale = max(videoRect.width, videoRect.height) / max(depthRect.width, depthRect.height)
        
        let depthConnection = depthOutput.connection(with: .depthData)
        depthConnection?.videoOrientation = .portrait
    }
}

// MARK: -Actions
extension CameraViewController {
    func switchCamera(to newPosition: CameraPosition) {
        sessionQueue.async {
            let currentDevice = self.videoDeviceInput.device
            let currentPosition = currentDevice.position
            guard currentPosition != newPosition.position else { return }
            
            guard let newDevice = self.getCameraDevice(for: newPosition),
                let newDeviceInput = try? AVCaptureDeviceInput(device: newDevice) else { return }
            
            self.session.beginConfiguration()
            
            self.session.removeInput(self.videoDeviceInput)
            if self.session.canAddInput(newDeviceInput) {
                self.session.addInput(newDeviceInput)
                self.videoDeviceInput = newDeviceInput
            } else {
                self.session.addInput(self.videoDeviceInput)
            }
            self.setupDepthOutput()
            let videoConnection = self.videoDeviceOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
            self.depthData = nil
            self.session.commitConfiguration()
        }
    }
    
    func takePhoto() {
        sessionQueue.async {
            if self.session.isRunning {
                self.session.stopRunning()
            } else {
                self.session.startRunning()
            }
        }
    }
    
    func restartSession() {
        depthData = nil
        sessionQueue.async {
            self.session.beginConfiguration()
            self.setupDepthOutput()
            self.session.commitConfiguration()
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }
    
    func changeFilter(to filter: Filter) {
        self.filter = filter
        if !session.isRunning && rawCameraCapture != nil {
            let filteredImage = applyFilter(to: self.rawCameraCapture)
            DispatchQueue.main.async {
                self.previewView.image = UIImage(ciImage: filteredImage)
            }
        }
    }
    
    func changeImageMode(to mode: ImageMode) {
        guard mode != imageMode else { return }
        if mode != .whole && session.isRunning {
            imageMode = .whole
        } else {
            imageMode = mode
        }
        let filteredImage = applyFilter(to: rawCameraCapture)
        DispatchQueue.main.async {
            self.previewView.image = UIImage(ciImage: filteredImage)
        }
    }
    
    func setMaskingIntensity(to value: CGFloat) {
        maskingIntensity = value
        guard !session.isRunning && hasBeenInitialized else { return }
        let filteredImage = applyFilter(to: rawCameraCapture)
        DispatchQueue.main.async {
            self.previewView.image = UIImage(ciImage: filteredImage)
        }
    }
    
    func saveImage() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            if status == .authorized {
                DispatchQueue.main.async {
                    let context = CIContext(options: [CIContextOption.useSoftwareRenderer:true])
                    guard let imageToSave = self?.previewView.image?.ciImage else { return }
                    guard let cgImage = context.createCGImage(imageToSave, from: imageToSave.extent) else { return }
                    let image = UIImage(cgImage: cgImage)
                    UIImageWriteToSavedPhotosAlbum(image, self, #selector(self?.saveError), nil)
                }
            } else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(
                        title: "Permission not granted",
                        message: "App does not have permission to use photo library.",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let _ = error {
            let alert = UIAlertController(
                title: "Error",
                message: "Image could not be saved",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(
                title: "Image Saved",
                message: "Image has been saved to Your library",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
        }
    }
    
    @objc func handleDeviceOrientationChange() {
        switch UIDevice.current.orientation {
        case .portrait, .faceUp:
            imageOrientation = .portrait
        case .landscapeLeft:
            imageOrientation = .landscapeRight
        case .landscapeRight:
            imageOrientation = .landscapeLeft
        case .portraitUpsideDown, .faceDown:
            imageOrientation = .portraitUpsideDown
        default:
            break
        }
        updateOrientation()
    }
    
    private func updateOrientation() {
        videoDeviceOutput?.connection(with: .video)?.videoOrientation = imageOrientation
        depthDeviceOutput?.connection(with: .depthData)?.videoOrientation = imageOrientation
        videoDeviceOutput?.connection(with: .video)?.isVideoMirrored = true
        depthDeviceOutput?.connection(with: .depthData)?.isVideoMirrored = true
    }
}


// MARK: -Camera Utils
extension CameraViewController {
    fileprivate func getCameraDevice(for position: CameraPosition) -> AVCaptureDevice? {
        switch position {
        case .back:
            if let device = getRearCameraDevice() {
                return device
            }
            return getFrontCameraDevice()
        case .front:
            if let device = getFrontCameraDevice() {
                return device
            }
            return getRearCameraDevice()
        }
    }
    
    private func getFrontCameraDevice() -> AVCaptureDevice? {
        if let trueDepthCamera = AVCaptureDevice.default(.builtInTrueDepthCamera, for: .video, position: .front) {
            return trueDepthCamera
        }
        if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
            return wideAngleCamera
        }
        return nil
    }
    
    private func getRearCameraDevice() -> AVCaptureDevice? {
        if let dualCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return dualCamera
        }
        if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return wideAngleCamera
        }
        return nil
    }
}


// MARK: -Filtering
extension CameraViewController {
    func applyFilter(to buffer: CVPixelBuffer) -> CIImage {
        guard !session.isRunning || imageMode == .whole else {
            return filter.apply(to: buffer)
        }
        let filteredImage = filter.apply(to: buffer)
        let originalImage = CIImage(cvImageBuffer: rawCameraCapture)
        if let mask = getDepthMask() {
            switch imageMode {
            case .background:
                return getForegroundMaskedImage(from: originalImage, to: filteredImage, mask: mask)
            case .foreground:
                return getBackgroundMaskedImage(from: originalImage, to: filteredImage, mask: mask)
            default:
                return filter.apply(to: buffer)
            }
        }
        return filteredImage
    }
    
     fileprivate func getForegroundMaskedImage(from originalImage: CIImage, to filteredImage: CIImage, mask: CIImage) -> CIImage {
        filteredImage.applyingFilter("CIBlendWithMask", parameters: [
          "inputMaskImage": mask,
          "inputBackgroundImage": originalImage,
          "inputImage": filteredImage
        ])
    }
    
     fileprivate func getBackgroundMaskedImage(from originalImage: CIImage, to filteredImage: CIImage, mask: CIImage) -> CIImage {
        originalImage.applyingFilter("CIBlendWithMask", parameters: [
          "inputMaskImage": mask,
          "inputBackgroundImage": filteredImage,
          "inputImage": originalImage
        ])
    }
    
     fileprivate func getDepthMask() -> CIImage? {
        guard let depthData = depthData else { return nil }
        var convertedDepth: AVDepthData
        let depthDataType = kCVPixelFormatType_DepthFloat32
        if depthData.depthDataType != depthDataType {
            convertedDepth = depthData.converting(toDepthDataType: depthDataType)
        } else {
            convertedDepth = depthData
        }
        let pixelBuffer = convertedDepth.depthDataMap
        pixelBuffer.clamp()

        let depthMap = CIImage(cvPixelBuffer: pixelBuffer)
        
        return getHighPassMask(for: depthMap)
    }
    
    fileprivate func getHighPassMask(for depthImage: CIImage) -> CIImage {
        let slope: CGFloat = 3.0
        let width: CGFloat = 0.1
        let filterWidth =  2 / slope + width
        let bias = -slope * (maskingIntensity - filterWidth / 2)
        
        let mask = depthImage
            .applyingFilter("CIColorMatrix", parameters: [
                "inputRVector": CIVector(x: slope, y: 0, z: 0, w: 0),
                "inputGVector": CIVector(x: 0, y: slope, z: 0, w: 0),
                "inputBVector": CIVector(x: 0, y: 0, z: slope, w: 0),
                "inputBiasVector": CIVector(x: bias, y: bias, z: bias, w: 0)
            ])
            .applyingFilter("CIColorClamp")
            .applyingFilter("CIBicubicScaleTransform", parameters: [
                "inputScale": maskScale
            ])
        return mask
    }
}

// MARK: -Image Capture
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        processCapture(sampleBuffer)
    }
    
    private func processCapture(_ sampleBuffer: CMSampleBuffer) {
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        rawCameraCapture = pixelBuffer
        let filteredImage = applyFilter(to: pixelBuffer)
        DispatchQueue.main.async {
            self.previewView.image = UIImage(ciImage: filteredImage)
        }
    }
}

// MARK: -Depth Data Capture
extension CameraViewController: AVCaptureDepthDataOutputDelegate {
    public func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        processDepth(depthData)
    }
    
    private func processDepth(_ depthData: AVDepthData) {
        DispatchQueue.main.async {
            self.depthData = depthData
        }
    }
}

struct CameraCaptureView: UIViewControllerRepresentable {
    typealias UIViewControllerType = CameraViewController
    
    var cameraDelegate = CameraViewController()
    
    func makeUIViewController(context: Context) -> CameraViewController {
        return cameraDelegate
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
    }
    
    func takePhoto() {
        cameraDelegate.takePhoto()
    }
    
    func restartSession() {
        cameraDelegate.restartSession()
    }
    
    func switchCamera(to position: CameraPosition) {
        cameraDelegate.switchCamera(to: position)
    }
    
    func changeFilter(to filter: Filter) {
        cameraDelegate.changeFilter(to: filter)
    }
    
    func setImageMode(to mode: ImageMode) {
        cameraDelegate.changeImageMode(to: mode)
    }
    
    func setMaskingIntensity(to value: CGFloat) {
        cameraDelegate.setMaskingIntensity(to: value)
    }
    
    func saveImage() {
        cameraDelegate.saveImage()
    }
    
    var isDepthDataAvailable: Bool {
        cameraDelegate.depthData != nil
    }
}
