//
//  UIImage+Extension.swift
//  PhotoLibraryExample
//
//  Created by Sakdinan Sukkhasem on 18/12/20.
//

import UIKit

extension UIImage {
    static func randomImageColor() -> UIImage {
        let size = CGSize(width: 500, height: 500)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(hue: CGFloat(arc4random_uniform(100)) / 100,
                    saturation: 1,
                    brightness: 1,
                    alpha: 1).setFill()
            context.fill(context.format.bounds)
        }
    }
}
