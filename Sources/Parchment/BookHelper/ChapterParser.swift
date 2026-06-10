import Foundation

// MARK: - ChapterParser

/// 小说章节解析器
/// 支持标准与非标准章节标题的全面解析
///
/// ⚠️ 重要：返回的 offset/length 均基于**规范化后**的 UTF-8 字节偏移，
/// 而非原始文件字节偏移。规范化操作包括：
///   - 将 CRLF/CR 换行符统一转换为 LF（\n）
///   - 每行末尾追加 LF（包括原始文件末尾无换行符的最后一行）
///   - 可选：合并连续空行（mergeBlankLines=true 时）
/// 因此，对于 CRLF 文件，normalized 字节数 < 原始字节数；
/// 对于末尾无换行符的文件，normalized 字节数 = 原始字节数 + 1。
/// 调用者若需要基于原始文件字节的偏移，需自行处理规范化差异。
final class ChapterParser {

    // MARK: - Public Types

    /// 章节信息
    struct ChapterItem {
        /// 章节标题（已清理首尾空白）
        let title: String
        /// 章节在**规范化后** UTF-8 字节流中的起始偏移量
        /// 注意：基于规范化字节（CRLF→LF，每行末尾追加LF），非原始文件字节偏移
        let offset: Int64
        /// 章节在规范化后 UTF-8 字节流中的字节长度
        /// 所有章节的 length 之和等于 normalizedBytes.count
        let length: Int64
        /// 章节正文摘要（跳过标题行，取前 N 字符）
        let sketchText: String
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
        case high, medium, low
    }

    // MARK: - Private Properties

    private let configuration: Configuration
    /// 编译好的正则列表（init 时编译，线程安全）
    private let compiledRegexGroups: [RegexGroup]
    /// 额外正则（不分组，每行都尝试）
    private let extraRegexes: [NSRegularExpression]

    // MARK: - Private: Regex Group

    /// 正则分组：按置信度分组
    private struct RegexGroup {
        let regexes: [NSRegularExpression]
        let confidence: Confidence
        /// 该组正则可能匹配的行首字节集合（用于快速预过滤）
        let triggerBytes: Set<UInt8>
    }

    // MARK: - Builtin Patterns

    // 高置信度模式
    private static let highConfidencePatterns: [String] = [
        // ── 1. 卷+章复合结构 ──
        #"^[\s\u3000]*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[卷部册]\s*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[章节回](\s+[^\n\r]{0,40}|[\s\u3000]*$)"#,
        // ── 2. 书名号复合标题 ──
        #"^[\s\u3000]*《[^》\n\r]{1,40}》\s*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[章节回卷部篇集幕话折则讲段期册](\s+[^\n\r]{0,40}|[\s\u3000]*$)"#,
        // ── 3. 标准中文章节 ──
        #"^[\s\u3000]*第\s*[零一二三四五六七八九十百千万亿\d０-９]+\s*[章节回卷部篇集幕话折则讲段期册](\s+[^\n\r]{0,60}|[\s\u3000]*$)"#,
        // ── 4. 带序号的中文章节变体（章/节/回 + 数字）──
        #"^[\s\u3000]*[章节回卷部篇集幕话折则讲段期册]\s*[零一二三四五六七八九十百千万亿\d０-９]+(\s+[^\n\r]{0,60}|[\s\u3000]*$)"#,
        // ── 5. 特殊固定标题词 ──
        // 后缀规则：
        //   a) 空白后跟任意内容（"番外 某某的故事"）
        //   b) 紧跟数字汉字序号（"番外一"、"序章一"）或非汉字字符（"番外1"、"尾声（完）"）
        //   c) 行尾（单独一词）
        // 不允许紧跟普通汉字，避免误报"前言内容"、"尾声渐起"等正文句子。
        // 注意：[^\u4E00-\u9FFF\u3400-\u4DBF\n\r] 排除 CJK 基本区和扩展 A，
        //       NSRegularExpression（ICU）的 \uXXXX 仅支持 BMP（4位十六进制），
        //       CJK 扩展 B/C/D/E/F（U+20000 以上）无法用 \uXXXX 表示，
        //       但这类字符在实际小说标题中极为罕见，可接受此边界情况。
        #"^[\s\u3000]*(序章|楔子|尾声|番外|后记|前言|引子|正文开始|附录|结语|终章|外传|插曲|间章|卷首语|卷尾语|序言|跋|题记|作者的话|作者有话说|作者碎碎念|作者按|特别篇|特别章|IF线|IF章|Side\s*Story|Side\s*Chapter)([\s\u3000]+[^\n\r]{0,60}|[零一二三四五六七八九十百千万\d０-９][^\n\r]{0,59}|[^\u4E00-\u9FFF\u3400-\u4DBF\n\r][^\n\r]{0,59}|[\s\u3000]*$)"#,
        // ── 6. 英文 Chapter / Part / Volume 等 ──
        // 要求后跟数字开头的标识符（如 "1"、"1-2"、"1.5"、"I"、"II"），
        // 或 prologue/epilogue/interlude/appendix 后跟字母序号（如 "A"、"B"）。
        // 禁止纯小写英文单词（如 "of"、"one"、"the"），避免 "part of"、"volume of" 等误报。
        // 规则：后跟标识符必须以数字或大写字母开头（\d 或 [A-Z]），
        //       或者是 prologue/epilogue/interlude/appendix 这类本身即完整标题的词（允许无后缀）。
        #"(?i)^[\s\u3000]*(chapter|chap|part|volume|vol|episode)\s+\d[\d\-\.a-zA-Z]{0,19}(\s+[^\n\r]{0,60})?"#,
        #"(?i)^[\s\u3000]*(prologue|epilogue|interlude|appendix)(\s+[\d\-\.a-zA-Z]{1,20}(\s+[^\n\r]{0,60})?)?"#,
    ]

    // 中置信度模式
    private static let mediumConfidencePatterns: [String] = [
        // ── 7. 罗马数字章节 ──
        // 使用 (?=[MDCLXVI]) 前瞻确保行首确实有罗马数字字符，再用完整正则匹配。
        // 注意：D 单独出现时（如 "D. test"）会被 (?=[MDCLXVI]) 通过，但 D{0,3} 可匹配 "D"，
        // 产生误报。为避免此问题，要求匹配结果捕获组2非空（通过 (?!\s*[\.、]) 排除空匹配）。
        // 实际上 D 单独是有效罗马数字（500），C（100）、L（50）、M（1000）同理，
        // 这些单字母罗马数字在章节标题中是合理的（如 "C. 第三章"），保留匹配。
        // 真正需要排除的是：行首为普通英文单词首字母（如 "Do"、"Can"、"Let"、"Make"）
        // 但这些词不在 [MDCLXVI] 的有效罗马数字组合中（如 "Do" → D+o，o 不是罗马数字字符，
        // 正则只匹配 D 后面的 [\.、]，"Do." 中 D 后跟 o 不是 [\.、]，不匹配）。
        // 结论：当前正则对单字母罗马数字（C/D/L/M/V/I/X）的匹配是预期行为。
        #"^[\s\u3000]*((?=[MDCLXVI])(M{0,4}(?:CM|CD|D?C{0,3})(?:XC|XL|L?X{0,3})(?:IX|IV|V?I{0,3})))\s*[\.、]\s*[^\n\r]{1,60}"#,
        // ── 8a. 中文数字序号行（有括号）──
        #"^[\s\u3000]*[（\(【\[〔][零一二三四五六七八九十百千万]+[）\)】\]〕]\s*[^\n\r]{0,60}"#,
        // ── 8b. 中文数字序号行（无括号，仅允许顿号/中文冒号，要求后跟至少2个汉字/字母，避免误匹配正文）──
        #"^[\s\u3000]*[零一二三四五六七八九十百千万]+\s*[、：]\s*[\u4E00-\u9FFF\u3400-\u4DBFa-zA-Z]{2}[^\n\r]{0,58}"#,
        // ── 9a. 阿拉伯数字序号行（有括号）──
        #"^[\s\u3000]*[（\(【\[〔]\d{1,4}[）\)】\]〕]\s*[^\n\r]{0,60}"#,
        // ── 9b. 阿拉伯数字序号行（无括号，仅允许顿号/中文冒号，排除英文句点避免误匹配正文）──
        #"^[\s\u3000]*\d{1,4}\s*[、：]\s*[^\n\r]{1,60}"#,
        // ── 10. 全角数字序号行（有括号，避免与 9b 重叠）──
        #"^[\s\u3000]*[（\(【\[〔][０-９]{1,4}[）\)】\]〕]\s*[^\n\r]{0,60}"#,
    ]

    // 低置信度模式
    private static let lowConfidencePatterns: [String] = [
        // ── 11. 纯数字独占一行（最多 4 位，与 isLowConfidenceValid 范围检查对齐）──
        #"^[\s\u3000]*第?\s*\d{1,4}\s*$"#,
    ]

    // MARK: - 首字节触发集合（预过滤用）

    /// 高/中置信度行首可能出现的 UTF-8 首字节
    /// 涵盖：汉字/全角符号、ASCII 字母、ASCII 数字、空白、括号、分隔线
    private static let highMediumTriggerBytes: Set<UInt8> = {
        var bytes = Set<UInt8>()
        // 汉字/全角符号首字节（CJK 及全角标点）
        for b: UInt8 in 0xE3...0xEF { bytes.insert(b) }
        // ASCII 大写字母（英文章节 Chapter/Part/Prologue 等）
        for b: UInt8 in 0x41...0x5A { bytes.insert(b) }
        // ASCII 小写字母
        for b: UInt8 in 0x61...0x7A { bytes.insert(b) }
        // ASCII 数字（数字序号）
        for b: UInt8 in 0x30...0x39 { bytes.insert(b) }
        // 空白（行首可能有缩进）
        bytes.insert(0x20) // space
        bytes.insert(0x09) // tab
        // ASCII 括号
        bytes.insert(0x28) // (
        bytes.insert(0x5B) // [
        // 分隔线字符
        bytes.insert(0x2D) // -
        bytes.insert(0x3D) // =
        bytes.insert(0x2A) // *
        return bytes
    }()

    /// 低置信度行首触发字节（纯数字/第+数字）
    private static let lowTriggerBytes: Set<UInt8> = {
        var bytes = Set<UInt8>()
        for b: UInt8 in 0x30...0x39 { bytes.insert(b) }
        bytes.insert(0x20)
        bytes.insert(0x09)
        // "第"(U+7B2C) UTF-8 编码为 0xE7 0xAC 0xAC，首字节为 0xE7
        // 注意：0xE7 是 UTF-8 三字节序列的首字节之一，并非仅"第"字独有，
        // 但低置信度模式（^[\s\u3000]*第?\s*\d{1,4}\s*$）本身会精确过滤，
        // 此处仅作粗粒度预过滤以减少正则调用次数。
        bytes.insert(0xE7)
        // 全角空格(U+3000) UTF-8 编码为 0xE3 0x80 0x80，首字节为 0xE3
        bytes.insert(0xE3)
        return bytes
    }()

    /// 所有触发字节的并集（预计算，避免每次调用重复合并）
    private static let allTriggerBytes: Set<UInt8> = highMediumTriggerBytes.union(lowTriggerBytes)

    // MARK: - Init

    init(configuration: Configuration = .default) {
        self.configuration = configuration
        // 在 init 中编译正则，避免 lazy var 的线程不安全问题
        let regexOptions: NSRegularExpression.Options = [.anchorsMatchLines, .useUnicodeWordBoundaries]
        func compile(_ patterns: [String]) -> [NSRegularExpression] {
            patterns.compactMap { try? NSRegularExpression(pattern: $0, options: regexOptions) }
        }
        self.compiledRegexGroups = [
            RegexGroup(regexes: compile(Self.highConfidencePatterns),  confidence: .high,   triggerBytes: Self.highMediumTriggerBytes),
            RegexGroup(regexes: compile(Self.mediumConfidencePatterns), confidence: .medium, triggerBytes: Self.highMediumTriggerBytes),
            RegexGroup(regexes: compile(Self.lowConfidencePatterns),    confidence: .low,    triggerBytes: Self.lowTriggerBytes),
        ]
        self.extraRegexes = configuration.extraPatterns.compactMap {
            try? NSRegularExpression(pattern: $0, options: regexOptions)
        }
    }

    // MARK: - Public API

    func parseItems(from text: String) -> [ChapterItem] {
        guard !text.isEmpty else { return [] }
        // 单次 UTF-8 字节扫描：规范化换行 + 行分割 + 匹配
        let (normalizedBytes, lineInfos) = buildLineInfos(from: text)
        // 扫描章节标题
        let matches = findChapterMatches(in: normalizedBytes, lineInfos: lineInfos)
        // 过滤模糊章节
        let filtered = filterAmbiguousMatches(matches, lineInfos: lineInfos)
        guard !filtered.isEmpty else {
            let sketch = makeSketchFromBytes(normalizedBytes, from: 0, to: normalizedBytes.count, maxLen: configuration.sketchMaxLength)
            return [ChapterItem(title: "正文", offset: 0, length: Int64(normalizedBytes.count), sketchText: sketch)]
        }
        return buildChapterItems(from: normalizedBytes, matches: filtered)
    }

    // MARK: - Private: Line Info

    private struct LineInfo {
        let start: Int
        /// 换行符（0x0A）的字节索引（即行内容结束位置，exclusive）
        /// bytes[start..<end] 为行内容（不含末尾 0x0A 换行符）
        /// 注意：bytes[end] == 0x0A（换行符本身），end == nextStart - 1
        let end: Int
        /// 换行符（0x0A）之后的字节索引（即下一行的 start，或 bytes.count）
        /// nextStart == end + 1（因为 normalized 中每行末尾追加了一个 0x0A）
        let nextStart: Int
        let isBlank: Bool
        let prevBlank: Bool
    }

    /// 单次扫描：规范化换行符 + 合并空行 + 构建行信息表
    private func buildLineInfos(from text: String) -> ([UInt8], [LineInfo]) {
        let srcBytes = Array(text.utf8)
        let count = srcBytes.count
        let doMerge = configuration.mergeBlankLines

        var normalized = [UInt8]()
        normalized.reserveCapacity(count)
        var lineInfos = [LineInfo]()
        lineInfos.reserveCapacity(count / 30 + 16)

        var i = 0
        var prevBlank = true
        var consecutiveBlankLines = 0

        while i < count {
            let lineStart = normalized.count

            while i < count {
                let b = srcBytes[i]
                if b == 0x0D {
                    i += (i + 1 < count && srcBytes[i + 1] == 0x0A) ? 2 : 1
                    break
                } else if b == 0x0A {
                    i += 1
                    break
                } else {
                    normalized.append(b)
                    i += 1
                }
            }

            let lineEnd = normalized.count
            // 统一通过 isLineBlank 判断（同时处理半角空白和全角空格 U+3000）
            let isBlank = isLineBlank(normalized, from: lineStart, to: lineEnd)

            if doMerge && isBlank {
                consecutiveBlankLines += 1
                if consecutiveBlankLines > 2 {
                    normalized.removeLast(lineEnd - lineStart)
                    // 必须在 continue 前更新 prevBlank，否则后续行的 prevBlank 字段将记录错误值
                    prevBlank = true
                    continue
                }
            } else {
                consecutiveBlankLines = 0
            }

            // lineContentEnd：行内容结束位置（换行符的字节索引，exclusive 切片不含换行符）
            let lineContentEnd = normalized.count
            normalized.append(0x0A)

            lineInfos.append(LineInfo(
                start: lineStart,
                end: lineContentEnd,
                nextStart: normalized.count,
                isBlank: isBlank,
                prevBlank: prevBlank
            ))
            prevBlank = isBlank
        }
        return (normalized, lineInfos)
    }

    @inline(__always)
    private func isLineBlank(_ bytes: [UInt8], from start: Int, to end: Int) -> Bool {
        var i = start
        while i < end {
            let b = bytes[i]
            if b == 0x20 || b == 0x09 { i += 1; continue }
            if b == 0xE3 && i + 3 <= end && bytes[i + 1] == 0x80 && bytes[i + 2] == 0x80 { i += 3; continue }
            return false
        }
        return true
    }

    // MARK: - Private: Matching

    private struct TitleMatch {
        let lineIndex: Int
        let titleText: String
        let byteOffset: Int64
        let confidence: Confidence
    }

    private func findChapterMatches(in bytes: [UInt8], lineInfos: [LineInfo]) -> [TitleMatch] {
        var results = [TitleMatch]()
        results.reserveCapacity(64)

        for (lineIdx, info) in lineInfos.enumerated() {
            if info.isBlank { continue }

            let firstByte = bytes[info.start]
            if !Self.allTriggerBytes.contains(firstByte) { continue }

            let lineBytes = bytes[info.start..<info.end]
            let lineContent = String(bytes: lineBytes, encoding: .utf8) ?? String(decoding: lineBytes, as: UTF8.self)
            let nsLine = lineContent as NSString
            let fullRange = NSRange(location: 0, length: nsLine.length)

            var matched = false
            for group in compiledRegexGroups {
                if matched { break }
                if !group.triggerBytes.contains(firstByte) { continue }
                for regex in group.regexes {
                    if let match = regex.firstMatch(in: lineContent, options: .anchored, range: fullRange) {
                        let cleaned = cleanTitle(nsLine.substring(with: match.range))
                        if !cleaned.isEmpty {
                            results.append(TitleMatch(lineIndex: lineIdx, titleText: cleaned, byteOffset: Int64(info.start), confidence: group.confidence))
                            matched = true
                            break
                        }
                    }
                }
            }

            if !matched && !extraRegexes.isEmpty {
                for regex in extraRegexes {
                    // 使用 .anchored 保持与内置正则一致的行为
                    if let match = regex.firstMatch(in: lineContent, options: .anchored, range: fullRange) {
                        let cleaned = cleanTitle(nsLine.substring(with: match.range))
                        if !cleaned.isEmpty {
                            results.append(TitleMatch(lineIndex: lineIdx, titleText: cleaned, byteOffset: Int64(info.start), confidence: .high))
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

        var validated = [TitleMatch]()
        validated.reserveCapacity(matches.count)

        for match in matches {
            switch match.confidence {
            case .high:
                validated.append(match)
            case .medium:
                if isMediumConfidenceValid(match) { validated.append(match) }
            case .low:
                if isLowConfidenceValid(match, lineInfos: lineInfos) { validated.append(match) }
            }
        }

        guard !validated.isEmpty else { return [] }

        // 当低置信度章节占比超过阈值时，直接丢弃所有低置信度结果（无需再调用 filterLowConfidenceByHighRatio）
        // 注意：ambiguousRatioThreshold 仅针对 .low 置信度，.medium 置信度不受此阈值影响，
        //       因为 medium 置信度已经过 isMediumConfidenceValid 验证，误报率较低。
        // 注意：withoutLow 为空时也直接返回空数组，让调用者生成"正文"章节，
        //       而不是继续走 filterLowConfidenceByHighRatio 保留所有低置信度章节。
        if validated.count >= configuration.minChapterCountForFiltering {
            let lowCount = validated.filter { $0.confidence == .low }.count
            if Double(lowCount) / Double(validated.count) > configuration.ambiguousRatioThreshold {
                return validated.filter { $0.confidence != .low }
            }
        }

        // 当高置信度章节占多数时，过滤掉低置信度噪声（medium 置信度不受此过滤影响）
        return filterLowConfidenceByHighRatio(validated)
    }

    private func isMediumConfidenceValid(_ match: TitleMatch) -> Bool {
        let title = match.titleText
        guard title.count >= 2 else { return false }
        return title.unicodeScalars.contains { scalar in
            let v = scalar.value
            return (v >= 0x4E00 && v <= 0x9FFF)   // CJK 基本区
            || (v >= 0x3400 && v <= 0x4DBF)        // CJK 扩展 A
            || (v >= 0x20000 && v <= 0x2A6DF)      // CJK 扩展 B
            || (v >= 0x2A700 && v <= 0x2CEAF)      // CJK 扩展 C/D/E
            || (v >= 0x2CEB0 && v <= 0x2EBEF)      // CJK 扩展 F
            || (v >= 0xF900 && v <= 0xFAFF)        // CJK 兼容汉字
            || (v >= 0x0041 && v <= 0x005A)        // ASCII 大写字母
            || (v >= 0x0061 && v <= 0x007A)        // ASCII 小写字母
            || (v >= 0x0030 && v <= 0x0039)        // ASCII 数字
            || (v >= 0xFF10 && v <= 0xFF19)        // 全角数字
            || (v >= 0xFF21 && v <= 0xFF3A)        // 全角大写字母
            || (v >= 0xFF41 && v <= 0xFF5A)        // 全角小写字母
        }
    }

    private func isLowConfidenceValid(_ match: TitleMatch, lineInfos: [LineInfo]) -> Bool {
        let title = match.titleText
        guard !title.isEmpty else { return false }

        let info = lineInfos[match.lineIndex]
        let nextIdx = match.lineIndex + 1
        let hasNextBlank = nextIdx < lineInfos.count ? lineInfos[nextIdx].isBlank : true

        guard info.prevBlank && hasNextBlank else { return false }

        let scalars = title.unicodeScalars
        var si = scalars.startIndex
        while si < scalars.endIndex {
            let v = scalars[si].value
            if v == 0x7B2C || v == 0x20 || v == 0x3000 { scalars.formIndex(after: &si) } else { break }
        }
        let stripped = scalars[si...]
        // stripped 为空（如标题仅含"第 "）时拒绝
        guard !stripped.isEmpty else { return false }
        let isPureNumeric = stripped.allSatisfy { $0.value >= 0x30 && $0.value <= 0x39 }
        // 低置信度模式只匹配纯数字或"第+数字"，非纯数字时拒绝
        guard isPureNumeric else { return false }
        guard stripped.count <= 4 else { return false }
        guard let num = Int(String(stripped)), num >= 1 && num <= 9999 else { return false }
        return true
    }

    /// 当高置信度章节占多数时，过滤掉低置信度的噪声匹配。
    /// 注意：此函数按置信度过滤，并非做章节序号连续性校验。
    private func filterLowConfidenceByHighRatio(_ matches: [TitleMatch]) -> [TitleMatch] {
        let highCount = matches.filter { $0.confidence == .high }.count
        guard highCount >= 3 else { return matches }
        guard Double(highCount) / Double(matches.count) > 0.5 else { return matches }
        return matches.filter { $0.confidence != .low }
    }

    // MARK: - Private: Build ChapterItems

    private func buildChapterItems(from bytes: [UInt8], matches: [TitleMatch]) -> [ChapterItem] {
        var items = [ChapterItem]()
        items.reserveCapacity(matches.count + 1)
        let totalBytes = Int64(bytes.count)
        let maxLen = configuration.sketchMaxLength

        // 若第一个章节不从文件头开始，则在首位插入"正文"段落（前言/版权页等）
        if let first = matches.first, first.byteOffset > 0 {
            let sketch = makeSketchFromBytes(bytes, from: 0, to: Int(first.byteOffset), maxLen: maxLen)
            items.append(ChapterItem(title: "正文", offset: 0, length: first.byteOffset, sketchText: sketch))
        }

        for i in matches.indices {
            let match = matches[i]
            let endByteOffset: Int64 = (i + 1 < matches.count) ? matches[i + 1].byteOffset : totalBytes
            let titleLineEnd = findLineEnd(bytes, from: Int(match.byteOffset))
            let sketch = makeSketchFromBytes(bytes, from: titleLineEnd, to: Int(endByteOffset), maxLen: maxLen)
            items.append(ChapterItem(
                title: match.titleText,
                offset: match.byteOffset,
                length: endByteOffset - match.byteOffset,
                sketchText: sketch
            ))
        }
        return items
    }

    @inline(__always)
    private func findLineEnd(_ bytes: [UInt8], from start: Int) -> Int {
        var i = start
        while i < bytes.count && bytes[i] != 0x0A { i += 1 }
        return i < bytes.count ? i + 1 : bytes.count
    }

    // MARK: - Private: Sketch

    private func makeSketchFromBytes(_ bytes: [UInt8], from start: Int, to end: Int, maxLen: Int) -> String {
        guard start < end else { return "" }

        var result = ""
        result.reserveCapacity(maxLen + 4)
        var lineStart = start
        var charCount = 0

        while lineStart < end && charCount < maxLen {
            var lineEnd = lineStart
            while lineEnd < end && bytes[lineEnd] != 0x0A { lineEnd += 1 }

            var trimStart = lineStart
            var trimEnd = lineEnd

            // 去除行首空白（半角空格、Tab、全角空格 U+3000 = 0xE3 0x80 0x80）
            while trimStart < trimEnd {
                let b = bytes[trimStart]
                if b == 0x20 || b == 0x09 {
                    trimStart += 1
                } else if b == 0xE3 && trimStart + 3 <= trimEnd
                            && bytes[trimStart + 1] == 0x80 && bytes[trimStart + 2] == 0x80 {
                    trimStart += 3
                } else {
                    break
                }
            }

            // 去除行尾空白
            while trimEnd > trimStart {
                if bytes[trimEnd - 1] == 0x20 || bytes[trimEnd - 1] == 0x09 {
                    trimEnd -= 1
                } else if trimEnd - 3 >= trimStart
                            && bytes[trimEnd - 3] == 0xE3
                            && bytes[trimEnd - 2] == 0x80
                            && bytes[trimEnd - 1] == 0x80 {
                    trimEnd -= 3
                } else {
                    break
                }
            }
            if trimStart < trimEnd {
                let lineSlice = bytes[trimStart..<trimEnd]
                let lineStr = String(bytes: lineSlice, encoding: .utf8) ?? String(decoding: lineSlice, as: UTF8.self)
                if !lineStr.isEmpty {
                    // 行间分隔符占 1 个字符，需计入剩余空间
                    let separator = result.isEmpty ? "" : " "
                    let separatorLen = separator.isEmpty ? 0 : 1
                    let remaining = maxLen - charCount - separatorLen
                    if remaining <= 0 { break }
                    result += separator
                    if lineStr.count <= remaining {
                        result += lineStr
                        charCount += separatorLen + lineStr.count
                    } else {
                        // 只追加恰好填满 maxLen 的部分，避免拼接超长内容后再截断
                        result += String(lineStr[..<lineStr.index(lineStr.startIndex, offsetBy: remaining)])
                        charCount = maxLen
                        break
                    }
                }
            }

            lineStart = lineEnd < end ? lineEnd + 1 : end
        }

        return result
    }

    // MARK: - Private: Title Cleaning

    /// 清理标题首尾空白，并将内部连续空白（含全角空格 U+3000）压缩为单个半角空格。
    /// 零宽字符（U+200B/U+FEFF/U+200D/U+200C/U+00AD）会被完全移除。
    /// 内部换行符（U+000A/U+000D）也会被完全移除（防御性处理，标题理论上不含换行符）。
    private func cleanTitle(_ raw: String) -> String {
        let scalars = raw.unicodeScalars

        @inline(__always)
        func isTrimmable(_ v: UInt32) -> Bool {
            v == 0x20 || v == 0x09 || v == 0x0A || v == 0x0D || v == 0x3000 || v == 0x00A0
            || v == 0x200B || v == 0xFEFF || v == 0x200D || v == 0x200C || v == 0x00AD
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
            // 零宽字符和换行符：完全移除（不转为空格，不影响 prevWasSpace）
            if v == 0x200B || v == 0xFEFF || v == 0x200D || v == 0x200C || v == 0x00AD
                || v == 0x0A || v == 0x0D {
                scalars.formIndex(after: &idx)
                continue
            }
            let isSpace = v == 0x20 || v == 0x09 || v == 0x3000 || v == 0x00A0
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
}

// MARK: - Convenience

extension ChapterParser {
    
    /// parseWith
    /// - Parameter text: String
    /// - Returns: [(title: String, offset: Int64, length: Int64, sketchText: String)]
    internal static func parseWith(_ text: String) -> [(title: String, offset: Int64, length: Int64, sketchText: String)] {
        ChapterParser().parseItems(from: text).map { ($0.title, $0.offset, $0.length, $0.sketchText) }
    }
}

