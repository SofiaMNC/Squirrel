import SwiftUI

#if canImport(UIKit)
/// Represents a platform specific image
public typealias PlatformImage = UIImage
#elseif canImport(AppKit)
/// Represents a platform specific image
public typealias PlatformImage = CGImage
#endif

/// Creates a `SwiftUI` `Image` from a ``PlatformImage``.
public func makeImage(from image: PlatformImage) -> Image {
    #if canImport(UIKit)
    return Image(uiImage: image)
    #elseif canImport(AppKit)
    let nsImage = NSImage(cgImage: image, size: .zero)
    return Image(nsImage: nsImage)
    #endif
}

public func makePlatformImage(data: Data) -> PlatformImage? {
    #if canImport(UIKit)
    UIImage(data: data)
    #elseif canImport(AppKit)
    // create a CGImage from data
    // Not using an NSImage because it doesn't conform to `Sendable`.
    guard
        let imageSource = CGImageSourceCreateWithData(data as CFData, nil),
        let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    else {
        return nil
    }
    return cgImage
    #endif
}
