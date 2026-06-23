//
//  Print.swift
//  Parchment
//
//  Created by okferret on 2026/6/23.
//

import Foundation

/// Writes the textual representations of the given items into the standard
/// output.
///
/// You can pass zero or more items to the `print(_:separator:terminator:)`
/// function. The textual representation for each item is the same as that
/// obtained by calling `String(describing: item)`. The following example
/// prints a string, a closed range of integers, and a group of floating-point
/// values to standard output:
///
///     print("One two three four five")
///     // Prints "One two three four five"
///
///     print(1...5)
///     // Prints "1...5"
///
///     print(1.0, 2.0, 3.0, 4.0, 5.0)
///     // Prints "1.0 2.0 3.0 4.0 5.0"
///
/// To print the items separated by something other than a space, pass a string
/// as `separator`.
///
///     print(1.0, 2.0, 3.0, 4.0, 5.0, separator: " ... ")
///     // Prints "1.0 ... 2.0 ... 3.0 ... 4.0 ... 5.0"
///
/// The output from each call to `print(_:separator:terminator:)` includes a
/// newline by default. To print the items without a trailing newline, pass an
/// empty string as `terminator`.
///
///     for n in 1...5 {
///         print(n, terminator: "")
///     }
///     // Prints "12345"
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - separator: A string to print between each item. The default is a single
///     space (`" "`).
///   - terminator: The string to print after all items have been printed. The
///     default is a newline (`"\n"`).
func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
#if DEBUG
    Swift.print(items, separator: separator, terminator: terminator)
#endif
}

/// Writes the textual representations of the given items most suitable for
/// debugging into the standard output.
///
/// You can pass zero or more items to the
/// `debugPrint(_:separator:terminator:)` function. The textual representation
/// for each item is the same as that obtained by calling
/// `String(reflecting: item)`. The following example prints the debugging
/// representation of a string, a closed range of integers, and a group of
/// floating-point values to standard output:
///
///     debugPrint("One two three four five")
///     // Prints "One two three four five"
///
///     debugPrint(1...5)
///     // Prints "ClosedRange(1...5)"
///
///     debugPrint(1.0, 2.0, 3.0, 4.0, 5.0)
///     // Prints "1.0 2.0 3.0 4.0 5.0"
///
/// To print the items separated by something other than a space, pass a string
/// as `separator`.
///
///     debugPrint(1.0, 2.0, 3.0, 4.0, 5.0, separator: " ... ")
///     // Prints "1.0 ... 2.0 ... 3.0 ... 4.0 ... 5.0"
///
/// The output from each call to `debugPrint(_:separator:terminator:)` includes
/// a newline by default. To print the items without a trailing newline, pass
/// an empty string as `terminator`.
///
///     for n in 1...5 {
///         debugPrint(n, terminator: "")
///     }
///     // Prints "12345"
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - separator: A string to print between each item. The default is a single
///     space (`" "`).
///   - terminator: The string to print after all items have been printed. The
///     default is a newline (`"\n"`).
func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
#if DEBUG
    Swift.debugPrint(items, separator: separator, terminator: terminator)
#endif
}

/// Writes the textual representations of the given items into the given output
/// stream.
///
/// You can pass zero or more items to the `print(_:separator:terminator:to:)`
/// function. The textual representation for each item is the same as that
/// obtained by calling `String(describing: item)`. The following example
/// prints a closed range of integers to a string:
///
///     var range = "My range: "
///     print(1...5, to: &range)
///     // range == "My range: 1...5\n"
///
/// To print the items separated by something other than a space, pass a string
/// as `separator`.
///
///     var separated = ""
///     print(1.0, 2.0, 3.0, 4.0, 5.0, separator: " ... ", to: &separated)
///     // separated == "1.0 ... 2.0 ... 3.0 ... 4.0 ... 5.0\n"
///
/// The output from each call to `print(_:separator:terminator:to:)` includes a
/// newline by default. To print the items without a trailing newline, pass an
/// empty string as `terminator`.
///
///     var numbers = ""
///     for n in 1...5 {
///         print(n, terminator: "", to: &numbers)
///     }
///     // numbers == "12345"
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - separator: A string to print between each item. The default is a single
///     space (`" "`).
///   - terminator: The string to print after all items have been printed. The
///     default is a newline (`"\n"`).
///   - output: An output stream to receive the text representation of each
///     item.
func print<Target>(_ items: Any..., separator: String = " ", terminator: String = "\n", to output: inout Target) where Target : TextOutputStream {
#if DEBUG
    Swift.print(items, separator: separator, terminator: terminator, to: &output)
#endif
}

/// Writes the textual representations of the given items most suitable for
/// debugging into the given output stream.
///
/// You can pass zero or more items to the
/// `debugPrint(_:separator:terminator:to:)` function. The textual
/// representation for each item is the same as that obtained by calling
/// `String(reflecting: item)`. The following example prints a closed range of
/// integers to a string:
///
///     var range = "My range: "
///     debugPrint(1...5, to: &range)
///     // range == "My range: ClosedRange(1...5)\n"
///
/// To print the items separated by something other than a space, pass a string
/// as `separator`.
///
///     var separated = ""
///     debugPrint(1.0, 2.0, 3.0, 4.0, 5.0, separator: " ... ", to: &separated)
///     // separated == "1.0 ... 2.0 ... 3.0 ... 4.0 ... 5.0\n"
///
/// The output from each call to `debugPrint(_:separator:terminator:to:)`
/// includes a newline by default. To print the items without a trailing
/// newline, pass an empty string as `terminator`.
///
///     var numbers = ""
///     for n in 1...5 {
///         debugPrint(n, terminator: "", to: &numbers)
///     }
///     // numbers == "12345"
///
/// - Parameters:
///   - items: Zero or more items to print.
///   - separator: A string to print between each item. The default is a single
///     space (`" "`).
///   - terminator: The string to print after all items have been printed. The
///     default is a newline (`"\n"`).
///   - output: An output stream to receive the text representation of each
///     item.
func debugPrint<Target>(_ items: Any..., separator: String = " ", terminator: String = "\n", to output: inout Target) where Target : TextOutputStream {
#if DEBUG
    Swift.debugPrint(items, separator: separator, terminator: terminator, to: &output)
#endif
}
