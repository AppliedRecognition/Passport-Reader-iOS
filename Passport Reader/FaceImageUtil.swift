//
//  FaceImageUtil.swift
//  Passport Reader
//
//  Created by Jakub Dolejs on 12/08/2025.
//

import UIKit
import VerIDCommonTypes

struct FaceImageUtil {
    
    static func cropImage(_ image: Image, toFace face: Face) -> UIImage {
        let uiImage = UIImage(cgImage: image.toCGImage()!)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let edgeDist = [face.bounds.midX, face.bounds.midY, image.size.width - face.bounds.midX, image.size.height - face.bounds.midY].min()!
        let maxDim = min(max(face.bounds.width, face.bounds.height), edgeDist * 2)
        let size = CGSize(width: maxDim, height: maxDim)
        let x = face.bounds.midX - maxDim / 2
        let y = face.bounds.midY - maxDim / 2
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            uiImage.draw(at: CGPoint(x: 0 - x, y: 0 - y))
        }
    }
    
    static func cropImage(_ image: Image, toSquareCenteredAt centre: CGPoint) -> UIImage {
        let uiImage = UIImage(cgImage: image.toCGImage()!)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let halfSize = [centre.x, centre.y, CGFloat(image.width) - centre.x, CGFloat(image.height) - centre.y].min()!
        let x = centre.x - halfSize
        let y = centre.y - halfSize
        let size = CGSize(width: halfSize * 2, height: halfSize * 2)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            uiImage.draw(at: CGPoint(x: 0 - x, y: 0 - y))
        }
    }
}
