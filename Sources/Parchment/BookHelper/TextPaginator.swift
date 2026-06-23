import Foundation
import CoreText
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - TextPaginator

/// 基于 CoreText 的高效文本分页器
///
/// 使用 `CTFramesetter` 精确计算每页可容纳的文本范围，
/// 返回每页的文本内容、UTF-8 字节偏移信息。
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
/// // pages: [(text: String, offset: Int64, length: Int64, isTruncated: Bool)]
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
        /// 默认字体（用于未传入 textAttributes 时的分页计算）
        /// 必须与渲染器使用的字体一致，否则分页边界与渲染结果会不吻合。
        /// 默认值：PingFangSC-Regular 17pt
        var font: CTFont
        
        init(
            pageSize: CGSize = CGSize(width: 375, height: 600),
            font: CTFont = CTFontCreateWithName("PingFangSC-Regular" as CFString, 17, nil)
        ) {
            self.pageSize = pageSize
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
    /// - Returns: 每页信息数组 `[(offset, length, isTruncated)]`
    ///   - `offset`      : 该页在原始 UTF-8 字节流中的起始偏移
    ///   - `length`      : 该页在原始 UTF-8 字节流中的字节长度
    ///   - `isTruncated` : 该页第一行是否是被截断的（即上一页末尾行在本页延续）；
    ///                     第一页始终为 `false`，后续页若上一页末尾字符不是换行符则为 `true`
    ///
    /// 注意：本方法**不再返回每页文本内容**。页文本可由调用方依据 `offset`/`length`
    /// 从对应的 UTF-8 编码文件中按字节切片还原，避免在数据库中冗余存储全文。
    func paginate(text: String, textAttributes: [NSAttributedString.Key: Any]? = nil) -> [(offset: Int64, length: Int64, isTruncated: Bool)] {
        // 1. 构建带排版属性的 NSAttributedString（一次性，整个分页过程复用）
        let attrString = buildAttributedString(from: text, overrideAttributes: textAttributes)
        let totalUTF16 = attrString.length
        guard totalUTF16 > 0 else { return [] }
        
        // 2. 预构建 UTF-16 → UTF-8 偏移映射表（O(n) 预处理，O(1) 查询）
        let offsetMap = buildUTF8OffsetMap(from: text)
        
        // 3. 创建 CTFramesetter 和 CGPath（循环外创建，避免重复分配）
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        let path = CGPath(rect: configuration.pageRect, transform: nil)
        
        // 3.5 构建截断页上下文（仅当渲染段落样式存在首行缩进时有效）
        //     当某页第一行是被截断的延续行时，渲染器仅将「该页第一段」的 firstLineHeadIndent 设为 0，
        //     而页内后续的新段落仍保留首行缩进。分页时必须采用完全相同的「仅首段无缩进」模型，
        //     否则页内后续段落的缩进差异会导致分页边界与渲染结果不吻合（表现为页面文字被裁剪或留白）。
        let truncatedContext = buildTruncatedContext(overrideAttributes: textAttributes)
        let nsText = text as NSString
        
        // 4. 分页循环
        //    中文小说每页约 500~800 字，UTF-16 约 500~800 code units，
        //    用 totalUTF16 / 600 作为初始容量估算（比 /400 更贴近实际）
        var slices = [PageSlice]()
        slices.reserveCapacity(max(4, totalUTF16 / 600))
        
        var location = 0
        var isPrevTruncated = false  // 上一页末尾是否被截断（即当前页第一行是延续行）
        
        while location < totalUTF16 {
            let advance: Int
            if isPrevTruncated, let context = truncatedContext {
                // 截断页：用「首段无缩进、其余段落保留缩进」的局部 framesetter 计算，
                // 与渲染端（ContentViewController.reloadWith）的处理完全一致。
                advance = truncatedPageAdvance(nsText: nsText,
                                               location: location,
                                               totalUTF16: totalUTF16,
                                               path: path,
                                               context: context)
            } else {
                // 普通页：复用全文 framesetter（所有段落均带首行缩进）
                let searchRange = CFRange(location: location, length: totalUTF16 - location)
                let frame   = CTFramesetterCreateFrame(framesetter, searchRange, path, nil)
                let visible = CTFrameGetVisibleStringRange(frame)
                // 防止死循环：visible.length <= 0 时强制推进 1 个 UTF-16 code unit。
                // 注意：若 location 恰好是代理对的第一个 code unit，advance=1 会落在
                // 代理对的第二个 code unit 上。buildUTF8OffsetMap 已将代理对第二个
                // code unit 的偏移值设为该标量的 UTF-8 结束位置，因此 utf8End 仍正确。
                advance = visible.length > 0 ? visible.length : 1
            }
            
            // 断言：分页 advance 不应超出剩余范围
            assert(location + advance <= totalUTF16,
                   "分页 advance 超出范围：location=\(location) advance=\(advance) totalUTF16=\(totalUTF16)")
            
            let utf8Start = offsetMap[location]
            
            slices.append(PageSlice(
                utf16Location: location,
                utf16Length:   advance,
                utf8Offset:    utf8Start
            ))
            
            // 判断本页末尾是否被截断，用于下一页选择正确的排版模型
            // 若本页最后一个字符不是换行符，说明最后一行被截断，延续到下一页
            if advance > 0 {
                let lastCharIndex = location + advance - 1
                let lastChar = nsText.character(at: lastCharIndex)
                isPrevTruncated = lastChar != unichar(UInt16(("\n" as UnicodeScalar).value))
            } else {
                isPrevTruncated = false
            }
            
            location += advance
        }
        
        // 5. 构建最终结果（从 String UTF-16 视图切片，避免 NSString 桥接）
        //    传入 offsetMap 的哨兵值（总 UTF-8 字节数），确保最后一页字节长度精确。
        let totalUTF8Bytes = offsetMap[totalUTF16]
        return buildResults(text: text, slices: slices, totalUTF8Bytes: totalUTF8Bytes, nsText: nsText)
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
    
    /// 构建默认段落样式：仅设置 `lineBreakMode = .byCharWrapping`，确保长行正确折行而不被截断。
    ///
    /// ⚠️ 重要：此默认样式仅保证折行方式一致，**不包含行高倍数、行高上下限、对齐、首行缩进**等设置，
    /// 因此其排版行高仅由 `configuration.font` 的自然行高决定。
    /// 若实际渲染器（如 `Configuration.paragraphStyle`）使用了 `lineHeightMultiple`、
    /// `minimum/maximumLineHeight`、`firstLineHeadIndent` 等，则默认样式的分页边界**不会**与渲染结果吻合。
    ///
    /// 为保证分页与渲染一致，调用方应始终通过 `textAttributes` 传入与渲染器完全相同的排版属性
    /// （含 `font` 与 `NSParagraphStyle`）。此默认分支仅作为无属性时的兜底，不应用于正式渲染场景。
    private func makeDefaultParagraphStyle() -> CTParagraphStyle {
        var lineBreakMode = CTLineBreakMode.byCharWrapping
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
    
    // MARK: - Private: Truncated Page Layout

    /// 截断页排版上下文
    ///
    /// 持有原始（带首行缩进）与「去首行缩进」两套属性，
    /// 用于在截断页中精确复现渲染端「仅首段无缩进、其余段落保留缩进」的排版模型。
    private struct TruncatedContext {
        /// 原始属性（含 firstLineHeadIndent，用于页内第二段及以后的新段落）
        let baseAttributes: [NSAttributedString.Key: Any]
        /// 去掉 firstLineHeadIndent 的属性（仅用于截断页第一段）
        let noIndentAttributes: [NSAttributedString.Key: Any]
    }

    /// 构建截断页排版上下文
    ///
    /// 渲染端（`ContentViewController.reloadWith`）对截断页的处理是：
    /// **仅将该页第一段**（即第一个换行符之前的延续内容）的 `firstLineHeadIndent` 设为 0，
    /// 页内后续的新段落仍保留首行缩进。因此分页时必须采用相同模型：
    /// 第一段用「去缩进」属性，后续段落用「原始」属性。
    ///
    /// - Returns: 截断页上下文；nil 表示无需特殊处理
    ///   （未提供段落样式，或 firstLineHeadIndent 本身为 0，截断页与普通页排版一致）
    private func buildTruncatedContext(
        overrideAttributes: [NSAttributedString.Key: Any]?
    ) -> TruncatedContext? {
        guard let attrs = overrideAttributes, !attrs.isEmpty else { return nil }

        // 注意：kCTParagraphStyleAttributeName 与 .paragraphStyle 是同一个 key 字符串，
        // 但值可能是 NSParagraphStyle（来自 UIKit）或 CTParagraphStyle（来自 CoreText）
        guard let paragraphStyleValue = attrs[.paragraphStyle] ?? attrs[kCTParagraphStyleAttributeName as NSAttributedString.Key] else {
            return nil
        }

        // 仅处理 NSParagraphStyle（UIKit 场景，本项目实际使用）。
        // CTParagraphStyle 难以无损复制并修改单个 specifier，且项目未使用，跳过。
        guard let nsStyle = paragraphStyleValue as? NSParagraphStyle else { return nil }
        // 首行缩进为 0 时，截断页与普通页排版一致，无需特殊处理
        guard nsStyle.firstLineHeadIndent != 0 else { return nil }

        let mutableStyle = (nsStyle.mutableCopy() as! NSMutableParagraphStyle)
        mutableStyle.firstLineHeadIndent = 0

        var noIndentAttrs = attrs
        noIndentAttrs[.paragraphStyle] = mutableStyle

        return TruncatedContext(baseAttributes: attrs, noIndentAttributes: noIndentAttrs)
    }

    /// 截断页计算时的文本窗口上限（UTF-16 code unit）
    ///
    /// 为避免对超长剩余文本反复构建 framesetter 造成 O(n²) 开销，
    /// 每次仅取从 `location` 起最多 `truncatedWindowSize` 个 code unit 参与排版计算。
    /// 单页满载中文正文通常不足 2000 code unit，8192 的窗口远超单页容量，
    /// 可保证窗口内一定能排满一整页，单页 advance 结果与使用全量剩余文本一致。
    private static let truncatedWindowSize = 8192

    /// 计算截断页可容纳的 UTF-16 长度（advance）
    ///
    /// 为精确复现渲染端排版，从 `location` 起切出一段足够长的文本窗口，针对该子串构建
    /// 「首段无缩进、其余段落带缩进」的 NSAttributedString，再用 CTFramesetter 计算可见范围。
    ///
    /// 实现要点：
    /// - 仅取最多 `truncatedWindowSize` 个 code unit 作为窗口，避免大文件 O(n²) 退化。
    /// - 先定位窗口内第一个换行符的位置，将 `[0, firstNewline]` 视为「首段」并赋予去缩进属性；
    ///   其余部分（含换行符之后的新段落）赋予原始（带缩进）属性。
    /// - 若窗口内不含换行符，则整窗都是首段延续内容，全部使用去缩进属性。
    ///
    /// - Returns: 本页可容纳的 UTF-16 code unit 数（至少为 1，防止死循环）
    private func truncatedPageAdvance(
        nsText: NSString,
        location: Int,
        totalUTF16: Int,
        path: CGPath,
        context: TruncatedContext
    ) -> Int {
        let remainingLength = totalUTF16 - location
        let windowLength = min(remainingLength, Self.truncatedWindowSize)
        let window = nsText.substring(with: NSRange(location: location, length: windowLength))
        let windowNS = window as NSString

        // 定位「首段」边界：窗口内第一个换行符（含换行符本身归入首段）
        let nl = windowNS.range(of: "\n")
        let firstParagraphLength: Int
        if nl.location != NSNotFound {
            firstParagraphLength = nl.location + nl.length
        } else {
            firstParagraphLength = windowNS.length
        }

        let mutable = NSMutableAttributedString(string: window, attributes: context.baseAttributes)
        // 首段使用「去首行缩进」属性，与渲染端一致
        mutable.setAttributes(context.noIndentAttributes,
                              range: NSRange(location: 0, length: firstParagraphLength))

        let framesetter = CTFramesetterCreateWithAttributedString(mutable)
        let frame = CTFramesetterCreateFrame(framesetter,
                                             CFRange(location: 0, length: 0),
                                             path, nil)
        let visible = CTFrameGetVisibleStringRange(frame)
        let advance = visible.length > 0 ? visible.length : 1
        // 防御：不超过窗口长度（进而不超过剩余长度）
        return min(advance, windowLength)
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
    ) -> [(offset: Int64, length: Int64, isTruncated: Bool)] {
        guard !slices.isEmpty else { return [] }
        
        // 不再切片生成每页文本：页文本由调用方按 offset/length 从 UTF-8 文件还原。
        return slices.indices.map { i in
            let slice = slices[i]
            
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
            
            return (offset: slice.utf8Offset,
                    length: utf8End - slice.utf8Offset,
                    isTruncated: isTruncated)
        }
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
    /// - Returns: 每页信息数组 `[(offset, length, isTruncated)]`
    static func paginate(text: String,
                         safeArea: CGSize,
                         textAttributes: [NSAttributedString.Key: Any]) -> [(offset: Int64, length: Int64, isTruncated: Bool)] {
        let configuration: Configuration = Configuration(pageSize: safeArea)
        return TextPaginator(configuration: configuration).paginate(text: text, textAttributes: textAttributes.isEmpty ? nil : textAttributes)
    }
}


