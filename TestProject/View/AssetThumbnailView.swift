//
//  AssetThumbnailView.swift
//  TestProject
//
//  Created by quanganh on 3/8/26.
//

import SwiftUI
import Photos

struct AssetThumbnailView: View {
    let asset: PHAsset
    let imageManager: PHCachingImageManager
    let targetSize: CGSize
    
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let uiImage = image {
                Color.clear
                    .aspectRatio(1, contentMode: .fill)
                    .overlay(
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipped()
            } else {
                Color.gray.opacity(0.2)
                    .aspectRatio(1, contentMode: .fill)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .opportunistic
        
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { result, info in
            if let result {
                self.image = result
            }
        }
    }
}
