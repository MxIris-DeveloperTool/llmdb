import Foundation

/// Rejoin the words a `.captureForPassthrough` argument captured into the
/// text they spell, dropping a leading `--`.
///
/// Passthrough capture keeps a `--` terminator as a word. The terminator is
/// needed for text that starts with `-` and contains an `h`, such as
/// `-[NSAppleEventManager dispatchRawAppleEvent:withRawReply:handlerRefCon:]`:
/// ArgumentParser reads such a word as a cluster of short flags and stops at
/// the `-h` inside it to print help. Returns nil when no text remains.
func passthroughText(_ words: [String]) -> String? {
    let textWords = words.first == "--" ? Array(words.dropFirst()) : words
    let text = textWords.joined(separator: " ")
    return text.trimmingCharacters(in: .whitespaces).isEmpty ? nil : text
}
