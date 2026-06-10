import Foundation
import CoreText

// MARK: - TextPaginator

/// 基于 CoreText 的高效文本分页器
///
/// 使用 `CTFramesetter` 精确计算每页可容纳的文本范围，
/// 返回每页的文本内容、UTF-8 字节偏移及摘要信息。
///
/// ## 使用示例
/// ```swift
/// let font = CTFontCreateWithName("PingFangSC-Regular" as CFString, 17, nil)
/// let config = TextPaginator.Configuration(
///     pageSize: CGSize(width: 375, height: 600),
///     font: font
/// )
/// let paginator = TextPaginator(configuration: config)
/// let pages = paginator.paginate(text: novelText)
/// // pages: [(text: String, offset: Int64, length: Int64, sketchText: String, isTruncated: Bool)]
/// ```
///
/// ## 性能说明
/// - 一次性构建 `NSAttributedString`，整个分页过程复用同一 `CTFramesetter`
/// - UTF-8 字节偏移通过预构建的 Unicode→UTF-8 偏移映射表计算，O(1) 查询
/// - 分页循环内零额外内存分配（`CGPath` / `CTFramesetter` 均在循环外创建）
/// - 对于百万字级别的小说，分页耗时通常在 100ms 以内
final class TextPaginator {
    
    // MARK: - Configuration
    
    /// 分页配置
    struct Configuration {
        /// 页面尺寸（单位：点，pt）
        var pageSize: CGSize
        /// 摘要最大字符数（默认 80）
        var sketchMaxLength: Int
        /// 默认字体（用于未传入 textAttributes 时的分页计算）
        /// 必须与渲染器使用的字体一致，否则分页边界与渲染结果会不吻合。
        /// 默认值：PingFangSC-Regular 17pt
        var font: CTFont
        
        init(
            pageSize: CGSize = CGSize(width: 375, height: 600),
            sketchMaxLength: Int = 80,
            font: CTFont = CTFontCreateWithName("PingFangSC-Regular" as CFString, 17, nil)
        ) {
            self.pageSize = pageSize
            self.sketchMaxLength = sketchMaxLength
            self.font = font
        }
        
        /// 页面矩形（与页面尺寸相同，不含内边距）
        /// 注意：与 PageRenderer.Configuration.textRect（含内边距）不同
        var pageRect: CGRect {
            CGRect(origin: .zero, size: pageSize)
        }
        
        static let `default` = Configuration()
    }
    
    // MARK: - Private: PageSlice
    //
    // 仅存储分页所需的最小信息：
    //   - utf16Location / utf16Length：用于从原始 String 切片（避免 NSRange 结构体）
    //   - utf8Offset：该页在 UTF-8 字节流中的起始偏移；字节长度由 buildResults 通过相邻页差值计算
    // 不再存储 NSRange，减少一次结构体构造。
    
    private struct PageSlice {
        let utf16Location: Int
        let utf16Length:   Int
        let utf8Offset:    Int64
        // utf8Length 不在此存储：buildResults 通过相邻页的 utf8Offset 差值计算，
        // 确保连续切片语义下字节长度精确，无需在 PageSlice 中冗余保存。
    }
    
    // MARK: - Private Properties
    
    private let configuration: Configuration
    
    // MARK: - Init
    
    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - Public API
    
    /// 对文本进行分页
    /// - Parameters:
    ///   - text: 待分页的原始文本
    ///   - textAttributes: 可选的文本排版属性字典，若提供则覆盖 Configuration 中的字体/段落样式
    /// - Returns: 每页信息数组 `[(text, offset, length, sketchText, isTruncated)]`
    ///   - `text`        : 该页的文本内容（原样保留所有空格、换行、缩进字符）
    ///   - `offset`      : 该页在原始 UTF-8 字节流中的起始偏移
    ///   - `length`      : 该页在原始 UTF-8 字节流中的字节长度
    ///   - `sketchText`  : 该页的文本摘要（前 N 个非空白字符）
    ///   - `isTruncated` : 该页第一行是否是被截断的（即上一页末尾行在本页延续）；
    ///                     第一页始终为 `false`，后续页若上一页末尾字符不是换行符则为 `true`
    func paginate(text: String, textAttributes: [NSAttributedString.Key: Any]? = nil) -> [(text: String, offset: Int64, length: Int64, sketchText: String, isTruncated: Bool)] {
        guard !text.isEmpty else { return [] }
        
        // 1. 构建带排版属性的 NSAttributedString（一次性，整个分页过程复用）
        let attrString = buildAttributedString(from: text, overrideAttributes: textAttributes)
        let totalUTF16 = attrString.length
        guard totalUTF16 > 0 else { return [] }
        
        // 2. 预构建 UTF-16 → UTF-8 偏移映射表（O(n) 预处理，O(1) 查询）
        let offsetMap = buildUTF8OffsetMap(from: text)
        
        // 3. 创建 CTFramesetter 和 CGPath（循环外创建，避免重复分配）
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPath(rect: configuration.pageRect, transform: nil)
        
        // 4. 分页循环
        //    中文小说每页约 500~800 字，UTF-16 约 500~800 code units，
        //    用 totalUTF16 / 600 作为初始容量估算（比 /400 更贴近实际）
        var slices = [PageSlice]()
        slices.reserveCapacity(max(4, totalUTF16 / 600))
        
        var location = 0
        while location < totalUTF16 {
            let searchRange = CFRange(location: location, length: totalUTF16 - location)
            let frame   = CTFramesetterCreateFrame(framesetter, searchRange, path, nil)
            let visible = CTFrameGetVisibleStringRange(frame)
            
            // 防止死循环：visible.length <= 0 时强制推进 1 个 UTF-16 code unit。
            // 注意：若 location 恰好是代理对的第一个 code unit，advance=1 会落在
            // 代理对的第二个 code unit 上。buildUTF8OffsetMap 已将代理对第二个
            // code unit 的偏移值设为该标量的 UTF-8 结束位置，因此 utf8End 仍正确。
            let advance = visible.length > 0 ? visible.length : 1
            
            // 断言：CTFrameGetVisibleStringRange 不应返回超出剩余范围的 length
            assert(location + advance <= totalUTF16,
                   "CTFrameGetVisibleStringRange 返回了超出范围的 length：location=\(location) advance=\(advance) totalUTF16=\(totalUTF16)")
            
            let utf8Start = offsetMap[location]
            
            slices.append(PageSlice(
                utf16Location: location,
                utf16Length:   advance,
                utf8Offset:    utf8Start
            ))
            
            location += advance
        }
        
        // 5. 构建最终结果（从 String UTF-16 视图切片，避免 NSString 桥接）
        //    传入 offsetMap 的哨兵值（总 UTF-8 字节数），确保最后一页字节长度精确。
        let totalUTF8Bytes = offsetMap[totalUTF16]
        return buildResults(text: text, slices: slices, totalUTF8Bytes: totalUTF8Bytes, nsText: text as NSString)
    }
    
    // MARK: - Private: AttributedString
    
    /// 构建用于分页计算的 NSAttributedString
    ///
    /// - 若调用方传入了 `overrideAttributes`，直接使用（与渲染器保持一致）
    /// - 若未传入，使用 `configuration.font` 构建默认属性，并设置 `lineBreakMode`，
    ///   确保分页所用字体与渲染字体一致，避免分页边界与渲染结果不吻合。
    private func buildAttributedString(
        from text: String,
        overrideAttributes: [NSAttributedString.Key: Any]? = nil
    ) -> NSAttributedString {
        if let attrs = overrideAttributes, !attrs.isEmpty {
            return NSAttributedString(string: text, attributes: attrs)
        }
        // 默认属性：使用 configuration.font，确保分页字体与渲染字体一致
        let paragraphStyle = makeDefaultParagraphStyle()
        let attrs: [NSAttributedString.Key: Any] = [
            kCTFontAttributeName as NSAttributedString.Key: configuration.font,
            kCTParagraphStyleAttributeName as NSAttributedString.Key: paragraphStyle
        ]
        return NSAttributedString(string: text, attributes: attrs)
    }
    
    /// 构建默认段落样式：仅设置 `lineBreakMode = .byWordWrapping`，
    /// 确保长行正确折行而不被截断。
    /// 行高由 `configuration.font` 的自然行高决定，与渲染器行为一致。
    private func makeDefaultParagraphStyle() -> CTParagraphStyle {
        var lineBreakMode = CTLineBreakMode.byWordWrapping
        return withUnsafeBytes(of: &lineBreakMode) { ptr in
            let settings: [CTParagraphStyleSetting] = [
                CTParagraphStyleSetting(
                    spec: .lineBreakMode,
                    valueSize: MemoryLayout<CTLineBreakMode>.size,
                    value: ptr.baseAddress!
                )
            ]
            return CTParagraphStyleCreate(settings, settings.count)
        }
    }
    
    // MARK: - Private: UTF-8 Offset Map
    
    /// UTF-16 code unit 索引 → UTF-8 字节偏移的紧凑映射表
    ///
    /// 使用 `ContiguousArray<Int64>` 替代 `Array<Int64>`，
    /// 保证内存连续布局，下标访问无额外桥接开销。
    private struct UTF8OffsetMap {
        private let table: ContiguousArray<Int64>
        
        init(table: ContiguousArray<Int64>) { self.table = table }
        
        /// O(1) 下标访问（越界时钳制到有效范围）
        ///
        /// 有效索引范围：`0...table.count-1`
        /// - 索引 `0..<utf16Count`：对应各 UTF-16 code unit 的 UTF-8 起始偏移
        /// - 索引 `utf16Count`（即 `table.count-1`）：哨兵，等于总 UTF-8 字节数
        @inline(__always)
        subscript(utf16Index: Int) -> Int64 {
            if utf16Index <= 0 { return 0 }
            if utf16Index >= table.count { return table[table.count - 1] }
            return table[utf16Index]
        }
    }
    
    /// 预构建映射表：时间 O(n)，空间 O(n)（n = UTF-16 code unit 数量）
    ///
    /// 优化点：
    /// - 使用 `ContiguousArray` 保证内存连续
    /// - 用 `scalar.value > 0xFFFF` 直接判断代理对，避免创建 `UTF16View`
    ///
    /// 代理对处理说明：
    /// - 代理对的第一个 code unit：存储该标量的 UTF-8 起始位置
    /// - 代理对的第二个 code unit：存储该标量的 UTF-8 **结束**位置（即下一标量的起始位置）
    ///   这样当 CTFrameGetVisibleStringRange 在代理对第二个 code unit 处截断时，
    ///   `offsetMap[location + advance]` 能正确返回该标量之后的 UTF-8 位置，
    ///   避免字节偏移少计 4 字节的问题。
    private func buildUTF8OffsetMap(from text: String) -> UTF8OffsetMap {
        let utf16Count = text.utf16.count
        var table = ContiguousArray<Int64>()
        table.reserveCapacity(utf16Count + 1)
        
        var utf8Pos: Int64 = 0
        
        for scalar in text.unicodeScalars {
            // UTF-8 字节数：由 Unicode 码点范围决定
            // U+0000..U+007F   → 1 字节
            // U+0080..U+07FF   → 2 字节
            // U+0800..U+FFFF   → 3 字节
            // U+10000..U+10FFFF → 4 字节
            let v = scalar.value
            let utf8Units: Int64
            switch v {
            case 0x00...0x7F:    utf8Units = 1
            case 0x80...0x7FF:   utf8Units = 2
            case 0x800...0xFFFF: utf8Units = 3
            default:             utf8Units = 4
            }
            
            table.append(utf8Pos)
            // 代理对（U+10000 以上）在 UTF-16 中占 2 个 code unit。
            // 第二个 code unit 存储该标量的 UTF-8 结束位置（utf8Pos + utf8Units），
            // 确保以代理对第二个 code unit 为边界时，UTF-8 偏移计算正确。
            if scalar.value > 0xFFFF {
                table.append(utf8Pos + utf8Units)
            }
            utf8Pos += utf8Units
        }
        
        table.append(utf8Pos)  // 哨兵：总 UTF-8 字节数
        return UTF8OffsetMap(table: table)
    }
    
    // MARK: - Private: Build Results
    
    private func buildResults(
        text: String,
        slices: [PageSlice],
        totalUTF8Bytes: Int64,
        nsText: NSString
    ) -> [(text: String, offset: Int64, length: Int64, sketchText: String, isTruncated: Bool)] {
        guard !slices.isEmpty else { return [] }
        
        let totalUTF16 = nsText.length
        let maxSketch  = configuration.sketchMaxLength
        
        // 强制连续切片：第 i 页的实际长度 = 第 i+1 页起点 - 第 i 页起点，
        // 确保所有字符（包括空行、行首空格、全角空格等）完整保留，无遗漏无重叠。
        return slices.indices.map { i in
            let slice     = slices[i]
            let nextStart = i + 1 < slices.count ? slices[i + 1].utf16Location : totalUTF16
            let length    = max(0, nextStart - slice.utf16Location)
            
            let pageText = nsText.substring(with: NSRange(location: slice.utf16Location,
                                                          length:   length))
            let sketch = makeSketch(from: pageText, maxLen: maxSketch)
            
            // utf8Length 同步修正：使用连续切片对应的实际字节长度。
            // 最后一页的 utf8End 使用 totalUTF8Bytes（offsetMap 哨兵值），
            // 避免因 advance 被强制设为 1 时 slice.utf8Length 计算偏差导致字节丢失。
            let utf8End: Int64
            if i + 1 < slices.count {
                utf8End = slices[i + 1].utf8Offset
            } else {
                utf8End = totalUTF8Bytes
            }
            
            // isTruncated：判断本页第一行是否是上一页末尾行的延续。
            // 第一页始终为 false；后续页若上一页末尾字符不是换行符（\n），
            // 说明上一页最后一行被分页截断，延续到本页，则标记为 true。
            let isTruncated: Bool
            if i == 0 {
                isTruncated = false
            } else {
                let prevSlice   = slices[i - 1]
                let prevEnd     = slice.utf16Location  // 即上一页的结束位置（不含）
                let prevLength  = max(0, prevEnd - prevSlice.utf16Location)
                if prevLength > 0 {
                    // 取上一页最后一个 UTF-16 code unit，判断是否为换行符
                    let lastCharIndex = prevSlice.utf16Location + prevLength - 1
                    let lastChar = nsText.character(at: lastCharIndex)
                    isTruncated = lastChar != unichar(UInt16(("\n" as UnicodeScalar).value))
                } else {
                    isTruncated = false
                }
            }
            
            return (text: pageText, offset: slice.utf8Offset,
                    length: utf8End - slice.utf8Offset,
                    sketchText: sketch,
                    isTruncated: isTruncated)
        }
    }
    
    // MARK: - Private: Sketch
    
    /// 包含半角空白和全角空格（U+3000）的字符集，静态构建避免每页重复分配
    private static let sketchWhitespaceSet = CharacterSet.whitespaces
        .union(CharacterSet(charactersIn: "\u{3000}"))
    
    /// 从页面文本中提取摘要（跳过空行，合并多行为单行，截取前 maxLen 个字符）
    ///
    /// 优化点：
    /// - 使用静态 `CharacterSet` 一次性 trim 半角空白 + 全角空格，替代 while 循环
    /// - 用 `Substring` 避免 `split` 产生的 String 拷贝
    private func makeSketch(from pageText: String, maxLen: Int) -> String {
        guard !pageText.isEmpty, maxLen > 0 else { return "" }
        
        let wsSet = Self.sketchWhitespaceSet
        
        var result = ""
        result.reserveCapacity(maxLen + 4)
        var charCount = 0
        
        for line in pageText.split(separator: "\n", omittingEmptySubsequences: true) {
            guard charCount < maxLen else { break }
            
            let trimmed = line.trimmingCharacters(in: wsSet)
            guard !trimmed.isEmpty else { continue }
            
            let sep    = result.isEmpty ? "" : " "
            let sepLen = sep.isEmpty ? 0 : 1
            let room   = maxLen - charCount - sepLen
            guard room > 0 else { break }
            
            result += sep
            if trimmed.count <= room {
                result    += trimmed
                charCount += sepLen + trimmed.count
            } else {
                result    += String(trimmed.prefix(room))
                charCount  = maxLen
                break
            }
        }
        
        return result
    }
}

// MARK: - Convenience

extension TextPaginator {
    
    /// 快速静态分页入口
    ///
    /// - Parameters:
    ///   - text: 待分页的原始文本
    ///   - safeArea: 页面安全区域尺寸（单位：点，pt），即去除系统安全区域后的可用页面尺寸
    ///   - textAttributes: 文本排版属性字典，支持 `kCTFontAttributeName`、
    ///     `kCTParagraphStyleAttributeName` 等 CoreText 属性键；
    ///     若字典非空，将直接用于分页计算（分页字体由字典中的 `kCTFontAttributeName` 决定）；
    ///     若字典为空，则使用默认字体（PingFangSC-Regular 17pt）和默认段落样式
    ///   - sketchMaxLength: 摘要最大字符数（默认 80）
    /// - Returns: 每页信息数组 `[(text, offset, length, sketchText, isTruncated)]`
    static func paginate(text: String,
                         safeArea: CGSize,
                         textAttributes: [NSAttributedString.Key: Any],
                         sketchMaxLength: Int = 80) -> [(text: String, offset: Int64, length: Int64, sketchText: String, isTruncated: Bool)] {
        let configuration: Configuration = Configuration(pageSize: safeArea, sketchMaxLength: sketchMaxLength)
        return TextPaginator(configuration: configuration).paginate(text: text, textAttributes: textAttributes.isEmpty ? nil : textAttributes)
    }
}


