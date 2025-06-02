//
//  UIImage+GIF.swift
//  YogaPoseTrainer
//
//  Created by Arun Mudaliar on 31/05/25.
//

import UIKit

extension UIImage{
    static func gif(name: String) -> UIImage? {
        guard let bundleUrl = Bundle.main.url(forResource: name, withExtension: "gif") else {
            print("Resource not found \(name)")
            return nil
        }
        guard let imageData = try? Data(contentsOf: bundleUrl) else {
            print("Resource data not found \(name)")
            return nil
        }
        return gif(data: imageData)
    }
    
    static func gif(data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("Failed to create image source")
            return nil
        }

        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()
        
        for i in 0..<count {
           guard let image = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
           images.append(image)

           let delaySeconds = UIImage.delayForImage(at: i, source: source)
           delays.append(Int(delaySeconds * 1000.0)) // Convert to ms
       }
        let duration: Int = delays.reduce(0, +)
        let gcd = UIImage.gcd(for: delays)

        var frames = [UIImage]()
        for i in 0..<count {
            let frame = UIImage(cgImage: images[i])
            let frameCount = delays[i] / gcd
            frames += Array(repeating: frame, count: frameCount)
        }

        return UIImage.animatedImage(with: frames, duration: Double(duration) / 1000.0)
        
    }
    
    private static func delayForImage(at index: Int, source: CGImageSource) -> Double {
           var delay = 0.1
           guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
                 let gifInfo = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
               return delay
           }

           if let unclamped = gifInfo[kCGImagePropertyGIFUnclampedDelayTime] as? Double {
               delay = unclamped
           } else if let clamped = gifInfo[kCGImagePropertyGIFDelayTime] as? Double {
               delay = clamped
           }

           if delay < 0.01 { delay = 0.1 }
           return delay
       }

       private static func gcd(for values: [Int]) -> Int {
           guard let first = values.first else { return 1 }
           return values.reduce(first) { UIImage.gcd($0, $1) }
       }

       private static func gcd(_ a: Int, _ b: Int) -> Int {
           var a = a, b = b
           while b != 0 {
               let temp = b
               b = a % b
               a = temp
           }
           return a
       }
    
}


