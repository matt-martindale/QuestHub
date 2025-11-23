import UIKit

public struct ImageCompressor {
    /// Compresses the given UIImage by optionally downscaling it to fit within maxDimension, then encoding to JPEG with the specified quality.
    /// - Parameters:
    ///   - image: The UIImage to compress.
    ///   - maxDimension: Optional maximum dimension (width or height) to downscale the image to. If nil, no downscaling is performed.
    ///   - jpegQuality: JPEG compression quality between 0.0 and 1.0. Defaults to 0.8.
    /// - Returns: A new compressed UIImage or nil if compression fails.
    public static func compress(image: UIImage, maxDimension: CGFloat? = nil, jpegQuality: CGFloat = 0.8) -> UIImage? {
        let quality = min(max(jpegQuality, 0.0), 1.0)
        let sourceImage: UIImage
        
        if let maxDimension = maxDimension {
            sourceImage = downscaled(image: image, maxDimension: maxDimension)
        } else {
            sourceImage = image
        }
        
        guard let data = sourceImage.jpegData(compressionQuality: quality) else {
            return nil
        }
        
        if let result = UIImage(data: data, scale: image.scale) {
            return UIImage(cgImage: result.cgImage!, scale: image.scale, orientation: .up)
        }
        return UIImage(data: data)
    }
    
    /// Asynchronously compresses the given UIImage by optionally downscaling it to fit within maxDimension, then encoding to JPEG with the specified quality.
    /// - Parameters:
    ///   - image: The UIImage to compress.
    ///   - maxDimension: Optional maximum dimension (width or height) to downscale the image to. If nil, no downscaling is performed.
    ///   - jpegQuality: JPEG compression quality between 0.0 and 1.0. Defaults to 0.8.
    /// - Returns: A new compressed UIImage or nil if compression fails.
    public static func compressAsync(image: UIImage, maxDimension: CGFloat? = nil, jpegQuality: CGFloat = 0.8) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let compressed = compress(image: image, maxDimension: maxDimension, jpegQuality: jpegQuality)
                continuation.resume(returning: compressed)
            }
        }
    }
    
    private static func downscaled(image: UIImage, maxDimension: CGFloat) -> UIImage {
        let width = image.size.width
        let height = image.size.height
        
        if width <= maxDimension && height <= maxDimension {
            return image
        }
        
        let newSize: CGSize
        if width >= height {
            let newWidth = maxDimension
            let newHeight = maxDimension * height / width
            newSize = CGSize(width: newWidth, height: newHeight)
        } else {
            let newHeight = maxDimension
            let newWidth = maxDimension * width / height
            newSize = CGSize(width: newWidth, height: newHeight)
        }
        
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let scaledImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return scaledImage
    }
}
