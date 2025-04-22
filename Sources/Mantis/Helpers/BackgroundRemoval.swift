//
//  BackgroundRemoval 2.swift
//  Mantis
//
//  Created by Srujana Akula on 4/22/25.
//


import UIKit
import Vision
import CoreImage

/// Utility for removing background from images using Vision and CoreImage
public class BackgroundRemoval {
    /// Removes the background from the given image. Returns a new image with white background where the original background was.
    /// - Parameters:
    ///   - image: The UIImage to process
    ///   - completion: Completion handler with the processed image or error message
    public static func removeBackground(from image: UIImage, completion: @escaping (UIImage?, String?) -> Void) {
        guard #available(iOS 17.0, *) else {
            completion(nil, "Background removal requires iOS 17 or later.")
            return
        }
        
        guard let cgImage = image.cgImage else {
            completion(nil, "Invalid image.")
            return
        }
        
        let ciInput = CIImage(cgImage: cgImage)
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let mask = subjectMaskImage(from: ciInput) {
                let resultCI = apply(maskImage: mask, to: ciInput)
                let context = CIContext()
                if let cgResult = context.createCGImage(resultCI, from: resultCI.extent) {
                    let resultUIImage = UIImage(cgImage: cgResult, scale: image.scale, orientation: image.imageOrientation)
                    DispatchQueue.main.async {
                        completion(resultUIImage, nil)
                    }
                    return
                }
            }
            DispatchQueue.main.async {
                completion(nil, "Background removal failed.")
            }
        }
    }

    @available(iOS 17.0, *)
    private static func subjectMaskImage(from inputImage: CIImage) -> CIImage? {
        let handler = VNImageRequestHandler(ciImage: inputImage)
        let request = VNGenerateForegroundInstanceMaskRequest()
        do {
            try handler.perform([request])
        } catch {
            print("[BackgroundRemoval] Vision handler error: \(error)")
            return nil
        }
        guard let result = request.results?.first else {
            print("[BackgroundRemoval] No mask observations found")
            return nil
        }
        do {
            let maskPixelBuffer = try result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler)
            return CIImage(cvPixelBuffer: maskPixelBuffer)
        } catch {
            print("[BackgroundRemoval] Mask extraction error: \(error)")
            return nil
        }
    }

    private static func apply(maskImage: CIImage, to inputImage: CIImage) -> CIImage {
        let filter = CIFilter(name: "CIBlendWithMask")!
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        filter.setValue(maskImage, forKey: kCIInputMaskImageKey)
        // Use a white background (passport style)
        let whiteBackground = CIImage(color: .white).cropped(to: inputImage.extent)
        filter.setValue(whiteBackground, forKey: kCIInputBackgroundImageKey)
        return filter.outputImage!
    }
}
