//
//  StringExtension.swift
//  EaseChatUIKit
//
//  Created by 朱继超 on 2020/12/17.
//
import CommonCrypto
import Foundation
import UIKit
// MARK: - StringExtension
//infix operator -= : AdditionPrecedence
//infix operator += : AdditionPrecedence
public extension String {
    var chat: ChatWrapper<Self> {
        ChatWrapper.init(self)
    }
    
    /// 根据下标获取字符串中的某个字符 "xxx"[2]
    subscript(safe index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
    
    subscript<R>(safe range: R) -> String? where R: RangeExpression, R.Bound == Int {
        let range = range.relative(to: Int.min..<Int.max)
        guard range.lowerBound >= 0,
              let lowerIndex = index(startIndex, offsetBy: range.lowerBound, limitedBy: endIndex),
              let upperIndex = index(startIndex, offsetBy: range.upperBound, limitedBy: endIndex) else {
            return nil
        }
        
        return String(self[lowerIndex..<upperIndex])
    }
    
    @discardableResult
    mutating func slice(from start: Int, to end: Int) -> String {
        guard end >= start else { return self }
        if let str = self[safe:start..<end] {
            self = str
        }
        return self
    }

    
    static func -=(_ lhs: inout Self, _ rhs: Self) {
        if rhs.count >= lhs.count {
            assertionFailure("param2's length cant't beyond of param1's length")
        }
        if lhs.contains(rhs) {
            var temp = lhs
            temp.removeSubrange(Range(NSMakeRange(0, rhs.count), in: lhs)!)
            lhs = temp
        }
    }
    
    /// insert character
    ///
    /// - Parameters:
    ///   - text: The string to be inserted
    ///   - index: Where to insert
    /// - Returns: String
    @discardableResult
    mutating func insert(_ text: String, at index: Int) -> Self {
        if index > self.count - 1 || index < 0 {
            return self
        }
        let insertIndex = self.index(self.startIndex, offsetBy: index)
        self.insert(contentsOf: text, at: insertIndex)
        return self
    }
    
    //MARK: caches路径
    /// caches路径
    static var cachesPath: String {
        
        return NSHomeDirectory() + "/Library/Caches/"
    }
    
    //MARK: documents路径
    /// documents路径
    static var documentsPath: String {
        
        return NSHomeDirectory() + "/Documents/"
    }
    
    //MARK: temp路径
    /// temp路径
    static var tempPath: String {
        
        return NSHomeDirectory() + "/tmp/"
    }
    
}

public extension ChatWrapper where Base == String {
    var numCount: Int {
        var count = 0
        for c in base where ("0"..."9").contains(c) {
            count += 1
        }
        return count
    }
    
    var urlDecoded: String {
        base.removingPercentEncoding ?? base
    }
    
    var localize: String {
        LanguageConvertor.localValue(key: base)
    }
    
    ///        "it's easy to encode strings".urlEncoded -> "it's%20easy%20to%20encode%20strings"
    ///
    var urlEncoded: String {
        return base.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
    }
    
    var containEmoji: Bool {
        // http://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
        for scalar in base.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                 0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                 0x1F680...0x1F6FF, // Transport and Map
                 0x1F1E6...0x1F1FF, // Regional country flags
                 0x2600...0x26FF, // Misc symbols
                 0x2700...0x27BF, // Dingbats
                 0xE0020...0xE007F, // Tags
                 0xFE00...0xFE0F, // Variation Selectors
                 0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                 127_000...127_600, // Various asian characters
                 65024...65039, // Variation selector
                 9100...9300, // Misc items
                 8400...8447: // Combining Diacritical Marks for Symbols
                return true
            default:
                continue
            }
        }
        return false
    }
    
    var locationString: String {
        Bundle.main.localizedString(forKey: base, value: "", table: nil)
    }
    
    var verticalText: String {
        var str = ""
        _ = base.map {
            str.append($0)
            str += "\n"
        }
        return str
    }
    
    ///        "123abc".hasLetters -> true
    ///        "123".hasLetters -> false
    ///
    var hasLetters: Bool {
        return base.rangeOfCharacter(from: .letters, options: .numeric, range: nil) != nil
    }
    
    ///        "abcd".hasNumbers -> false
    ///        "123abc".hasNumbers -> true
    ///
    var hasNumbers: Bool {
        return base.rangeOfCharacter(from: .decimalDigits, options: .literal, range: nil) != nil
    }
    

    ///     "abcdcba".isPalindrome -> true
    ///     "Mom".isPalindrome -> true
    ///     "A man a plan a canal, Panama!".isPalindrome -> true
    ///     "Mama".isPalindrome -> false
    ///
    var isPalindrome: Bool {
        let letters = base.filter { $0.isLetter }
        guard !letters.isEmpty else { return false }
        let midIndex = letters.index(letters.startIndex, offsetBy: letters.count / 2)
        let firstHalf = letters[letters.startIndex..<midIndex]
        let secondHalf = letters[midIndex..<letters.endIndex].reversed()
        return !zip(firstHalf, secondHalf).contains(where: { $0.lowercased() != $1.lowercased() })
    }
    
    var isWhitespace: Bool {
        return base.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var wordCount: Int {
        var count = 0
        for c in base.lowercased() where ("a"..."z").contains(c) {
            count += 1
        }
        return count
    }
    
    var pinYin: String {
        let mutableString = NSMutableString(string: base)
        //把汉字转为拼音
        CFStringTransform(mutableString, nil, kCFStringTransformToLatin, false)
        //去掉拼音的音标
        CFStringTransform(mutableString, nil, kCFStringTransformStripDiacritics, false)
        //去掉空格
        return String(mutableString).replacingOccurrences(of: " ", with: "")
    }
    
    var hexColor: UIColor {
        if base == "--" || base.isEmpty == true {
            return .orange
        }
        let hexString = base.trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hexString)
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
         
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
         
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    func rangeOfString(_ subString: String) -> NSRange {
        (base as NSString).range(of: subString)
    }
    
    func sizeWithText(font: UIFont, size: CGSize) -> CGSize {
        let attributes = [NSAttributedString.Key.font: font]
        let option = NSStringDrawingOptions.usesLineFragmentOrigin
        let rect:CGRect = base.boundingRect(with: size, options: option, attributes: attributes, context: nil)
        return rect.size;
    }
    
    func lines() -> [String] {
        var result = [String]()
        base.enumerateLines { line, _ in
            result.append(line)
        }
        return result
    }
    
    /// SwifterSwift: Array with unicodes for all characters in a string.
    /// - Returns: The unicodes for all characters in a string.
    func unicodeArray() -> [Int] {
        return base.unicodeScalars.map { Int($0.value) }
    }
    
    /// jsonString convert dic
    /// - Returns: Dictionary
    func jsonToDictionary() -> Dictionary<String,Any> {
        base.data(using: .utf8)?.chat.toDictionary() ?? [:]
    }
    
    /// 是否符合正则表达式
    ///
    /// - Parameter expression: 正则表达式
    /// - Returns: 结果
    func isMatchRegular(expression: String) -> Bool {
        if let regularExpression = try? NSRegularExpression.init(pattern: expression, options: NSRegularExpression.Options.caseInsensitive) {
            return regularExpression.matches(in: base, options: .reportCompletion, range: NSRange(location: 0, length: base.count)).count > 0
        }
        return false
    }
    
    /// 是否包含符合正则表达式的字符串
    ///
    /// - Parameter expression: 正则表达式
    /// - Returns: 结果
    func isContainRegular(expression: String) -> Bool {
        if let regularExpression = try? NSRegularExpression.init(pattern: expression, options: NSRegularExpression.Options.caseInsensitive) {
            return regularExpression.rangeOfFirstMatch(in: base, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange(location: 0, length: base.count)).location != NSNotFound
        }
        return false
    }
    
    ///        var str = "Hèllö Wórld!"
    ///        str.chat.latinize()
    ///        print(str) // prints "Hello World!"
    ///
    @discardableResult
    mutating func latinize() -> String {
        base = base.folding(options: .diacriticInsensitive, locale: Locale.current)
        return base
    }
    
    /// 替换符合正则表达式的文字
    ///
    /// - Parameters:
    ///   - expression: 正则表达式
    ///   - newStr: 替换后的文字
    /// - Returns: 新字符串
    func removeMatchRegular(expression: String, with newStr: String) -> String {
        if let regularExpression = try? NSRegularExpression.init(pattern: expression, options: NSRegularExpression.Options.caseInsensitive) {
            return regularExpression.stringByReplacingMatches(in: base, options: NSRegularExpression.MatchingOptions.reportProgress, range: NSRange(location: 0, length: base.count), withTemplate: newStr)
        }
        return base
    }
    
    /// Range转换为NSRange
    func convertNSRange(from range: Range<String.Index>) -> NSRange? {
        return NSRange(range, in: base)
    }
    
    /// 获取所有符合正则表达式的文字位置
    ///
    /// - Parameter expression: 正则表达式 eg: "@[\\u4e00-\\u9fa5\\w\\-\\_]+ "="@ZCC "
    /// - Returns: [位置]?
    func matchRegularRange(expression: String) -> [NSRange]? {
        if let regularExpression = try? NSRegularExpression.init(pattern: expression, options: NSRegularExpression.Options.caseInsensitive) {
            return regularExpression.matches(in: base, options: .reportProgress, range: NSRange(location: 0, length: base.count)).map {
                $0.range
            }
        }
        return nil
    }
    
    /// Whether regularity matches-predicate method
    ///
    /// - Parameter string: MATCHES string
    /// - Returns: Bool
    func isRegularCorrect(_ string: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", string).evaluate(with: self)
    }
    
    // 检测字符串是否包含 Emoji
    func containsEmoji() -> Bool {
        for scalar in base.unicodeScalars {
            switch scalar.value {
            case 0x1F600...0x1F64F, // Emoticons
                0x1F300...0x1F5FF, // Misc Symbols and Pictographs
                0x1F680...0x1F6FF, // Transport and Map
                0x1F700...0x1F77F, // Alchemical Symbols
                0x1F780...0x1F7FF, // Geometric Shapes Extended
                0x1F800...0x1F8FF, // Supplemental Arrows-C
                0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                0x1FA00...0x1FA6F, // Chess Symbols
                0x1FA70...0x1FAFF, // Symbols and Pictographs Extended-A
                0x2600...0x26FF,   // Misc Symbols
                0x2700...0x27BF,   // Dingbats
                0xFE00...0xFE0F,   // Variation Selectors
                0x1F1E6...0x1F1FF, // Flags
                0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
                0x1F018...0x1F270, // Various Asian characters
                0x238C...0x2454,   // Misc items
                0x20D0...0x20FF:   // Combining Diacritical Marks for Symbols
                return true
            default:
                continue
            }
        }
        return false
    }
    
    /// 移除字符串中的Emoij
    ///
    /// - Returns: 新字符串
    func deleteEmoij() -> String {
        
        return base.chat.removeMatchRegular(expression: "[^\\u0020-\\u007E\\u00A0-\\u00BE\\u2E80-\\uA4CF\\uF900-\\uFAFF\\uFE30-\\uFE4F\\uFF00-\\uFFEF\\u0080-\\u009F\\u2000-\\u201f\r\n]", with: "")
    }
    
    ///  String convert to Date
    /// - Parameter formatter: yyyy-MM-dd hh:mm:ss
    /// - Returns: Date
    func toDate(formatter: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = formatter
        fmt.locale = Locale(identifier: "zh_CN")
        let date = fmt.date(from: base) ?? Date()
        return date
    }
    
    //时间戳转时间
    func timeStampToString(dateFormat: String?) -> Base {
        var string = base
        if(base.count >= 10){
            string = base.chat.subStringTo(10)
        }
        let timeStamp:TimeInterval = Double(string) ?? 0.0
        let dfmatter = DateFormatter()
        dfmatter.locale = Locale(identifier: "zh_CN")
        dfmatter.dateFormat = dateFormat ?? "yyyy-MM-dd HH:mm:ss"
        let date = Date(timeIntervalSince1970: timeStamp)
        return dfmatter.string(from: date)
    }
    
    ///1, 截取规定下标之后的字符串
    func subStringFrom(_ index: Int) -> String {
        let temporaryIndex = base.index(base.startIndex, offsetBy: index)
        return String(base[temporaryIndex...])
    }
    
    ///2, 截取规定下标之前的字符串
    func subStringTo(_ index: Int) -> String {
        let temporaryString = base
        let temporaryIndex = temporaryString.index(temporaryString.startIndex, offsetBy: index)
        return String(temporaryString[...temporaryIndex])
    }
    ///3,替换某个range的字符串
    func replaceStringWithRange(location: Int, length: Int, newString: String) -> String {
        if location + length > base.count {
            return base
        }
        let start = base.startIndex
        let location_start = base.index(start, offsetBy: location)
        let location_end = base.index(location_start, offsetBy: length)
        let result = base.replacingCharacters(in: location_start..<location_end, with: newString)
        return result
    }
    ///4.获取某个range 的子串
    func subStringWithRange(location: Int, length: Int) -> String {
        if location + length > base.count{
            return base
        }
        let str: String = base
        let start = str.startIndex
        let startIndex = str.index(start, offsetBy: location)
        let endIndex = str.index(startIndex, offsetBy: length)
        return String(str[startIndex..<endIndex])
    }
    
    /// 正则匹配第一次出现
    func firstMatchWith(pattern: String) -> NSRange {
        if base.count == 0 {
            return NSMakeRange(0, 0)
        }
        do {
            let str: String = base
            let regular = try NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive)
            let reg = regular.firstMatch(in: str, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSMakeRange(0, str.count))
            if let result = reg {
                return NSMakeRange(result.range.location, result.range.length)
            }
        } catch {
            assert(false, "error: \(error)")
        }
        return NSMakeRange(0, 0)
    }
    
    /// 获取子串的所有range
    func rangesOfString(_ searchString: String) -> [NSRange] {
        var results = [NSRange]()
        let inString = base as NSString
        if searchString.count > 0 && inString.length > 0 {
            var searchRange = NSMakeRange(0, inString.length)
            var range = inString.range(of: searchString, options: [], range: searchRange)
            while (range.location != NSNotFound) {
                results.append(range)
                searchRange = NSMakeRange(NSMaxRange(range), inString.length - NSMaxRange(range))
                range = inString.range(of: searchString, options: [], range: searchRange)
            }
            
        }
        return results
    }
    
    /// 文字转图片
    ///
    /// - Parameters:
    ///   - font: 字体大小
    ///   - textColor: 文字颜色
    /// - Returns: 图片
    func convertToTextImage(font: UIFont, textColor: UIColor, size: CGSize) -> UIImage? {
        
        let imgHeight: CGFloat = 16.0
        let imgWidth = base.chat.sizeWithText(font: font, size: size).width
        
        let attributeStr = NSAttributedString.init(string: base, attributes: [.font : font, .foregroundColor: textColor])
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imgWidth, height: imgHeight), false, UIScreen.main.scale)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setCharacterSpacing(10.0)
        context?.setTextDrawingMode(CGTextDrawingMode.fill)
        context?.setFillColor(UIColor.white.cgColor)
        
        attributeStr.draw(in: CGRect(x: 0.0, y: 0.0, width: imgWidth, height: imgHeight))
        
        let newImg = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImg
    }
    
    /// 生成二维码
    ///
    /// - Parameters:
    ///   - centerImg: 中间的小图
    ///   - block: 回调
    internal func generateQRCode(centerImg: UIImage? = nil) -> UIImage? {
        
        if base.isEmpty {
            return nil
        }
        let filter = CIFilter.init(name: "CIQRCodeGenerator")
        filter?.setDefaults()
        filter?.setValue(base.data(using: String.Encoding.utf8, allowLossyConversion: true), forKey: "inputMessage")
        if let image = filter?.outputImage {
            let size: CGFloat = 300.0
            
            let integral: CGRect = image.extent.integral
            let proportion: CGFloat = min(size/integral.width, size/integral.height)
            
            let width = integral.width * proportion
            let height = integral.height * proportion
            let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
            let bitmapRef = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: 0)!
            
            let context = CIContext(options: nil)
            if let bitmapImage: CGImage = context.createCGImage(image, from: integral) {
                bitmapRef.interpolationQuality = CGInterpolationQuality.none
                bitmapRef.scaleBy(x: proportion, y: proportion);
                bitmapRef.draw(bitmapImage, in: integral);
                if let image: CGImage = bitmapRef.makeImage() {
                    var qrCodeImage = UIImage(cgImage: image)
                    if let centerImg = centerImg {
                        // 图片拼接
                        UIGraphicsBeginImageContextWithOptions(qrCodeImage.size, false, UIScreen.main.scale)
                        qrCodeImage.draw(in: CGRect(x: 0.0, y: 0.0, width: qrCodeImage.size.width, height: qrCodeImage.size.height))
                        centerImg.draw(in: CGRect(x: (qrCodeImage.size.width - 35.0) / 2.0, y: (qrCodeImage.size.height - 35.0) / 2.0, width: 35.0, height: 35.0))
                        
                        qrCodeImage = UIGraphicsGetImageFromCurrentImageContext() ?? qrCodeImage
                        UIGraphicsEndImageContext()
                        return qrCodeImage
                    } else {
                        return qrCodeImage
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    //MARK: - 生成高清的UIImage
    func generateUpHighDefinitionImage(_ image: CIImage, size: CGFloat) -> UIImage? {
        let integral: CGRect = image.extent.integral
        let proportion: CGFloat = min(size/integral.width, size/integral.height)
        
        let width = integral.width * proportion
        let height = integral.height * proportion
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapRef = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: 0)!
        
        let context = CIContext(options: nil)
        let bitmapImage: CGImage = context.createCGImage(image, from: integral)!
        
        bitmapRef.interpolationQuality = CGInterpolationQuality.none
        bitmapRef.scaleBy(x: proportion, y: proportion);
        bitmapRef.draw(bitmapImage, in: integral);
        if let image: CGImage = bitmapRef.makeImage() {
            return UIImage(cgImage: image)
        }
        return nil
    }
    
}
