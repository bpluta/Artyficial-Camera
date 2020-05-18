//
//  CVPixelBuffer.swift
//  Artyficial Camera
//
//  Created by Bartłomiej Pluta on 17/05/2020.
//  Copyright © 2020 Bartłomiej Pluta. All rights reserved.
//

import CoreImage

extension CVPixelBuffer {
    func clamp() {
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)

        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let floatBuffer = unsafeBitCast(CVPixelBufferGetBaseAddress(self), to: UnsafeMutablePointer<Float>.self)

        for y in stride(from: 0, through: height, by: 1) {
            for x in stride(from: 0, to: width, by: 1) {
                let pixel = floatBuffer[y * width + x]
                floatBuffer[y * width + x] = min(1.0, max(pixel, 0.0))
            }
        }
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
    }
}
