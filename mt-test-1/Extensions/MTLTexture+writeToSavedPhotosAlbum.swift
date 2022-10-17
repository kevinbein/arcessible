//
//  MTLTexture+saveImage.swift
//  mt-test-1
//
//  Created by Kevin Bein on 06.09.22.
//

import Metal
import Accelerate
import CoreGraphics
import ImageIO
import MobileCoreServices
import UIKit

extension MTLTexture {
    fileprivate func makeImage(for texture: MTLTexture) -> CGImage? {
        debugPrint(texture.pixelFormat)
        debugPrint(texture.pixelFormat.rawValue)
        //assert(texture.pixelFormat == .bgra8Unorm)
        assert(texture.pixelFormat == .bgra8Unorm_srgb)

        let width = texture.width
        let height = texture.height
        let pixelByteCount = 4 * MemoryLayout<UInt8>.size
        let imageBytesPerRow = width * pixelByteCount
        let imageByteCount = imageBytesPerRow * height
        let imageBytes = UnsafeMutableRawPointer.allocate(byteCount: imageByteCount, alignment: pixelByteCount)
        defer {
            imageBytes.deallocate()
        }

        texture.getBytes(imageBytes,
                         bytesPerRow: imageBytesPerRow,
                         from: MTLRegionMake2D(0, 0, width, height),
                         mipmapLevel: 0)

        swizzleBGRA8toRGBA8(imageBytes, width: width, height: height)

        //guard let colorSpace = CGColorSpace(name: CGColorSpace.linearSRGB) else { return nil }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return nil }
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        guard let bitmapContext = CGContext(data: nil,
                                            width: width,
                                            height: height,
                                            bitsPerComponent: 8,
                                            bytesPerRow: imageBytesPerRow,
                                            space: colorSpace,
                                            bitmapInfo: bitmapInfo) else { return nil }
        bitmapContext.data?.copyMemory(from: imageBytes, byteCount: imageByteCount)
        let image = bitmapContext.makeImage()
        return image
    }
    
    fileprivate func swizzleBGRA8toRGBA8(_ bytes: UnsafeMutableRawPointer, width: Int, height: Int) {
        var sourceBuffer = vImage_Buffer(data: bytes,
                                         height: vImagePixelCount(height),
                                         width: vImagePixelCount(width),
                                         rowBytes: width * 4)
        var destBuffer = vImage_Buffer(data: bytes,
                                       height: vImagePixelCount(height),
                                       width: vImagePixelCount(width),
                                       rowBytes: width * 4)
        var swizzleMask: [UInt8] = [ 2, 1, 0, 3 ] // BGRA -> RGBA
        vImagePermuteChannels_ARGB8888(&sourceBuffer, &destBuffer, &swizzleMask, vImage_Flags(kvImageNoFlags))
    }
    
    func writeToSavedPhotosAlbum() {
        let texture = self
        guard let image = makeImage(for: texture) else { return }

        let uiimage = UIImage(cgImage: image)
        UIImageWriteToSavedPhotosAlbum(uiimage, nil, nil, nil)
    }
    
    func saveImage() {
        let texture = self
        
        let width = texture.width
        let height = texture.height
        let bytesPerRow = width * 4

        let data = UnsafeMutableRawPointer.allocate(byteCount: bytesPerRow * height, alignment: 4)
        defer {
            data.deallocate()
        }

        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(data, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)

        var buffer = vImage_Buffer(data: data, height: UInt(height), width: UInt(width), rowBytes: bytesPerRow)

        let map: [UInt8] = [2, 1, 0, 3]
        vImagePermuteChannels_ARGB8888(&buffer, &buffer, map, 0)

        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) else { return }
        guard let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                      space: colorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
        guard let cgImage = context.makeImage() else { return }

        let uiimage = UIImage(cgImage: cgImage)
        UIImageWriteToSavedPhotosAlbum(uiimage, nil, nil, nil)
    }
}
