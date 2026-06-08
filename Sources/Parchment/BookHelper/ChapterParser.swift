import Foundation

// MARK: - ChapterParser

/// 小说章节解析器
/// 支持标准与非标准章节标题的全面解析
/// 返回 offset/length 均为解码后 UTF-8 字节偏移（与 String.utf8 对齐）
final class ChapterParser {

    // MARK: - Public Types

    /// 章节信息
    struct ChapterItem {
        /// 章节标题（已清理首尾空白）
        let title: String
        /// 章节在解码文本 UTF-8 中的字节偏移量
        let offset: Int64
        /// 章节 UTF-8 字节长度
        let length: Int64
        /// 章节正文摘要（跳过标题行，取前 N 字符）
        let sketchText: String

        init(title: String, offset: Int64, length: Int64, sketchText: String) {
            self.title = title
            self.offset = offset
            self.length = length
            self.sketchText = sketchText
        }
    }

    // MARK: - Configuration

    /// 解析配置
    struct Configuration {
        /// 摘要最大字符数（默认 120）
        var sketchMaxLength: Int
        /// 是否合并连续空行（默认 true，3+ 空行压缩为 2 行）
        var mergeBlankLines: Bool
        /// 自定义额外正则模式（追加到内置模式之后，使用 anchorsMatchLines）
        var extraPatterns: [String]
        /// 低置信度章节占比阈值：超过此比例则丢弃所有低置信度结果（默认 0.6）
        var ambiguousRatioThreshold: Double
        /// 最小章节数阈值：章节数低于此值时，放宽低置信度过滤（默认 3）
        var minChapterCountForFiltering: Int

        init(
            sketchMaxLength: Int = 120,
            mergeBlankLines: Bool = true,
            extraPatterns: [String] = [],
            ambiguousRatioThreshold: Double = 0.6,
            minChapterCountForFiltering: Int = 3
        ) {
            self.sketchMaxLength = sketchMaxLength
            self.mergeBlankLines = mergeBlankLines
            self.extraPatterns = extraPatterns
            self.ambiguousRatioThreshold = ambiguousRatioThreshold
            self.minChapterCountForFiltering = minChapterCountForFiltering
        }

        static let `default` = Configuration()
    }

    // MARK: - Confidence Level

    /// 章节匹配置信度
    private enum Confidence {
        case high
        case medium
        case low
    }

    // MARK: - Private Properties

    private let configuration: Configuration

    /// 编译好的正则列表（懒加载，仅编译一次）
    private lazy var compiledRegexGroups: [RegexGroup] = buildRegexGroups()

    /// 额外正则（不分组，每行都尝试）
    private lazy var extraRegexes: [NSRegularExpression] = buildExtraRegexes()

    // MARK: - Private: Regex Group

    /// 正则分组：按置信度分组
    private struct RegexGroup {
        let regexes: [NSRegularExpression]
        let confidence: Confidence
        /// 该组正则可能匹配的行首字节集合（用于快速预过滤）
        let triggerBytes: Set<UInt8>
    }

    // MARK: - Builtin Patterns

    // 高置信度模式（仅匹配常见章节格式）
    private static let highConfidencePatterns: [String] = [
        // ── 1. 卷+章复合结构 ──
        #"^[\s\u3000]*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[卷部册]\s*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[章节回](\s+[^\n\r]{0,40}|[\s\u3000]*$)"#,
        // ── 2. 标准中文章节 ──
        #"^[\s\u3000]*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[章节回卷部篇集幕话折则讲段期册](\s+[^\n\r]{0,60}|[\s\u3000]*$)"#,
        // ── 3. 特殊固定标题词 ──
        #"^[\s\u3000]*(序章|楔子|尾声|番外|后记|前言|引子|正文开始|附录|结语|终章|外传|间章|序言|作者的话|作者有话说|特别篇|特别章)(\s+[^\n\r]{0,60}|[\s\u3000]*$)"#,
    ]

    // 中置信度模式（留空，不使用）
    private static let mediumConfidencePatterns: [String] = []

    // 低置信度模式（留空，不使用）
    private static let lowConfidencePatterns: [String] = []
    // MARK: - 首字节触发集合（预过滤用）

    /// 高置信度行首可能出现的 UTF-8 首字节
    /// "第" = E7 AC AC，章节回等汉字首字节 = 0xE3-0xEF，空格/全角空格
    private static let highMediumTriggerBytes: Set<UInt8> = {
        var bytes = Set<UInt8>()
        // 汉字/全角符号首字节（"第"、"序"、"楔"、"尾"、"番"等均在此范围）
        for b: UInt8 in 0xE3...0xEF { bytes.insert(b) }
        // 空白（行首可能有缩进）
        bytes.insert(0x20) // space
        bytes.insert(0x09) // tab
        return bytes
    }()

    // MARK: - Init

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    // MARK: - Public API

    func parse(text: String) -> [(title: String, offset: Int64, length: Int64, sketchText: String)] {
        parseItems(from: text).map { ($0.title, $0.offset, $0.length, $0.sketchText) }
    }

    func parseItems(from text: String) -> [ChapterItem] {
        guard !text.isEmpty else { return [] }

        // 单次 UTF-8 字节扫描：规范化换行 + 行分割 + 匹配
        let (normalizedBytes, lineInfos) = buildLineInfos(from: text)

        // 扫描章节标题
        let matches = findChapterMatches(in: normalizedBytes, lineInfos: lineInfos)

        // 过滤模糊章节
        let filtered = filterAmbiguousMatches(matches, lineInfos: lineInfos)

        guard !filtered.isEmpty else {
            let sketch = makeSketchFromBytes(normalizedBytes, from: 0, to: normalizedBytes.count,
                                             maxLen: configuration.sketchMaxLength)
            return [ChapterItem(title: "正文", offset: 0,
                                length: Int64(normalizedBytes.count), sketchText: sketch)]
        }

        return buildChapterItems(from: normalizedBytes, matches: filtered)
    }

    func parse(fileURL url: URL) throws -> [(title: String, offset: Int64, length: Int64, sketchText: String)] {
        let text = try readText(from: url)
        return parse(text: text)
    }

    // MARK: - Private: Line Info

    /// 行信息（基于规范化后的 UTF-8 字节数组）
    private struct LineInfo {
        /// 行内容在 normalizedBytes 中的起始字节索引（含）
        let start: Int
        /// 行内容结束字节索引（不含换行符）
        let end: Int
        /// 行末换行符之后的字节索引（即下一行 start，或 bytes.count）
        let nextStart: Int
        /// 该行是否为空行（去除空白后为空）
        let isBlank: Bool
        /// 前一行是否为空行（或是文件开头）
        let prevBlank: Bool
    }

    /// 单次扫描：规范化换行符 + 构建行信息表
    /// - 将 \r\n / \r 统一为 \n
    /// - 若 mergeBlankLines，连续 3+ 空行压缩为 2 行
    /// - 返回规范化后的字节数组 + 行信息列表
    private func buildLineInfos(from text: String) -> ([UInt8], [LineInfo]) {
        // 直接操作 UTF-8 字节，避免 String 的 Unicode 标量开销
        let srcBytes = Array(text.utf8)
        let count = srcBytes.count

        // 第一步：规范化换行符（\r\n → \n，\r → \n）
        var normalized = [UInt8]()
        normalized.reserveCapacity(count)
        var i = 0
        while i < count {
            let b = srcBytes[i]
            if b == 0x0D { // \r
                normalized.append(0x0A) // \n
                if i + 1 < count && srcBytes[i + 1] == 0x0A {
                    i += 2 // skip \r\n
                } else {
                    i += 1
                }
            } else {
                normalized.append(b)
                i += 1
            }
        }

        // 第二步：若需要合并空行，压缩连续 3+ 个 \n 为 2 个 \n
        if configuration.mergeBlankLines {
            var merged = [UInt8]()
            merged.reserveCapacity(normalized.count)
            var consecutiveNewlines = 0
            for b in normalized {
                if b == 0x0A {
                    consecutiveNewlines += 1
                    if consecutiveNewlines <= 2 {
                        merged.append(b)
                    }
                    // 超过 2 个连续 \n 则丢弃
                } else {
                    consecutiveNewlines = 0
                    merged.append(b)
                }
            }
            normalized = merged
        }

        // 第三步：构建行信息表
        let totalBytes = normalized.count
        var lineInfos = [LineInfo]()
        lineInfos.reserveCapacity(totalBytes / 30 + 16) // 预估行数

        var lineStart = 0
        var prevBlank = true // 文件开头视为前有空行

        while lineStart < totalBytes {
            // 找行尾（下一个 \n 或文件末尾）
            var lineEnd = lineStart
            while lineEnd < totalBytes && normalized[lineEnd] != 0x0A {
                lineEnd += 1
            }
            let nextStart = lineEnd < totalBytes ? lineEnd + 1 : totalBytes

            // 判断是否为空行（仅含空白字节）
            let isBlank = isLineBlank(normalized, from: lineStart, to: lineEnd)

            lineInfos.append(LineInfo(
                start: lineStart,
                end: lineEnd,
                nextStart: nextStart,
                isBlank: isBlank,
                prevBlank: prevBlank
            ))

            prevBlank = isBlank
            lineStart = nextStart
        }

        return (normalized, lineInfos)
    }

    /// 判断字节范围内是否全为空白（space 0x20, tab 0x09, 全角空格 0xE3 0x80 0x80）
    @inline(__always)
    private func isLineBlank(_ bytes: [UInt8], from start: Int, to end: Int) -> Bool {
        var i = start
        while i < end {
            let b = bytes[i]
            if b == 0x20 || b == 0x09 {
                i += 1
                continue
            }
            // 全角空格 UTF-8: E3 80 80
            if b == 0xE3 && i + 2 < end && bytes[i + 1] == 0x80 && bytes[i + 2] == 0x80 {
                i += 3
                continue
            }
            return false
        }
        return true
    }

    // MARK: - Private: Regex

    private func buildRegexGroups() -> [RegexGroup] {
        func compile(_ patterns: [String]) -> [NSRegularExpression] {
            patterns.compactMap { pattern in
                try? NSRegularExpression(
                    pattern: pattern,
                    options: [.anchorsMatchLines, .useUnicodeWordBoundaries]
                )
            }
        }
        return [
            RegexGroup(
                regexes: compile(Self.highConfidencePatterns),
                confidence: .high,
                triggerBytes: Self.highMediumTriggerBytes
            ),
        ]
    }

    private func buildExtraRegexes() -> [NSRegularExpression] {
        configuration.extraPatterns.compactMap { pattern in
            try? NSRegularExpression(
                pattern: pattern,
                options: [.anchorsMatchLines, .useUnicodeWordBoundaries]
            )
        }
    }

    // MARK: - Private: Matching

    private struct TitleMatch {
        /// 行在 lineInfos 中的索引
        let lineIndex: Int
        /// 清理后的标题文本
        let titleText: String
        /// 行首 UTF-8 字节偏移
        let byteOffset: Int64
        /// 匹配置信度
        let confidence: Confidence
    }

    private func findChapterMatches(in bytes: [UInt8], lineInfos: [LineInfo]) -> [TitleMatch] {
        var results = [TitleMatch]()
        results.reserveCapacity(64)

        let groups = compiledRegexGroups
        let extras = extraRegexes

        for (lineIdx, info) in lineInfos.enumerated() {
            // 跳过空行
            if info.isBlank { continue }

            // 首字节预过滤：若行首字节不在触发集合中，直接跳过
            let firstByte = bytes[info.start]
            if !Self.highMediumTriggerBytes.contains(firstByte) { continue }

            // 从字节切片构建行字符串（仅在可能匹配时才做）
            let lineBytes = bytes[info.start..<info.end]
            let lineContent = String(bytes: lineBytes, encoding: .utf8) ?? String(decoding: lineBytes, as: UTF8.self)

            let nsLine = lineContent as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)

            var matched = false
            for group in groups {
                if matched { break }
                // 组级首字节预过滤
                if !group.triggerBytes.contains(firstByte) { continue }
                for regex in group.regexes {
                    if let match = regex.firstMatch(in: lineContent, options: .anchored, range: fullRange) {
                        let matchedStr = nsLine.substring(with: match.range)
                        let cleaned = cleanTitle(matchedStr)
                        if !cleaned.isEmpty {
                            results.append(TitleMatch(
                                lineIndex: lineIdx,
                                titleText: cleaned,
                                byteOffset: Int64(info.start),
                                confidence: group.confidence
                            ))
                            matched = true
                            break
                        }
                    }
                }
            }

            if !matched && !extras.isEmpty {
                for regex in extras {
                    if let match = regex.firstMatch(in: lineContent, options: [], range: fullRange) {
                        let matchedStr = nsLine.substring(with: match.range)
                        let cleaned = cleanTitle(matchedStr)
                        if !cleaned.isEmpty {
                            results.append(TitleMatch(
                                lineIndex: lineIdx,
                                titleText: cleaned,
                                byteOffset: Int64(info.start),
                                confidence: .high
                            ))
                            break
                        }
                    }
                }
            }
        }

        return results
    }

    // MARK: - Private: Ambiguous Match Filtering

    private func filterAmbiguousMatches(_ matches: [TitleMatch], lineInfos: [LineInfo]) -> [TitleMatch] {
        guard !matches.isEmpty else { return [] }

        let cfg = configuration
        var validated = [TitleMatch]()
        validated.reserveCapacity(matches.count)

        for match in matches {
            switch match.confidence {
            case .high:
                validated.append(match)
            case .medium:
                if isMediumConfidenceValid(match) {
                    validated.append(match)
                }
            case .low:
                if isLowConfidenceValid(match, lineInfos: lineInfos) {
                    validated.append(match)
                }
            }
        }

        guard !validated.isEmpty else { return [] }

        if validated.count >= cfg.minChapterCountForFiltering {
            let lowCount = validated.filter { $0.confidence == .low }.count
            let lowRatio = Double(lowCount) / Double(validated.count)
            if lowRatio > cfg.ambiguousRatioThreshold {
                let withoutLow = validated.filter { $0.confidence != .low }
                if !withoutLow.isEmpty {
                    return filterBySequenceConsistency(withoutLow)
                }
            }
        }

        return filterBySequenceConsistency(validated)
    }

    private func isMediumConfidenceValid(_ match: TitleMatch) -> Bool {
        let title = match.titleText
        guard title.count >= 2 else { return false }
        return title.unicodeScalars.contains { scalar in
            let v = scalar.value
            return (v >= 0x4E00 && v <= 0x9FFF)
                || (v >= 0x0041 && v <= 0x005A)
                || (v >= 0x0061 && v <= 0x007A)
                || (v >= 0x0030 && v <= 0x0039)
                || (v >= 0xFF10 && v <= 0xFF19)
                || (v >= 0xFF21 && v <= 0xFF3A)
                || (v >= 0xFF41 && v <= 0xFF5A)
        }
    }

    /// 低置信度验证：利用已预计算的 prevBlank 和下一行 isBlank
    private func isLowConfidenceValid(_ match: TitleMatch, lineInfos: [LineInfo]) -> Bool {
        let title = match.titleText
        guard !title.isEmpty else { return false }

        let info = lineInfos[match.lineIndex]

        // 前一行是否为空行（已在 buildLineInfos 中预计算）
        let hasPrevBlank = info.prevBlank

        // 后一行是否为空行
        let nextIdx = match.lineIndex + 1
        let hasNextBlank: Bool
        if nextIdx < lineInfos.count {
            hasNextBlank = lineInfos[nextIdx].isBlank
        } else {
            hasNextBlank = true // 文件末尾
        }

        guard hasPrevBlank && hasNextBlank else { return false }

        // 纯数字标题范围检查
        let scalars = title.unicodeScalars
        var si = scalars.startIndex
        // 跳过 "第" (U+7B2C) 和空白
        while si < scalars.endIndex {
            let v = scalars[si].value
            if v == 0x7B2C || v == 0x20 || v == 0x3000 {
                scalars.formIndex(after: &si)
            } else {
                break
            }
        }
        let stripped = scalars[si...]
        let isPureNumeric = !stripped.isEmpty && stripped.allSatisfy {
            $0.value >= 0x30 && $0.value <= 0x39
        }
        if isPureNumeric {
            // 数字过长（超过 4 位）直接拒绝，避免 Int 溢出时跳过范围检查
            guard stripped.count <= 4 else { return false }
            guard let num = Int(String(stripped)), num >= 1 && num <= 9999 else { return false }
        }
        return true
    }

    private func filterBySequenceConsistency(_ matches: [TitleMatch]) -> [TitleMatch] {
        let highCount = matches.filter { $0.confidence == .high }.count
        guard highCount >= 3 else { return matches }
        let highRatio = Double(highCount) / Double(matches.count)
        guard highRatio > 0.5 else { return matches }

        // 高置信度章节占主导时，直接丢弃所有中/低置信度匹配
        // 避免"数字+点+长文本"前言行被误识别为章节
        return matches.filter { $0.confidence == .high }
    }

    // MARK: - Private: Build ChapterItems

    private func buildChapterItems(from bytes: [UInt8], matches: [TitleMatch]) -> [ChapterItem] {
        var items = [ChapterItem]()
        items.reserveCapacity(matches.count)
        let totalBytes = Int64(bytes.count)
        let maxLen = configuration.sketchMaxLength

        for i in matches.indices {
            let match = matches[i]
            let endByteOffset: Int64 = (i + 1 < matches.count) ? matches[i + 1].byteOffset : totalBytes
            let byteLength = endByteOffset - match.byteOffset

            // 摘要从标题行之后开始
            // 找到标题行的 nextStart（即正文起始字节）
            // match.byteOffset 是行首，需要找到行末（含换行符）之后
            let titleLineEnd = findLineEnd(bytes, from: Int(match.byteOffset))
            let contentStart = titleLineEnd
            let contentEnd = Int(endByteOffset)

            let sketch = makeSketchFromBytes(bytes, from: contentStart, to: contentEnd, maxLen: maxLen)

            items.append(ChapterItem(
                title: match.titleText,
                offset: match.byteOffset,
                length: byteLength,
                sketchText: sketch
            ))
        }
        return items
    }

    /// 找到从 start 开始的行末（换行符之后的位置，即下一行起始）
    @inline(__always)
    private func findLineEnd(_ bytes: [UInt8], from start: Int) -> Int {
        var i = start
        let count = bytes.count
        while i < count && bytes[i] != 0x0A { i += 1 }
        return i < count ? i + 1 : count
    }

    // MARK: - Private: Sketch（直接操作字节，避免重复行扫描）

    private func makeSketchFromBytes(_ bytes: [UInt8], from start: Int, to end: Int, maxLen: Int) -> String {
        guard start < end else { return "" }

        var result = ""
        result.reserveCapacity(maxLen + 4)

        var lineStart = start
        var charCount = 0

        while lineStart < end && charCount < maxLen {
            // 找行尾
            var lineEnd = lineStart
            while lineEnd < end && bytes[lineEnd] != 0x0A { lineEnd += 1 }

            // 提取行内容（去除首尾空白字节）
            var trimStart = lineStart
            var trimEnd = lineEnd
            while trimStart < trimEnd && (bytes[trimStart] == 0x20 || bytes[trimStart] == 0x09) {
                trimStart += 1
            }
            while trimEnd > trimStart && (bytes[trimEnd - 1] == 0x20 || bytes[trimEnd - 1] == 0x09) {
                trimEnd -= 1
            }

            if trimStart < trimEnd {
                let lineSlice = bytes[trimStart..<trimEnd]
                let lineStr = String(bytes: lineSlice, encoding: .utf8) ?? String(decoding: lineSlice, as: UTF8.self)
                if !lineStr.isEmpty {
                    if result.isEmpty {
                        result = lineStr
                    } else {
                        result += " "
                        result += lineStr
                    }
                    charCount = result.count
                }
            }

            lineStart = lineEnd < end ? lineEnd + 1 : end
        }

        if result.count <= maxLen {
            return result
        }
        let endIdx = result.index(result.startIndex, offsetBy: maxLen)
        return String(result[..<endIdx]) + "…"
    }

    // MARK: - Private: Title Cleaning

    private func cleanTitle(_ raw: String) -> String {
        let scalars = raw.unicodeScalars

        @inline(__always)
        func isTrimmable(_ v: UInt32) -> Bool {
            v == 0x20 || v == 0x09 || v == 0x0A || v == 0x0D || v == 0x3000
        }

        var startIdx = scalars.startIndex
        while startIdx < scalars.endIndex && isTrimmable(scalars[startIdx].value) {
            scalars.formIndex(after: &startIdx)
        }
        guard startIdx < scalars.endIndex else { return "" }

        var endIdx = scalars.endIndex
        while endIdx > startIdx {
            let prevIdx = scalars.index(before: endIdx)
            if isTrimmable(scalars[prevIdx].value) { endIdx = prevIdx } else { break }
        }

        var out = String.UnicodeScalarView()
        out.reserveCapacity(scalars.distance(from: startIdx, to: endIdx))
        var prevWasSpace = false
        var idx = startIdx
        while idx < endIdx {
            let scalar = scalars[idx]
            let v = scalar.value
            let isSpace = v == 0x20 || v == 0x09 || v == 0x3000
            if isSpace {
                if !prevWasSpace { out.append(Unicode.Scalar(0x20)!) }
                prevWasSpace = true
            } else {
                out.append(scalar)
                prevWasSpace = false
            }
            scalars.formIndex(after: &idx)
        }
        return String(out)
    }

    // MARK: - Private: File Reading

    private func readText(from url: URL) throws -> String {
        let data = try Data(contentsOf: url)

        if data.count >= 2 {
            if data[0] == 0xFF && data[1] == 0xFE {
                if let text = String(data: data, encoding: .utf16LittleEndian) { return text }
            } else if data[0] == 0xFE && data[1] == 0xFF {
                if let text = String(data: data, encoding: .utf16BigEndian) { return text }
            }
        }
        if data.count >= 3 && data[0] == 0xEF && data[1] == 0xBB && data[2] == 0xBF {
            if let text = String(data: data, encoding: .utf8) { return text }
        }

        let encodings: [String.Encoding] = [
            .utf8,
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))),
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.big5_HKSCS_1999.rawValue))),
            .init(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.shiftJIS.rawValue))),
        ]

        for encoding in encodings {
            if let text = String(data: data, encoding: encoding) {
                return text
            }
        }

        return String(decoding: data, as: UTF8.self)
    }
}

// MARK: - Convenience Extensions

extension ChapterParser {

    static func parse(text: String) -> [(title: String, offset: Int64, length: Int64, sketchText: String)] {
        ChapterParser().parse(text: text)
    }

    static func parse(fileURL url: URL) throws -> [(title: String, offset: Int64, length: Int64, sketchText: String)] {
        try ChapterParser().parse(fileURL: url)
    }
}

// MARK: - ChapterItem: CustomStringConvertible

extension ChapterParser.ChapterItem: CustomStringConvertible {
    var description: String {
        let preview = sketchText.isEmpty ? "(空)" : String(sketchText.prefix(30))
        return "ChapterItem(title: \"\(title)\", offset: \(offset), length: \(length), sketch: \"\(preview)\")"
    }
}

// MARK: - ChapterItem: Equatable

extension ChapterParser.ChapterItem: Equatable {
    static func == (lhs: ChapterParser.ChapterItem, rhs: ChapterParser.ChapterItem) -> Bool {
        lhs.offset == rhs.offset && lhs.length == rhs.length && lhs.title == rhs.title
    }
}

// MARK: - ChapterItem: Hashable

extension ChapterParser.ChapterItem: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(offset)
        hasher.combine(length)
        hasher.combine(title)
    }
}

