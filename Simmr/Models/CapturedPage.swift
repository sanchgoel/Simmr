//
//  CapturedPage.swift
//  Simmr
//
//  A single photographed/picked recipe page, used by the shared review
//  screen for both the camera and photo library import paths. Wrapped in a
//  stable-identity struct rather than passing raw UIImage around — UIImage
//  isn't Identifiable, so ForEach/onMove reordering and "retake" splicing
//  (replacing one page's image while keeping its position) need a stable id
//  independent of the image's own contents.
//

import UIKit

struct CapturedPage: Identifiable {
    let id: UUID
    var image: UIImage

    init(id: UUID = UUID(), image: UIImage) {
        self.id = id
        self.image = image
    }
}
