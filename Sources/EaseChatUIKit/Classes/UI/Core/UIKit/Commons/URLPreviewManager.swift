//
//  URLPreviewManager.swift
//  EaseChatDemo
//
//  Created by 朱继超 on 2024/6/13.
//

import Foundation

@objc public class URLPreviewManager: NSObject {
    
    @objc public static var caches: Dictionary<String,HTMLContent> = [:]

    @objcMembers public class HTMLContent: NSObject {
        func toDictionary() -> Dictionary<String,Any> {
            return ["title":self.title ?? "","description":self.descriptionHTML ?? "","imageUrl":self.imageURL ?? ""]
        }
        public var title: String?
        public lazy var titleAttribute: NSAttributedString? = {
            if title != nil {
                return NSAttributedString {
                    AttributedText(self.title!)
                        .font(UIFont.theme.headlineSmall)
                        .foregroundColor(Theme.style == .dark ? UIColor.theme.neutralColor98:UIColor.theme.neutralColor1).lineHeight(multiple: 1.15, minimum: 1.15).lineBreakMode(.byTruncatingTail)
                }
            } else {
                return nil
            }
        }()
        public var descriptionHTML: String?
        public var imageURL: String?
    }
    
    @objc public static func preview(from url: String, completion: @escaping (Error?,HTMLContent?) -> Void) {
        if self.caches.keys.contains(url) {
            completion(nil,self.caches[url])
            return
        }
        var urlString = url.lowercased()
        if !url.hasPrefix("http://"), !url.hasPrefix("https://") {
            urlString = "https://" + url
        } else {
            if url.hasPrefix("http://") {
                urlString.insert("s", at: 4)
            }
        }
        guard let htmlURL = URL(string: urlString) else {
            completion(NSError(domain: "\(url) not found", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]),nil)
            return
        }
        let task = URLSession.shared.dataTask(with: htmlURL) { data, response, error in
            if let error = error {
                completion(error,nil)
                return
            }
            
            guard let data = data else {
                completion(NSError(domain: "\(url) no data", code: 404, userInfo: [NSLocalizedDescriptionKey: "No data received."]),nil)
                return
            }
            
            // 将数据转换为 HTML 字符串
            if let htmlString = String(data: data, encoding: .utf8) {
                let content = URLPreviewManager.matchHTMLContent(from: htmlString)
                if content.title != nil {
                    completion(nil,content)
                } else {
                    completion(NSError(domain: "\(url) hasn't title", code: 404, userInfo: [NSLocalizedDescriptionKey: "Web page hasn't title"]),nil)
                }
            } else {
                completion(NSError(domain: "\(url) html string is empty", code: 404, userInfo: [NSLocalizedDescriptionKey: "Html string is empty."]),nil)
            }
        }
        
        task.resume()
    }


    @objc public static func matchHTMLContent(from html: String) -> HTMLContent {
        let content = HTMLContent()
        
        // Open Graph 协议的正则表达式模式
        let titleOGPattern = "<meta property=\"og:title\" content=\"(.*?)\"\\s*/?>"
        let descriptionOGPattern = "<meta property=\"og:description\" content=\"(.*?)\"\\s*/?>"
        let imageOGPattern = "<meta property=\"og:image\" content=\"(.*?)\"\\s*/?>"
        
        // 非 Open Graph 协议的正则表达式模式
        let titlePattern = "<title>(.*?)</title>"
        let descriptionPattern = "<meta\\s+name=\"description\"\\s+content=\"(.*?)\"\\s*/?>"
        let imagePattern = #"<img\\s+[^>]*src=\"((https?://|www\.)[^\"]+)"[^>]*>"#
        let imageSrcPattern = #"<link\s+rel="image_src"\s+href="((https?://|www\.)[^\"]*)"\s*/?>"#
        if Appearance.chat.titlePreviewPattern.isEmpty {
            // 提取 Open Graph 协议中的 title
            if let titleOGMatch = html.range(of: titleOGPattern, options: .regularExpression) {
                let titleOG = String(html[titleOGMatch])
                if let startRange = titleOG.range(of: "content=\""), let endRange = titleOG.range(of: "\"", range: startRange.upperBound..<titleOG.endIndex) {
                    content.title = String(titleOG[startRange.upperBound..<endRange.lowerBound])
                }
            } else {
                // 如果没有找到 Open Graph 协议的内容，则提取非 OG 协议的内容
                if let titleMatch = html.range(of: titlePattern, options: .regularExpression) {
                    let title = String(html[titleMatch])
                    if let startRange = title.range(of: "<title>"), let endRange = title.range(of: "</title>") {
                        content.title = String(title[startRange.upperBound..<endRange.lowerBound])
                    }
                }
            }
        } else {
            if let titleMatch = html.range(of: Appearance.chat.titlePreviewPattern, options: .regularExpression) {
                let title = String(html[titleMatch])
                if let startRange = title.range(of: "<title>"), let endRange = title.range(of: "</title>") {
                    content.title = String(title[startRange.upperBound..<endRange.lowerBound])
                }
            } else {
                if let titleOGMatch = html.range(of: titleOGPattern, options: .regularExpression) {
                    let titleOG = String(html[titleOGMatch])
                    if let startRange = titleOG.range(of: "content=\""), let endRange = titleOG.range(of: "\"", range: startRange.upperBound..<titleOG.endIndex) {
                        content.title = String(titleOG[startRange.upperBound..<endRange.lowerBound])
                    }
                }
            }
        }
        
        if Appearance.chat.descriptionPreviewPattern.isEmpty {
            // 提取 Open Graph 协议中的 description
            if let descriptionOGMatch = html.range(of: descriptionOGPattern, options: .regularExpression) {
                let descriptionOG = String(html[descriptionOGMatch])
                if let startRange = descriptionOG.range(of: "content=\""), let endRange = descriptionOG.range(of: "\"", range: startRange.upperBound..<descriptionOG.endIndex) {
                    content.descriptionHTML = String(descriptionOG[startRange.upperBound..<endRange.lowerBound])
                }
            } else {
                if let descriptionMatch = html.range(of: descriptionPattern, options: .regularExpression) {
                    let description = String(html[descriptionMatch])
                    if let startRange = description.range(of: "content=\""), let endRange = description.range(of: "\"", range: startRange.upperBound..<description.endIndex) {
                        content.descriptionHTML = String(description[startRange.upperBound..<endRange.lowerBound])
                    }
                }
            }
        } else {
            if let descriptionMatch = html.range(of: Appearance.chat.descriptionPreviewPattern, options: .regularExpression) {
                let description = String(html[descriptionMatch])
                if let startRange = description.range(of: "content=\""), let endRange = description.range(of: "\"", range: startRange.upperBound..<description.endIndex) {
                    content.descriptionHTML = String(description[startRange.upperBound..<endRange.lowerBound])
                }
            } else {
                if let descriptionOGMatch = html.range(of: descriptionOGPattern, options: .regularExpression) {
                    let descriptionOG = String(html[descriptionOGMatch])
                    if let startRange = descriptionOG.range(of: "content=\""), let endRange = descriptionOG.range(of: "\"", range: startRange.upperBound..<descriptionOG.endIndex) {
                        content.descriptionHTML = String(descriptionOG[startRange.upperBound..<endRange.lowerBound])
                    }
                }
            }
        }
        
        if Appearance.chat.imagePreviewPattern.isEmpty {
            // 提取 Open Graph 协议中的 image
            if let imageOGMatch = html.range(of: imageOGPattern, options: .regularExpression) {
                let imageOG = String(html[imageOGMatch])
                if let startRange = imageOG.range(of: "content=\""), let endRange = imageOG.range(of: "\"", range: startRange.upperBound..<imageOG.endIndex) {
                    content.imageURL = String(imageOG[startRange.upperBound..<endRange.lowerBound])
                }
            } else {
                if let imageSrcMatch = html.range(of: imageSrcPattern, options: .regularExpression) {
                    let imageSrc = String(html[imageSrcMatch])
                    if let startRange = imageSrc.range(of: "href=\""), let endRange = imageSrc.range(of: "\"", range: startRange.upperBound..<imageSrc.endIndex) {
                        content.imageURL = String(imageSrc[startRange.upperBound..<endRange.lowerBound])
                    }
                } else if let imageMatch = html.range(of: imagePattern, options: .regularExpression) {
                    let imageTag = String(html[imageMatch])
                    if let startRange = imageTag.range(of: "src=\""), let endRange = imageTag.range(of: "\"", range: startRange.upperBound..<imageTag.endIndex) {
                        content.imageURL = String(imageTag[startRange.upperBound..<endRange.lowerBound])
                    }
                }
            }
        } else {
            if let imageCustomMatch = html.range(of: Appearance.chat.imagePreviewPattern, options: .regularExpression) {
                let imageTag = String(html[imageCustomMatch])
                if let startRange = imageTag.range(of: "src=\""), let endRange = imageTag.range(of: "\"", range: startRange.upperBound..<imageTag.endIndex) {
                    content.imageURL = String(imageTag[startRange.upperBound..<endRange.lowerBound])
                }
            } else {
                if let imageOGMatch = html.range(of: imageOGPattern, options: .regularExpression) {
                    let imageOG = String(html[imageOGMatch])
                    if let startRange = imageOG.range(of: "content=\""), let endRange = imageOG.range(of: "\"", range: startRange.upperBound..<imageOG.endIndex) {
                        content.imageURL = String(imageOG[startRange.upperBound..<endRange.lowerBound])
                    }
                }
            }
        }
                        
        return content
    }

}
