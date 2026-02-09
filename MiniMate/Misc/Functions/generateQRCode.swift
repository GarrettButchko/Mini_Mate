//
//  generateQRCode.swift
//  MiniMate
//
//  Created by Garrett Butchko on 2/7/26.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

func generateQRCode(from string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    filter.message = Data(string.utf8)
    filter.correctionLevel = "M"

    if let outputImage = filter.outputImage {
        let scaledImage = outputImage.transformed(
            by: CGAffineTransform(scaleX: 10, y: 10)
        )

        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgImage)
        }
    }

    return UIImage(systemName: "xmark.circle")!
}
