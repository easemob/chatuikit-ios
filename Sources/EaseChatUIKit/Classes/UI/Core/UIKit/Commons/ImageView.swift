//
//  ImageView.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2023/9/1.
//

import UIKit
import Combine

/// A subclass of `UIImageView` that provides a method for loading an image from a URL.
@objc final public class ImageView: UIImageView {

    private var cancellables = Set<AnyCancellable>()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Loads an image from the specified URL and sets it as the image of the image view.
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - placeHolder: An optional placeholder image to display while the image is being loaded.
    @MainActor public func image(with url: String,placeHolder: UIImage?) {
        self.image = placeHolder
        var urlString = url.lowercased()
        if !url.hasPrefix("http://"), !url.hasPrefix("https://") {
            urlString = "https://" + url
        } else {
            if url.hasPrefix("http://") {
                urlString.insert("s", at: 4)
            }
        }
        guard let imageURL = URL(string: urlString) else {
            return
        }
        ImageLoader.shared.loadImage(from: imageURL)
            .sink(receiveValue: { [weak self] url_image in
                if url_image != nil,url_image?.size ?? .zero != .zero {
                    self?.image = url_image
                }
            })
            .store(in: &self.cancellables)
    }

    /// Loads an image from the specified URL and sets it as the image of the image view.
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - placeHolder: An optional placeholder image to display while the image is being loaded.
    ///   - loadFinished: Load finished callback.
    public func image(with url: String,placeHolder: UIImage?,loadFinished: @escaping (UIImage?) -> Void) {
        self.image = placeHolder
        guard let imageURL = URL(string: url) else {
            return
        }
        ImageLoader.shared.loadImage(from: imageURL)
            .sink(receiveValue: { [weak self] url_image in
                if url_image != nil,url_image?.size ?? .zero != .zero  {
                    self?.image = url_image
                    loadFinished(url_image)
                }
            })
            .store(in: &self.cancellables)
    }
}
