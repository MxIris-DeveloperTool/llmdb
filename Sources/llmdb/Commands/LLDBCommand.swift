import ArgumentParser
import Foundation

struct LLDBCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lldb",
        abstract: "Run a raw lldb command and return its output"
    )

    // Captured verbatim so the command's own options (`-n`, `-c`) aren't
    // parsed as llmdb's; see `passthroughText`. Several words are rejoined
    // with single spaces and not re-quoted — re-quoting would corrupt raw
    // input such as `expression -- …` — so a command with quoted parts of its
    // own must arrive as one word. llmdb's own options must come first.
    @Argument(
        parsing: .captureForPassthrough,
        help: "lldb command, e.g. `image lookup -n main`. Put options first. Quote the whole command as one argument when it has quoted parts of its own."
    )
    var commandWords: [String] = []

    @Option(name: .long, help: "Session ID")
    var session: String?

    func validate() throws {
        guard passthroughText(commandWords) != nil else {
            throw ValidationError("Missing expected argument '<command>'")
        }
    }

    func run() async throws {
        let result = try await DaemonClient.call(
            RPC.lldb,
            LLDBCommandParams(sessionId: session, command: passthroughText(commandWords) ?? "")
        )
        try JSONOutput.print(result)
    }
}
