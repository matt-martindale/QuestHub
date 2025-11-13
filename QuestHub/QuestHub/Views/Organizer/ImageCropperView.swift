//
//  ImageCropperView.swift
//  QuestHub
//
//  Created by Matt Martindale on 11/12/25.
//

import SwiftUI

struct CropHoleShape: Shape {
    let rect: CGRect
    let cornerRadius: CGFloat
    func path(in bounds: CGRect) -> Path {
        // Create an outer rectangle and subtract a rounded-rect hole using even-odd fill
        let outer = UIBezierPath(rect: bounds)
        let inner = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        outer.append(inner)
        outer.usesEvenOddFillRule = true
        return Path(outer.cgPath)
    }
}

struct ImageCropperView: View {
    let image: UIImage
    let aspectRatio: CGFloat
    let onCropped: (UIImage) -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var minAllowedScale: CGFloat = 1
    @State private var computedMinScale: CGFloat = 1

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                let horizontalPadding: CGFloat = 24
                let availableWidth = max(1, geo.size.width - horizontalPadding * 2)
                let safeAspect = max(aspectRatio, 0.0001)
                let maxCropWidth = min(availableWidth, max(1, geo.size.height))
                let cropWidth = max(1, maxCropWidth)
                let cropHeight = max(1, cropWidth / safeAspect)
                let cropSize = CGSize(width: cropWidth, height: cropHeight)
                let cropRect = CGRect(
                    x: max(0, (geo.size.width - cropSize.width) / 2),
                    y: max(0, (geo.size.height - cropSize.height) / 2),
                    width: cropSize.width,
                    height: cropSize.height
                )

                let imageAspect = image.size.width / image.size.height
                let canvasAspect = geo.size.width / geo.size.height

                let fittedSize: CGSize = {
                    if imageAspect > canvasAspect {
                        let width = geo.size.width
                        let height = width / imageAspect
                        return CGSize(width: width, height: height)
                    } else {
                        let height = geo.size.height
                        let width = height * imageAspect
                        return CGSize(width: width, height: height)
                    }
                }()

                let minScaleX = cropRect.width / fittedSize.width
                let minScaleY = cropRect.height / fittedSize.height
                let localComputedMinScale = max(minScaleX, minScaleY)
                let maxScale: CGFloat = max(localComputedMinScale * 4, 4)

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            DragGesture()
                                .onChanged { value in
                                    let proposed = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                    offset = clampOffset(
                                        proposed,
                                        imageSize: fittedSize,
                                        cropRect: cropRect,
                                        canvasSize: geo.size,
                                        scale: scale
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                },
                            MagnificationGesture()
                                .onChanged { value in
                                    let proposedScale = lastScale * value
                                    let clamped = min(maxScale, max(localComputedMinScale, proposedScale))
                                    if clamped != scale {
                                        let ratio = clamped / max(scale, 0.0001)
                                        offset = CGSize(width: offset.width * ratio, height: offset.height * ratio)
                                    }
                                    scale = clamped
                                    offset = clampOffset(
                                        offset,
                                        imageSize: fittedSize,
                                        cropRect: cropRect,
                                        canvasSize: geo.size,
                                        scale: scale
                                    )
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    lastOffset = offset
                                }
                        )
                    )
                    .clipped()

                Color.black.opacity(0.5)
                    .mask(
                        CropHoleShape(rect: cropRect, cornerRadius: 10)
                            .fill(style: FillStyle(eoFill: true))
                    )
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropRect.width, height: cropRect.height)
                    .position(x: cropRect.midX, y: cropRect.midY)

                VStack {
                    Spacer()
                    HStack {
                        Button("Cancel") { onCancel(); dismiss() }
                        Spacer()
                        Button("Crop") {
                            if let result = renderCroppedImage(canvasSize: geo.size, cropRect: cropRect) {
                                onCropped(result)
                            }
                            dismiss()
                        }
                    }
                    .padding()
                }

                Color.clear
                    .onAppear {
                        DispatchQueue.main.async {
                            let minScale = localComputedMinScale
                            if scale < minScale {
                                scale = minScale
                                lastScale = minScale
                            }
                            offset = clampOffset(offset, imageSize: fittedSize, cropRect: cropRect, canvasSize: geo.size, scale: scale)
                            lastOffset = offset
                        }
                    }
                    .onChange(of: localComputedMinScale) { _, newMin in
                        DispatchQueue.main.async {
                            if scale < newMin {
                                scale = newMin
                                lastScale = newMin
                            }
                            offset = clampOffset(offset, imageSize: fittedSize, cropRect: cropRect, canvasSize: geo.size, scale: scale)
                            lastOffset = offset
                        }
                    }
            }
        }
    }

    private func renderCroppedImage(canvasSize: CGSize, cropRect: CGRect) -> UIImage? {
        let imageAspect = image.size.width / image.size.height
        let canvasAspect = canvasSize.width / canvasSize.height

        let fittedSize: CGSize = {
            if imageAspect > canvasAspect {
                let width = canvasSize.width
                let height = width / imageAspect
                return CGSize(width: width, height: height)
            } else {
                let height = canvasSize.height
                let width = height * imageAspect
                return CGSize(width: width, height: height)
            }
        }()

        let imageOrigin = CGPoint(x: (canvasSize.width - fittedSize.width) / 2, y: (canvasSize.height - fittedSize.height) / 2)
        let transformedSize = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)
        let transformedOrigin = CGPoint(x: imageOrigin.x + offset.width - (transformedSize.width - fittedSize.width) / 2, y: imageOrigin.y + offset.height - (transformedSize.height - fittedSize.height) / 2)

        let scaleX = image.size.width / transformedSize.width
        let scaleY = image.size.height / transformedSize.height

        let xInImage = (cropRect.minX - transformedOrigin.x) * scaleX
        let yInImage = (cropRect.minY - transformedOrigin.y) * scaleY
        let widthInImage = cropRect.width * scaleX
        let heightInImage = cropRect.height * scaleY

        let imageCropRect = CGRect(x: xInImage, y: yInImage, width: widthInImage, height: heightInImage).integral
        guard let cgImage = image.cgImage else { return nil }
        let boundedRect = imageCropRect.intersection(CGRect(origin: .zero, size: image.size))
        guard let cropped = cgImage.cropping(to: boundedRect) else { return nil }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }

    private func clampOffset(_ proposed: CGSize, imageSize: CGSize, cropRect: CGRect, canvasSize: CGSize, scale: CGFloat) -> CGSize {
        let imageOrigin = CGPoint(
            x: (canvasSize.width - imageSize.width) / 2,
            y: (canvasSize.height - imageSize.height) / 2
        )
        let transformedSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)

        let baseOrigin = CGPoint(
            x: imageOrigin.x - (transformedSize.width - imageSize.width) / 2,
            y: imageOrigin.y - (transformedSize.height - imageSize.height) / 2
        )

        let proposedOrigin = CGPoint(x: baseOrigin.x + proposed.width, y: baseOrigin.y + proposed.height)

        let minX = cropRect.maxX - transformedSize.width
        let maxX = cropRect.minX
        let minY = cropRect.maxY - transformedSize.height
        let maxY = cropRect.minY

        let clampedOriginX = min(max(proposedOrigin.x, minX), maxX)
        let clampedOriginY = min(max(proposedOrigin.y, minY), maxY)

        let clampedOffset = CGSize(
            width: clampedOriginX - baseOrigin.x,
            height: clampedOriginY - baseOrigin.y
        )
        return clampedOffset
    }
}
